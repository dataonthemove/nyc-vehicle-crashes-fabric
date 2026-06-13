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
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles`
-- 
-- **Target:** `dbo.dim_vehicle`
-- 
-- **Logic:** Incremental insert of distinct vehicle attribute combinations not already in target.
-- 
-- **Updated 2026-06-12:** vehicle_occupants removed — relocated to fact_crash_vehicle (numeric measure, see 12_ETL_fact_crash_vehicle)
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

    INSERT INTO dbo.dim_vehicle
    (
        vehicle_type,
        vehicle_make,
        vehicle_model,
        vehicle_year,
        state_registration,
        travel_direction,
        driver_sex,
        driver_license_status,
        driver_license_jurisdiction
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.VEHICLE_TYPE),                 '') AS vehicle_type,
        NULLIF(TRIM(src.VEHICLE_MAKE),                 '') AS vehicle_make,
        NULLIF(TRIM(src.VEHICLE_MODEL),                '') AS vehicle_model,
        TRY_CAST(src.VEHICLE_YEAR AS SMALLINT)            AS vehicle_year,
        NULLIF(TRIM(src.STATE_REGISTRATION),           '') AS state_registration,
        NULLIF(TRIM(src.TRAVEL_DIRECTION),             '') AS travel_direction,
        NULLIF(TRIM(src.DRIVER_SEX),                   '') AS driver_sex,
        NULLIF(TRIM(src.DRIVER_LICENSE_STATUS),        '') AS driver_license_status,
        NULLIF(TRIM(src.DRIVER_LICENSE_JURISDICTION),  '') AS driver_license_jurisdiction
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle tgt
        WHERE  ISNULL(tgt.vehicle_type,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_TYPE),               ''), '')
          AND  ISNULL(tgt.vehicle_make,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MAKE),               ''), '')
          AND  ISNULL(tgt.vehicle_model,               '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MODEL),              ''), '')
          AND  ISNULL(tgt.vehicle_year,                -1) = ISNULL(TRY_CAST(src.VEHICLE_YEAR AS SMALLINT),      -1)
          AND  ISNULL(tgt.state_registration,          '') = ISNULL(NULLIF(TRIM(src.STATE_REGISTRATION),        ''), '')
          AND  ISNULL(tgt.travel_direction,            '') = ISNULL(NULLIF(TRIM(src.TRAVEL_DIRECTION),          ''), '')
          AND  ISNULL(tgt.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.DRIVER_SEX),                ''), '')
          AND  ISNULL(tgt.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_STATUS),     ''), '')
          AND  ISNULL(tgt.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_JURISDICTION),''), '')
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
