CREATE PROCEDURE etl.usp_load_fact_persons
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_persons
    (
        date_key,
        collision_key,
        person_key,
        person_age,
        is_injured,
        is_killed
    )
    SELECT
        CAST(FORMAT(TRY_CAST(src.crash_date AS DATE), 'yyyyMMdd') AS INT)  AS date_key,
        dc.collision_key,
        dp.person_key,
        TRY_CAST(src.person_age AS INT)                                    AS person_age,
        CASE WHEN src.person_injury = 'Injured' THEN 1 ELSE 0 END          AS is_injured,
        CASE WHEN src.person_injury = 'Killed'  THEN 1 ELSE 0 END          AS is_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_persons src

    -- Resolve collision_key
    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(src.collision_id AS INT)

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
        WHERE  tgt.collision_key = dc.collision_key
    )
    AND TRY_CAST(src.crash_date   AS DATE) IS NOT NULL
    AND TRY_CAST(src.collision_id AS INT)  IS NOT NULL;

END;

GO