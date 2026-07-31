CREATE PROCEDURE etl.usp_load_dim_person
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_person
    (
        person_type,
        person_sex,
        ejection,
        emotional_status,
        bodily_injury,
        position_in_vehicle,
        safety_equipment,
        ped_location,
        ped_action,
        ped_role
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.PERSON_TYPE),          '') AS person_type,
        NULLIF(TRIM(src.PERSON_SEX),           '') AS person_sex,
        NULLIF(TRIM(src.EJECTION),             '') AS ejection,
        NULLIF(TRIM(src.EMOTIONAL_STATUS),     '') AS emotional_status,
        NULLIF(TRIM(src.BODILY_INJURY),        '') AS bodily_injury,
        NULLIF(TRIM(src.POSITION_IN_VEHICLE),  '') AS position_in_vehicle,
        NULLIF(TRIM(src.SAFETY_EQUIPMENT),     '') AS safety_equipment,
        NULLIF(TRIM(src.PED_LOCATION),         '') AS ped_location,
        NULLIF(TRIM(src.PED_ACTION),           '') AS ped_action,
        NULLIF(TRIM(src.PED_ROLE),             '') AS ped_role
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionspersons src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_person tgt
        WHERE  ISNULL(tgt.person_type,         '') = ISNULL(NULLIF(TRIM(src.PERSON_TYPE),         ''), '')
          AND  ISNULL(tgt.person_sex,          '') = ISNULL(NULLIF(TRIM(src.PERSON_SEX),          ''), '')
          AND  ISNULL(tgt.ejection,            '') = ISNULL(NULLIF(TRIM(src.EJECTION),            ''), '')
          AND  ISNULL(tgt.emotional_status,    '') = ISNULL(NULLIF(TRIM(src.EMOTIONAL_STATUS),    ''), '')
          AND  ISNULL(tgt.bodily_injury,       '') = ISNULL(NULLIF(TRIM(src.BODILY_INJURY),       ''), '')
          AND  ISNULL(tgt.position_in_vehicle, '') = ISNULL(NULLIF(TRIM(src.POSITION_IN_VEHICLE), ''), '')
          AND  ISNULL(tgt.safety_equipment,    '') = ISNULL(NULLIF(TRIM(src.SAFETY_EQUIPMENT),    ''), '')
          AND  ISNULL(tgt.ped_location,        '') = ISNULL(NULLIF(TRIM(src.PED_LOCATION),        ''), '')
          AND  ISNULL(tgt.ped_action,          '') = ISNULL(NULLIF(TRIM(src.PED_ACTION),          ''), '')
          AND  ISNULL(tgt.ped_role,            '') = ISNULL(NULLIF(TRIM(src.PED_ROLE),            ''), '')
    );

END;

GO