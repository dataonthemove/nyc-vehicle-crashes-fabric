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

-- # 06_ETL_dim_contributing_factor
-- **Purpose:** Create stored procedure `etl.usp_load_dim_contributing_factor`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- 
-- **Source columns:** `CONTRIBUTING_FACTOR_VEHICLE_1` through `_5` (unpivoted)
-- 
-- **Target:** `dbo.dim_contributing_factor`
-- 
-- **Logic:** UNION all 5 factor columns to get distinct values; incremental insert of new factors only.
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_contributing_factor', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_contributing_factor;
GO

CREATE PROCEDURE etl.usp_load_dim_contributing_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot all 5 contributing factor columns into a single distinct list
    WITH all_factors AS
    (
        SELECT NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    )
    INSERT INTO dbo.dim_contributing_factor (factor_desc)
    SELECT factor_desc
    FROM   all_factors src
    WHERE  src.factor_desc IS NOT NULL
      AND  NOT EXISTS
           (
               SELECT 1
               FROM   dbo.dim_contributing_factor tgt
               WHERE  tgt.factor_desc = src.factor_desc
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
EXEC etl.usp_load_dim_contributing_factor;

SELECT COUNT(*) AS dim_contributing_factor_row_count FROM dbo.dim_contributing_factor;

SELECT TOP 20 * FROM dbo.dim_contributing_factor ORDER BY factor_desc;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
