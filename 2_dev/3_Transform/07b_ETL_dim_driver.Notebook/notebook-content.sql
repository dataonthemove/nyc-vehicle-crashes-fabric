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

-- # 07b_ETL_dim_driver
-- **Purpose:** Create stored procedure `etl.usp_load_dim_driver`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles`
-- 
-- **Target:** `dbo.dim_driver`
-- 
-- **Logic:** Incremental insert of distinct driver attribute combinations not already in target.
-- 
-- **Created 2026-09-27:** driver_sex, driver_license_status, driver_license_jurisdiction split out of dim_vehicle (ADR-0005, D6). Linking a vehicle's driver to their fact_persons row is out of scope.
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_driver', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_driver;
GO

CREATE PROCEDURE etl.usp_load_dim_driver
AS
BEGIN
    SET NOCOUNT ON;

    -- Driver attributes, split out of dim_vehicle (ADR-0005, D6).
    INSERT INTO dbo.dim_driver
    (
        driver_sex,
        driver_license_status,
        driver_license_jurisdiction
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.driver_sex),                  '') AS driver_sex,
        NULLIF(TRIM(src.driver_license_status),       '') AS driver_license_status,
        NULLIF(TRIM(src.driver_license_jurisdiction), '') AS driver_license_jurisdiction
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_driver tgt
        WHERE  ISNULL(tgt.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.driver_sex),                  ''), '')
          AND  ISNULL(tgt.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.driver_license_status),       ''), '')
          AND  ISNULL(tgt.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.driver_license_jurisdiction), ''), '')
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
EXEC etl.usp_load_dim_driver;

SELECT COUNT(*) AS dim_driver_row_count FROM dbo.dim_driver;

SELECT TOP 10 * FROM dbo.dim_driver ORDER BY driver_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
