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

-- # 07_ETL_dim_vehicle
-- **Purpose:** Create stored procedure `etl.usp_load_dim_vehicle`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles`
-- 
-- **Target:** `dbo.dim_vehicle`
-- 
-- **Logic:** Incremental insert of distinct vehicle attribute combinations not already in target.
-- 
-- **Updated 2026-06-12:** vehicle_occupants removed — relocated to fact_crash_vehicle (numeric measure, see 12_ETL_fact_crash_vehicle)
-- 
-- **Updated 2026-09-27:** vehicle attributes only — driver_sex/driver_license_status/driver_license_jurisdiction moved to dim_driver (07b_ETL_dim_driver), travel_direction to dim_vehicle_circumstance, vehicle_model dropped (ADR-0005, D6/D7/D9)
-- 
-- **vehicle_year cleansing (2026-10-10):** loaded as NULL unless it lies between 1900 and the crash year + 1, the crash year taken from the same source row's `crash_date`. Source years ranged 1000 to 20063 across 4,551,002 crash–vehicles; about 2,927 were impossible. 1900–1979 is kept (1,019 classic vehicles). The expression is identical in `etl.usp_load_fact_crash_vehicle`'s `dim_vehicle` lookup — change both together or the fact's INNER JOIN drops vehicles. `dim_vehicle` is keyed on its whole attribute set, so existing rows are not patched: empty `dim_vehicle` and `fact_crash_vehicle` and reload (`vehicle_key` values are regenerated).
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_vehicle', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_vehicle;
GO

CREATE PROCEDURE etl.usp_load_dim_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    -- Vehicle only: driver attributes live in dim_driver, travel_direction in
    -- dim_vehicle_circumstance, vehicle_model is dropped (ADR-0005, D6/D7/D9).
    INSERT INTO dbo.dim_vehicle
    (
        vehicle_type,
        vehicle_make,
        vehicle_year,
        state_registration
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.vehicle_type),       '') AS vehicle_type,
        NULLIF(TRIM(src.vehicle_make),       '') AS vehicle_make,
        -- Model year cleansing: NULL unless 1900 to the source row's crash year + 1.
        -- Identical in usp_load_dim_vehicle and usp_load_fact_crash_vehicle (vehicle_key lookup).
        CASE WHEN TRY_CAST(src.vehicle_year AS SMALLINT)
                  BETWEEN 1900 AND YEAR(TRY_CAST(src.crash_date AS DATE)) + 1
             THEN TRY_CAST(src.vehicle_year AS SMALLINT) END  AS vehicle_year,
        NULLIF(TRIM(src.state_registration), '') AS state_registration
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle tgt
        WHERE  ISNULL(tgt.vehicle_type,       '') = ISNULL(NULLIF(TRIM(src.vehicle_type),       ''), '')
          AND  ISNULL(tgt.vehicle_make,       '') = ISNULL(NULLIF(TRIM(src.vehicle_make),       ''), '')
          AND  ISNULL(tgt.vehicle_year,       -1) = ISNULL(CASE WHEN TRY_CAST(src.vehicle_year AS SMALLINT)
                                                        BETWEEN 1900 AND YEAR(TRY_CAST(src.crash_date AS DATE)) + 1
                                                   THEN TRY_CAST(src.vehicle_year AS SMALLINT) END, -1)
          AND  ISNULL(tgt.state_registration, '') = ISNULL(NULLIF(TRIM(src.state_registration), ''), '')
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
EXEC etl.usp_load_dim_vehicle;

SELECT COUNT(*) AS dim_vehicle_row_count FROM dbo.dim_vehicle;

SELECT TOP 10 * FROM dbo.dim_vehicle ORDER BY vehicle_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
