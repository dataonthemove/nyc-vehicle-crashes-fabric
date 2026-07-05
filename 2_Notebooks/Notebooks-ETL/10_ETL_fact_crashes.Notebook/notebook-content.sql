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
-- -- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- -- **Target:** `dbo.fact_crashes`
-- -- **Grain:** One row per collision event (COLLISION_ID).
-- -- **Key logic:**
-- - `collision_key` resolved via lookup to `dim_collision` on `collision_id`
-- - `date_key` derived as INT in YYYYMMDD format from `CRASH_DATE`
-- - `location_key` resolved via lookup to `dim_location` on borough/zip/lat/long
-- - `factor_group_key` resolved via lookup to `dim_factor_group` on `collision_key` (2026-06-12, Kimball factor-group bridge pattern)
-- - All measure columns cast to INT; NULL-safe via TRY_CAST
-- - Incremental: skips collision_keys already present in fact_crashes
-- -- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure dim_collision, dim_date, dim_location, dim_factor_group are populated first (run 09b_ETL_dim_factor_group before this).
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

    INSERT INTO dbo.fact_crashes
    (
        date_key,
        collision_key,
        location_key,
        factor_group_key,
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
        dc.collision_key,
        ISNULL(dl.location_key, -1)                                        AS location_key,
        dfg.factor_group_key                                               AS factor_group_key,
        TRY_CAST(src.number_of_persons_injured    AS INT)                  AS persons_injured,
        TRY_CAST(src.number_of_persons_killed     AS INT)                  AS persons_killed,
        TRY_CAST(src.number_of_pedestrians_injured AS INT)                 AS pedestrians_injured,
        TRY_CAST(src.number_of_pedestrians_killed  AS INT)                 AS pedestrians_killed,
        TRY_CAST(src.number_of_cyclist_injured    AS INT)                  AS cyclists_injured,
        TRY_CAST(src.number_of_cyclist_killed     AS INT)                  AS cyclists_killed,
        TRY_CAST(src.number_of_motorist_injured   AS INT)                  AS motorists_injured,
        TRY_CAST(src.number_of_motorist_killed    AS INT)                  AS motorists_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src

    -- Resolve collision_key
    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(src.collision_id AS INT)

    -- Resolve factor_group_key (1:1 with collision_key)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.collision_key = dc.collision_key

    -- Resolve location_key (NULL-safe match on all four columns)
    LEFT JOIN dbo.dim_location dl
        ON  ISNULL(dl.borough,   '') = ISNULL(NULLIF(TRIM(src.borough),   ''), '')
        AND ISNULL(dl.zip_code,  '') = ISNULL(NULLIF(TRIM(src.zip_code),  ''), '')
        AND ISNULL(dl.latitude,  -999) = ISNULL(TRY_CAST(src.latitude  AS FLOAT), -999)
        AND ISNULL(dl.longitude, -999) = ISNULL(TRY_CAST(src.longitude AS FLOAT), -999)

    -- Incremental: skip already-loaded collisions
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crashes tgt
        WHERE  tgt.collision_key = dc.collision_key
    )
    -- Exclude rows with unparseable dates or collision IDs
    AND TRY_CAST(src.crash_date  AS DATE) IS NOT NULL
    AND TRY_CAST(src.collision_id AS INT) IS NOT NULL;

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
