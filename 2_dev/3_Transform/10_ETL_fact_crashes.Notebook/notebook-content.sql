-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "sqldatawarehouse"
-- META   },
-- META   "dependencies": {
-- META     "warehouse": {
-- META       "default_warehouse": "da2b14e1-b933-a3f7-47de-f697ddedf601",
-- META       "known_warehouses": [
-- META         {
-- META           "id": "da2b14e1-b933-a3f7-47de-f697ddedf601",
-- META           "type": "Datawarehouse"
-- META         }
-- META       ]
-- META     }
-- META   }
-- META }

-- MARKDOWN ********************

-- # 10_ETL_fact_crashes
-- **Purpose:** Create stored procedure `etl.usp_load_fact_crashes`.
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- **Target:** `dbo.fact_crashes`
-- **Grain:** One row per collision event (COLLISION_ID).
-- **Key logic:**
-- - `collision_id` carried as a degenerate dimension (ADR-0005; `dim_collision` dropped 2026-09-26)
-- - `date_key` derived as INT in YYYYMMDD format from `CRASH_DATE`
-- - `location_key` resolved via lookup to `dim_location` on borough/zip_code; no match resolves to the Unknown member, found by lookup (ADR-0005, D15) — the proc THROWs if it is missing
-- - `latitude`/`longitude` carried on the fact as the crash point (moved from `dim_location`, D8); a trailing UPDATE NULLs any point outside the NYC bounding box, incl. (0, 0)
-- - `factor_group_key` resolved via lookup to `dim_factor_group` on the crash's `factor_set_hash` (ADR-0005, D3; derivation must match 09b_ETL_dim_factor_group)
-- - All measure columns cast to INT; NULL-safe via TRY_CAST
-- - Incremental: skips collision_ids already present in fact_crashes
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure dim_date, dim_location, dim_factor_group are populated first (run 09b_ETL_dim_factor_group before this).
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.


-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_fact_crashes', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_fact_crashes;
GO

CREATE PROCEDURE etl.usp_load_fact_crashes
AS
BEGIN
    SET NOCOUNT ON;

    -- Unknown location member (ADR-0005, D15): resolved by lookup, never a literal key.
    DECLARE @unknown_location_key BIGINT;
    SELECT @unknown_location_key = location_key
    FROM   dbo.dim_location
    WHERE  borough = 'UNKNOWN' AND zip_code = 'UNKNOWN';
    IF @unknown_location_key IS NULL
        THROW 50001, 'dim_location Unknown member missing: run etl.usp_load_dim_location first.', 1;

    -- NYC bounding box for a valid crash point (all five boroughs: Staten Island S tip ~40.496, Bronx N ~40.915).
    DECLARE @lat_min FLOAT = 40.49,  @lat_max FLOAT = 40.92;
    DECLARE @lon_min FLOAT = -74.27, @lon_max FLOAT = -73.68;

    -- Unpivot 5 contributing factor columns into collision x factor pairs (UNION collapses duplicates within a crash)
    WITH crash_factor AS
    (
        SELECT TRY_CAST(collision_id AS INT) AS collision_id, NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    ),
    -- One factor set per crash: SHA-256 over its sorted distinct specified factor_desc values.
    -- No specified factor (NULL or 'Unspecified') hashes '' -> the single empty-set group.
    -- Identical in usp_load_dim_factor_group, usp_load_fact_crashes and usp_load_bridge_crash_factor.
    crash_factor_set AS
    (
        SELECT
            collision_id,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', ISNULL(
                STRING_AGG(CASE WHEN factor_desc <> 'Unspecified' THEN factor_desc END, '|')
                    WITHIN GROUP (ORDER BY factor_desc), '')), 2) AS factor_set_hash
        FROM   crash_factor
        WHERE  collision_id IS NOT NULL
        GROUP  BY collision_id
    )
    INSERT INTO dbo.fact_crashes
    (
        date_key,
        collision_id,
        location_key,
        factor_group_key,
        latitude,
        longitude,
        persons_injured,
        persons_killed,
        pedestrians_injured,
        pedestrians_killed,
        cyclists_injured,
        cyclists_killed,
        motorists_injured,
        motorists_killed
    )
    SELECT
        CAST(FORMAT(TRY_CAST(src.crash_date AS DATE), 'yyyyMMdd') AS INT) AS date_key,
        TRY_CAST(src.collision_id AS INT)                                  AS collision_id,
        ISNULL(dl.location_key, @unknown_location_key)                     AS location_key,
        dfg.factor_group_key                                               AS factor_group_key,
        TRY_CAST(src.latitude  AS FLOAT)                                   AS latitude,
        TRY_CAST(src.longitude AS FLOAT)                                   AS longitude,
        TRY_CAST(src.number_of_persons_injured    AS INT)                  AS persons_injured,
        TRY_CAST(src.number_of_persons_killed     AS INT)                  AS persons_killed,
        TRY_CAST(src.number_of_pedestrians_injured AS INT)                 AS pedestrians_injured,
        TRY_CAST(src.number_of_pedestrians_killed  AS INT)                 AS pedestrians_killed,
        TRY_CAST(src.number_of_cyclist_injured    AS INT)                  AS cyclists_injured,
        TRY_CAST(src.number_of_cyclist_killed     AS INT)                  AS cyclists_killed,
        TRY_CAST(src.number_of_motorist_injured   AS INT)                  AS motorists_injured,
        TRY_CAST(src.number_of_motorist_killed    AS INT)                  AS motorists_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src

    -- Resolve factor_group_key by the crash's factor-set hash
    INNER JOIN crash_factor_set cfs
        ON cfs.collision_id = TRY_CAST(src.collision_id AS INT)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.factor_set_hash = cfs.factor_set_hash

    -- Resolve location_key (NULL-safe match on borough/zip_code); no match -> Unknown member
    LEFT JOIN dbo.dim_location dl
        ON  ISNULL(dl.borough,   '') = ISNULL(NULLIF(TRIM(src.borough),   ''), '')
        AND ISNULL(dl.zip_code,  '') = ISNULL(NULLIF(TRIM(src.zip_code),  ''), '')

    -- Incremental: skip already-loaded collisions
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crashes tgt
        WHERE  tgt.collision_id = TRY_CAST(src.collision_id AS INT)
    )
    -- Exclude rows with unparseable dates or collision IDs
    AND TRY_CAST(src.crash_date  AS DATE) IS NOT NULL
    AND TRY_CAST(src.collision_id AS INT) IS NOT NULL;

    -- Crash point cleanse: a point outside the NYC box, incl. (0, 0), is unknown, not a location.
    -- NULLs both coordinates together; the crash row and its counts stay. Idempotent: NULL points
    -- never match, so this fixes loaded rows and each new batch alike. Raw nyc_crashes is untouched.
    UPDATE dbo.fact_crashes
    SET    latitude = NULL, longitude = NULL
    WHERE  (latitude IS NOT NULL OR longitude IS NOT NULL)
      AND  NOT (latitude  BETWEEN @lat_min AND @lat_max
            AND longitude BETWEEN @lon_min AND @lon_max
            AND latitude IS NOT NULL AND longitude IS NOT NULL);

END;
GO

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 2: Execute and verify
EXEC etl.usp_load_fact_crashes;

SELECT COUNT(*) AS fact_crashes_row_count FROM dbo.fact_crashes;

SELECT TOP 10 * FROM dbo.fact_crashes ORDER BY crash_id;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
