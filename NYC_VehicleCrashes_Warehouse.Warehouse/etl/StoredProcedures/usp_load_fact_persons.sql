CREATE PROCEDURE etl.usp_load_fact_persons
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_persons
    (
        collision_key,
        person_key,
        person_age,
        is_injured,
        is_killed
    )
    SELECT
        dc.collision_key,
        dp.person_key,
        TRY_CAST(src.PERSON_AGE AS INT)                                    AS person_age,
        CASE WHEN src.PERSON_INJURY = 'Injured' THEN 1 ELSE 0 END          AS is_injured,
        CASE WHEN src.PERSON_INJURY = 'Killed'  THEN 1 ELSE 0 END          AS is_killed
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionspersons src

    -- Resolve collision_key
    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(src.COLLISION_ID AS INT)

    -- Resolve person_key
    INNER JOIN dbo.dim_person dp
        ON  ISNULL(dp.person_type,         '') = ISNULL(NULLIF(TRIM(src.PERSON_TYPE),         ''), '')
        AND ISNULL(dp.person_sex,          '') = ISNULL(NULLIF(TRIM(src.PERSON_SEX),          ''), '')
        AND ISNULL(dp.ejection,            '') = ISNULL(NULLIF(TRIM(src.EJECTION),            ''), '')
        AND ISNULL(dp.emotional_status,    '') = ISNULL(NULLIF(TRIM(src.EMOTIONAL_STATUS),    ''), '')
        AND ISNULL(dp.bodily_injury,       '') = ISNULL(NULLIF(TRIM(src.BODILY_INJURY),       ''), '')
        AND ISNULL(dp.position_in_vehicle, '') = ISNULL(NULLIF(TRIM(src.POSITION_IN_VEHICLE), ''), '')
        AND ISNULL(dp.safety_equipment,    '') = ISNULL(NULLIF(TRIM(src.SAFETY_EQUIPMENT),    ''), '')
        AND ISNULL(dp.ped_location,        '') = ISNULL(NULLIF(TRIM(src.PED_LOCATION),        ''), '')
        AND ISNULL(dp.ped_action,          '') = ISNULL(NULLIF(TRIM(src.PED_ACTION),          ''), '')
        AND ISNULL(dp.ped_role,            '') = ISNULL(NULLIF(TRIM(src.PED_ROLE),            ''), '')

    -- Incremental: skip collisions already loaded
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_persons tgt
        WHERE  tgt.collision_key = dc.collision_key
    )
    AND TRY_CAST(src.CRASH_DATE   AS DATE) IS NOT NULL
    AND TRY_CAST(src.COLLISION_ID AS INT)  IS NOT NULL;

END;