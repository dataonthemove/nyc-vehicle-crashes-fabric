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

-- # 05_ETL_dim_location
-- **Purpose:** Create stored procedure `etl.usp_load_dim_location`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- 
-- **Target:** `dbo.dim_location`
-- 
-- **Logic:** Incremental insert of distinct borough/zip_code/latitude/longitude combinations not already in target.
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_location', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_location;
GO

CREATE PROCEDURE etl.usp_load_dim_location
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_location
    (
        borough,
        zip_code,
        latitude,
        longitude
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.borough),    '')  AS borough,
        NULLIF(TRIM(src.zip_code),   '')  AS zip_code,
        TRY_CAST(src.latitude  AS FLOAT) AS latitude,
        TRY_CAST(src.longitude AS FLOAT) AS longitude
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_location tgt
        WHERE  ISNULL(tgt.borough,   '')  = ISNULL(NULLIF(TRIM(src.borough),   ''), '')
          AND  ISNULL(tgt.zip_code,  '')  = ISNULL(NULLIF(TRIM(src.zip_code),  ''), '')
          AND  ISNULL(tgt.latitude,  -999) = ISNULL(TRY_CAST(src.latitude  AS FLOAT), -999)
          AND  ISNULL(tgt.longitude, -999) = ISNULL(TRY_CAST(src.longitude AS FLOAT), -999)
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
EXEC etl.usp_load_dim_location;

SELECT COUNT(*) AS dim_location_row_count FROM dbo.dim_location;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
