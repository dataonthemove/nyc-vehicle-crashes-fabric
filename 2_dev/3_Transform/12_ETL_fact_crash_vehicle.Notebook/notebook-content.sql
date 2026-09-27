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

-- # 12_ETL_fact_crash_vehicle
-- **Purpose:** Create stored procedure `etl.usp_load_fact_crash_vehicle`.
-- -- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles`
-- -- **Target:** `dbo.fact_crash_vehicle` (factless fact)
-- -- **Grain:** One row per collision x vehicle combination.
-- -- **Source profile:** 4,375,018 rows; all COLLISION_ID non-null; ~94% VEHICLE_TYPE coverage; ~79% PRE_CRASH coverage.
-- -- **Key logic:**
-- - `date_key`, `location_key`, `factor_group_key` taken from `fact_crashes` by `collision_id` (ADR-0005, 2026-09-26) — a vehicle always agrees with its crash; vehicles with no loaded crash are dropped
-- - `collision_id` carried as a degenerate dimension (ADR-0005)
-- - `vehicle_key` resolved via INNER JOIN to `dim_vehicle` on its 4 attribute columns (vehicle_occupants removed 2026-06-12; driver, travel_direction and vehicle_model removed 2026-09-27, ADR-0005)
-- - `vehicle_circumstance_key` resolved via INNER JOIN to `dim_vehicle_circumstance` on pre_crash/travel_direction/point_of_impact/vehicle_damage (renamed from dim_damage, ADR-0005 D16)
-- - `driver_key` resolved via INNER JOIN to `dim_driver` on driver_sex/driver_license_status/driver_license_jurisdiction (ADR-0005 D6)
-- - `vehicle_occupants` cast to INT from source, capped: values > 100 set to NULL (2026-06-12: relocated from dim_vehicle — numeric by nature)
-- - Incremental: skips collision_ids already in target
-- -- **vehicle_occupants cap (2026-08-01):** source `number_of_occupants` carries garbage — 152 rows exceeded 100, one being the sentinel 999999999 (max otherwise 981,990,849), inflating the column SUM from ~3.1M to 2.74B. Values above 100 are not credible for any road vehicle, so they are nulled. The cap is set at 100 rather than lower because the 21–100 band is legitimate: 809 Bus and 20 School Bus rows.
-- -- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure fact_crashes, dim_vehicle, dim_vehicle_circumstance, dim_driver are populated first.
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.
-- 5. Run Cell 3 ONCE — remediates rows loaded before the cap existed. The procedure is incremental, so a rerun alone will not correct them.


-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_fact_crash_vehicle', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_fact_crash_vehicle;
GO

CREATE PROCEDURE etl.usp_load_fact_crash_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_crash_vehicle
    (
        date_key,
        collision_id,
        location_key,
        factor_group_key,
        vehicle_key,
        vehicle_circumstance_key,
        driver_key,
        vehicle_occupants
    )
    SELECT
        fc.date_key,
        fc.collision_id,
        fc.location_key,
        fc.factor_group_key,
        dv.vehicle_key,
        dvc.vehicle_circumstance_key,
        ddr.driver_key,
        CASE
            WHEN TRY_CAST(src.vehicle_occupants AS INT) > 100 THEN NULL
            ELSE TRY_CAST(src.vehicle_occupants AS INT)
        END AS vehicle_occupants
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src

    -- Header keys (date_key, location_key, factor_group_key) come from the vehicle's crash,
    -- never the vehicle row (ADR-0005). Vehicles with no loaded crash are dropped.
    INNER JOIN dbo.fact_crashes fc
        ON fc.collision_id = TRY_CAST(src.collision_id AS INT)

    -- Resolve vehicle_key
    INNER JOIN dbo.dim_vehicle dv
        ON  ISNULL(dv.vehicle_type,       '') = ISNULL(NULLIF(TRIM(src.vehicle_type),       ''), '')
        AND ISNULL(dv.vehicle_make,       '') = ISNULL(NULLIF(TRIM(src.vehicle_make),       ''), '')
        AND ISNULL(dv.vehicle_year,       -1) = ISNULL(TRY_CAST(src.vehicle_year AS SMALLINT), -1)
        AND ISNULL(dv.state_registration, '') = ISNULL(NULLIF(TRIM(src.state_registration), ''), '')

    -- Resolve vehicle_circumstance_key
    INNER JOIN dbo.dim_vehicle_circumstance dvc
        ON  ISNULL(dvc.pre_crash,        '') = ISNULL(NULLIF(TRIM(src.pre_crash),        ''), '')
        AND ISNULL(dvc.travel_direction, '') = ISNULL(NULLIF(TRIM(src.travel_direction), ''), '')
        AND ISNULL(dvc.point_of_impact,  '') = ISNULL(NULLIF(TRIM(src.point_of_impact),  ''), '')
        AND ISNULL(dvc.vehicle_damage,   '') = ISNULL(NULLIF(TRIM(src.vehicle_damage),   ''), '')

    -- Resolve driver_key
    INNER JOIN dbo.dim_driver ddr
        ON  ISNULL(ddr.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.driver_sex),                  ''), '')
        AND ISNULL(ddr.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.driver_license_status),       ''), '')
        AND ISNULL(ddr.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.driver_license_jurisdiction), ''), '')

    -- Incremental: skip collisions already loaded
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crash_vehicle tgt
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
EXEC etl.usp_load_fact_crash_vehicle;

SELECT COUNT(*) AS fact_crash_vehicle_row_count FROM dbo.fact_crash_vehicle;

SELECT TOP 10 * FROM dbo.fact_crash_vehicle ORDER BY fact_crash_vehicle_id;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 3: ONE-TIME remediation of rows loaded before the vehicle_occupants cap existed.
-- The procedure is incremental (WHERE NOT EXISTS on collision_id), so rerunning it will
-- NOT revisit already-loaded rows. This UPDATE is what actually corrects them.
-- Safe to re-run: idempotent, and a no-op once no rows exceed the cap.

SELECT
    COUNT(*)                        AS rows_over_cap_before,
    SUM(CAST(vehicle_occupants AS BIGINT)) AS sum_before
FROM dbo.fact_crash_vehicle
WHERE vehicle_occupants > 100;

UPDATE dbo.fact_crash_vehicle
SET    vehicle_occupants = NULL
WHERE  vehicle_occupants > 100;

-- Verify: rows_over_cap_after must be 0; sum_after should be ~3,118,066
SELECT
    SUM(CASE WHEN vehicle_occupants > 100 THEN 1 ELSE 0 END) AS rows_over_cap_after,
    SUM(CAST(vehicle_occupants AS BIGINT))                   AS sum_after,
    MAX(vehicle_occupants)                                   AS max_after
FROM dbo.fact_crash_vehicle;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
