CREATE PROCEDURE etl.usp_load_fact_persons
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_persons
    (
        date_key,
        collision_id,
        location_key,
        factor_group_key,
        person_key,
        person_age,
        is_injured,
        is_killed
    )
    SELECT
        fc.date_key,
        fc.collision_id,
        fc.location_key,
        fc.factor_group_key,
        dp.person_key,
        -- Age cleansing (same rule as the Cell 3 backfill in notebook 11_ETL_fact_persons):
        -- < 0 or > 110 is junk; 0 means "unknown" except for Passenger/Pedestrian (real infants).
        CASE
            WHEN TRY_CAST(src.person_age AS INT) < 0
              OR TRY_CAST(src.person_age AS INT) > 110 THEN NULL
            WHEN TRY_CAST(src.person_age AS INT) = 0
             AND ISNULL(dp.ped_role, '') NOT IN ('Passenger', 'Pedestrian') THEN NULL
            ELSE TRY_CAST(src.person_age AS INT)
        END                                                                AS person_age,
        CASE WHEN src.person_injury = 'Injured' THEN 1 ELSE 0 END          AS is_injured,
        CASE WHEN src.person_injury = 'Killed'  THEN 1 ELSE 0 END          AS is_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_persons src

    -- Header keys (date_key, location_key, factor_group_key) come from the person's crash,
    -- never the person row (ADR-0005). Persons with no loaded crash are dropped.
    INNER JOIN dbo.fact_crashes fc
        ON fc.collision_id = TRY_CAST(src.collision_id AS INT)

    -- Resolve person_key
    INNER JOIN dbo.dim_person dp
        ON  ISNULL(dp.person_type,         '') = ISNULL(NULLIF(TRIM(src.person_type),         ''), '')
        AND ISNULL(dp.person_sex,          '') = ISNULL(NULLIF(TRIM(src.person_sex),          ''), '')
        AND ISNULL(dp.ejection,            '') = ISNULL(NULLIF(TRIM(src.ejection),            ''), '')
        AND ISNULL(dp.emotional_status,    '') = ISNULL(NULLIF(TRIM(src.emotional_status),    ''), '')
        AND ISNULL(dp.bodily_injury,       '') = ISNULL(NULLIF(TRIM(src.bodily_injury),       ''), '')
        AND ISNULL(dp.position_in_vehicle, '') = ISNULL(NULLIF(TRIM(src.position_in_vehicle), ''), '')
        AND ISNULL(dp.safety_equipment,    '') = ISNULL(NULLIF(TRIM(src.safety_equipment),    ''), '')
        AND ISNULL(dp.ped_location,        '') = ISNULL(NULLIF(TRIM(src.ped_location),        ''), '')
        AND ISNULL(dp.ped_action,          '') = ISNULL(NULLIF(TRIM(src.ped_action),          ''), '')
        AND ISNULL(dp.ped_role,            '') = ISNULL(NULLIF(TRIM(src.ped_role),            ''), '')

    -- Incremental: skip collisions already loaded
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_persons tgt
        WHERE  tgt.collision_id = fc.collision_id
    );

END;

GO