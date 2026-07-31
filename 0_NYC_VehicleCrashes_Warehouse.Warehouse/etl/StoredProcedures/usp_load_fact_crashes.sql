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
        CAST(FORMAT(TRY_CAST(src.CRASH_DATE AS DATE), 'yyyyMMdd') AS INT) AS date_key,
        dc.collision_key,
        ISNULL(dl.location_key, -1)                                        AS location_key,
        dfg.factor_group_key                                               AS factor_group_key,
        TRY_CAST(src.NUMBER_OF_PERSONS_INJURED    AS INT)                  AS persons_injured,
        TRY_CAST(src.NUMBER_OF_PERSONS_KILLED     AS INT)                  AS persons_killed,
        TRY_CAST(src.NUMBER_OF_PEDESTRIANS_INJURED AS INT)                 AS pedestrians_injured,
        TRY_CAST(src.NUMBER_OF_PEDESTRIANS_KILLED  AS INT)                 AS pedestrians_killed,
        TRY_CAST(src.NUMBER_OF_CYCLIST_INJURED    AS INT)                  AS cyclists_injured,
        TRY_CAST(src.NUMBER_OF_CYCLIST_KILLED     AS INT)                  AS cyclists_killed,
        TRY_CAST(src.NUMBER_OF_MOTORIST_INJURED   AS INT)                  AS motorists_injured,
        TRY_CAST(src.NUMBER_OF_MOTORIST_KILLED    AS INT)                  AS motorists_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes src

    -- Resolve collision_key
    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(src.COLLISION_ID AS INT)

    -- Resolve factor_group_key (1:1 with collision_key)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.collision_key = dc.collision_key

    -- Resolve location_key (NULL-safe match on all four columns)
    LEFT JOIN dbo.dim_location dl
        ON  ISNULL(dl.borough,   '') = ISNULL(NULLIF(TRIM(src.BOROUGH),   ''), '')
        AND ISNULL(dl.zip_code,  '') = ISNULL(NULLIF(TRIM(src.ZIP_CODE),  ''), '')
        AND ISNULL(dl.latitude,  -999) = ISNULL(TRY_CAST(src.LATITUDE  AS FLOAT), -999)
        AND ISNULL(dl.longitude, -999) = ISNULL(TRY_CAST(src.LONGITUDE AS FLOAT), -999)

    -- Incremental: skip already-loaded collisions
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crashes tgt
        WHERE  tgt.collision_key = dc.collision_key
    )
    -- Exclude rows with unparseable dates or collision IDs
    AND TRY_CAST(src.CRASH_DATE  AS DATE) IS NOT NULL
    AND TRY_CAST(src.COLLISION_ID AS INT) IS NOT NULL;

END;

GO