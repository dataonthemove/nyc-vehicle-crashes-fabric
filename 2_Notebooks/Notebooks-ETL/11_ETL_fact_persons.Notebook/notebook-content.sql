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

-- # 11_ETL_fact_persons
-- **Purpose:** Create stored procedure `etl.usp_load_fact_persons`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionspersons`
-- 
-- **Target:** `dbo.fact_persons`
-- 
-- **Grain:** One row per person per collision.
-- 
-- **Key logic:**
-- - `collision_key` resolved via lookup to `dim_collision` on `collision_id`
-- - `date_key` derived as INT in YYYYMMDD format from source `CRASH_DATE` (same pattern as fact_crashes)
-- - `person_key` resolved via lookup to `dim_person` on all 10 attribute columns
-- - `is_injured` = 1 where PERSON_INJURY = 'Injured'
-- - `is_killed` = 1 where PERSON_INJURY = 'Killed'
-- - `person_age` cast to INT via TRY_CAST (dirty source values possible)
-- - Incremental: skips fact_person_id already loaded via collision_key match
-- 
-- **PERSON_INJURY distinct values (profiled):** Injured, Killed, Unspecified
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure dim_collision, dim_date, dim_person are populated first.
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.


-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_fact_persons', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_fact_persons;
GO

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
        CAST(FORMAT(TRY_CAST(src.CRASH_DATE AS DATE), 'yyyyMMdd') AS INT)  AS date_key,
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
GO

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 2: Execute and verify
EXEC etl.usp_load_fact_persons;

SELECT COUNT(*) AS fact_persons_row_count FROM dbo.fact_persons;

SELECT TOP 10 * FROM dbo.fact_persons ORDER BY fact_person_id;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
