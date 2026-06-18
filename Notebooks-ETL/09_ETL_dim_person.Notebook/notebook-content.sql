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

-- # 09_ETL_dim_person
-- **Purpose:** Create stored procedure `etl.usp_load_dim_person`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionspersons`
-- 
-- **Target:** `dbo.dim_person`
-- 
-- **Source column max lengths profiled:** person_type(15), person_sex(1), ejection(17), emotional_status(14), bodily_injury(20), position_in_vehicle(86), safety_equipment(40), ped_location(57), ped_action(47), ped_role(15)
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_person', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_person;
GO

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

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 2: Execute and verify
EXEC etl.usp_load_dim_person;

SELECT COUNT(*) AS dim_person_row_count FROM dbo.dim_person;

SELECT TOP 10 * FROM dbo.dim_person ORDER BY person_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
