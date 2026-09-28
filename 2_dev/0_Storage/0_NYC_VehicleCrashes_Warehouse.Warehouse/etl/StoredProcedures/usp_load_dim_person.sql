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
        NULLIF(TRIM(src.person_type),          '') AS person_type,
        NULLIF(TRIM(src.person_sex),           '') AS person_sex,
        NULLIF(TRIM(src.ejection),             '') AS ejection,
        NULLIF(TRIM(src.emotional_status),     '') AS emotional_status,
        NULLIF(TRIM(src.bodily_injury),        '') AS bodily_injury,
        NULLIF(TRIM(src.position_in_vehicle),  '') AS position_in_vehicle,
        NULLIF(TRIM(src.safety_equipment),     '') AS safety_equipment,
        NULLIF(TRIM(src.ped_location),         '') AS ped_location,
        NULLIF(TRIM(src.ped_action),           '') AS ped_action,
        NULLIF(TRIM(src.ped_role),             '') AS ped_role
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_persons src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_person tgt
        WHERE  ISNULL(tgt.person_type,         '') = ISNULL(NULLIF(TRIM(src.person_type),         ''), '')
          AND  ISNULL(tgt.person_sex,          '') = ISNULL(NULLIF(TRIM(src.person_sex),          ''), '')
          AND  ISNULL(tgt.ejection,            '') = ISNULL(NULLIF(TRIM(src.ejection),            ''), '')
          AND  ISNULL(tgt.emotional_status,    '') = ISNULL(NULLIF(TRIM(src.emotional_status),    ''), '')
          AND  ISNULL(tgt.bodily_injury,       '') = ISNULL(NULLIF(TRIM(src.bodily_injury),       ''), '')
          AND  ISNULL(tgt.position_in_vehicle, '') = ISNULL(NULLIF(TRIM(src.position_in_vehicle), ''), '')
          AND  ISNULL(tgt.safety_equipment,    '') = ISNULL(NULLIF(TRIM(src.safety_equipment),    ''), '')
          AND  ISNULL(tgt.ped_location,        '') = ISNULL(NULLIF(TRIM(src.ped_location),        ''), '')
          AND  ISNULL(tgt.ped_action,          '') = ISNULL(NULLIF(TRIM(src.ped_action),          ''), '')
          AND  ISNULL(tgt.ped_role,            '') = ISNULL(NULLIF(TRIM(src.ped_role),            ''), '')
    );

END;

GO