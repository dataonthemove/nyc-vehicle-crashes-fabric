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
-- -- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_persons`
-- -- **Target:** `dbo.fact_persons`
-- -- **Grain:** One row per person per collision.
-- -- **Key logic:**
-- - `collision_id` carried as a degenerate dimension (ADR-0005)
-- - `date_key`, `location_key`, `factor_group_key` taken from `fact_crashes` by `collision_id` (ADR-0005, 2026-09-26) — a person always agrees with its crash; persons with no loaded crash are dropped
-- - `person_key` resolved via lookup to `dim_person` on all 10 attribute columns
-- - `is_injured` = 1 where PERSON_INJURY = 'Injured'
-- - `is_killed` = 1 where PERSON_INJURY = 'Killed'
-- - `person_age` cast to INT via TRY_CAST (dirty source values possible)
-- - Incremental: skips collisions already loaded (collision_id match)
-- -- **PERSON_INJURY distinct values (profiled):** Injured, Killed, Unspecified
-- -- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure fact_crashes and dim_person are populated first.
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
        TRY_CAST(src.person_age AS INT)                                    AS person_age,
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
