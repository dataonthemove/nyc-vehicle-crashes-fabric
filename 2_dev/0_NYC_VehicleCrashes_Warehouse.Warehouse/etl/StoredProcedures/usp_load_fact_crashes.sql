CREATE PROCEDURE etl.usp_load_fact_crashes
AS
BEGIN
    SET NOCOUNT ON;

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

    -- Resolve factor_group_key by the crash's factor-set hash
    INNER JOIN crash_factor_set cfs
        ON cfs.collision_id = TRY_CAST(src.collision_id AS INT)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.factor_set_hash = cfs.factor_set_hash

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
        WHERE  tgt.collision_id = TRY_CAST(src.collision_id AS INT)
    )
    -- Exclude rows with unparseable dates or collision IDs
    AND TRY_CAST(src.crash_date  AS DATE) IS NOT NULL
    AND TRY_CAST(src.collision_id AS INT) IS NOT NULL;

END;

GO