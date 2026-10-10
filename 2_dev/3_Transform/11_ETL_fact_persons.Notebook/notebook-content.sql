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
-- - `person_age` cast to INT via TRY_CAST, then cleansed: NULL when < 0 or > 110; 0 → NULL unless Person Role (`ped_role`) is Passenger or Pedestrian
-- - Incremental: skips collisions already loaded (collision_id match)
-- -- **PERSON_INJURY distinct values (profiled):** Injured, Killed, Unspecified
-- -- **person_age cleansing (2026-10-10):** source `person_age` ranged −999 to 9999 across 5,984,110 rows. Above 110 the count jumps from 76 rows (106–110) to 627 (111–120), so the tail is junk. 548,420 rows were 0, mostly meaning "unknown": 507,484 Registrants (owners not in the crash) and 6,890 Drivers. Only Passengers (17,308) and Pedestrians (1,157) hold plausible infants, so 0 is kept for those roles alone.
-- -- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure fact_crashes and dim_person are populated first.
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.
-- 5. Run Cell 3 ONCE per stage — remediates rows loaded before the age cleansing existed. The procedure is incremental, so a rerun alone will not correct them.


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

-- CELL ********************

-- Cell 3: ONE-TIME remediation of rows loaded before the person_age cleansing existed.
-- The procedure is incremental (WHERE NOT EXISTS on collision_id), so rerunning it will
-- NOT revisit already-loaded rows. This UPDATE is what actually corrects them.
-- Same rule as the person_age CASE in etl.usp_load_fact_persons; role from dim_person.
-- Safe to re-run: idempotent, and a no-op once no row breaks the rule.

SELECT
    COUNT(*)                                                    AS row_count_before,
    SUM(CASE WHEN fp.person_age IS NULL THEN 1 ELSE 0 END)      AS blank_age_before,
    SUM(CASE WHEN fp.person_age < 0 OR fp.person_age > 110
             OR (fp.person_age = 0
                 AND ISNULL(dp.ped_role, '') NOT IN ('Passenger', 'Pedestrian'))
             THEN 1 ELSE 0 END)                                 AS rows_to_null
FROM dbo.fact_persons fp
LEFT JOIN dbo.dim_person dp
    ON dp.person_key = fp.person_key;

UPDATE fp
SET    person_age = NULL
FROM   dbo.fact_persons fp
LEFT JOIN dbo.dim_person dp
    ON dp.person_key = fp.person_key
WHERE  fp.person_age < 0
   OR  fp.person_age > 110
   OR  (fp.person_age = 0
        AND ISNULL(dp.ped_role, '') NOT IN ('Passenger', 'Pedestrian'));

-- Verify: row_count_after = row_count_before; blank_age_after = blank_age_before + rows_to_null;
-- min_age_after >= 0; max_age_after <= 110; non_infant_zeros_after = 0
-- Dev expectation (baseline 2026-10-10): rows_to_null 535,179; blank_age_after 1,211,090; rows 5,984,110
SELECT
    COUNT(*)                                                    AS row_count_after,
    SUM(CASE WHEN fp.person_age IS NULL THEN 1 ELSE 0 END)      AS blank_age_after,
    MIN(fp.person_age)                                          AS min_age_after,
    MAX(fp.person_age)                                          AS max_age_after,
    SUM(CASE WHEN fp.person_age = 0
             AND ISNULL(dp.ped_role, '') NOT IN ('Passenger', 'Pedestrian')
             THEN 1 ELSE 0 END)                                 AS non_infant_zeros_after
FROM dbo.fact_persons fp
LEFT JOIN dbo.dim_person dp
    ON dp.person_key = fp.person_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
