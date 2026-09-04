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