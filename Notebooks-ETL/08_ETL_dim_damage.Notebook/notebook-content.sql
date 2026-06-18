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

-- # 08_ETL_dim_damage
-- **Purpose:** Create stored procedure `etl.usp_load_dim_damage`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles`
-- 
-- **Target:** `dbo.dim_damage` (junk dimension)
-- 
-- **Source columns (max lengths profiled):** PRE_CRASH (26), POINT_OF_IMPACT (25), VEHICLE_DAMAGE (25) — all within VARCHAR(100)
-- 
-- **Logic:** Incremental insert of distinct combinations not already in target.
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_damage', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_damage;
GO

CREATE PROCEDURE etl.usp_load_dim_damage
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_damage
    (
        pre_crash,
        point_of_impact,
        vehicle_damage
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.PRE_CRASH),       '') AS pre_crash,
        NULLIF(TRIM(src.POINT_OF_IMPACT), '') AS point_of_impact,
        NULLIF(TRIM(src.VEHICLE_DAMAGE),  '') AS vehicle_damage
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_damage tgt
        WHERE  ISNULL(tgt.pre_crash,       '') = ISNULL(NULLIF(TRIM(src.PRE_CRASH),       ''), '')
          AND  ISNULL(tgt.point_of_impact, '') = ISNULL(NULLIF(TRIM(src.POINT_OF_IMPACT), ''), '')
          AND  ISNULL(tgt.vehicle_damage,  '') = ISNULL(NULLIF(TRIM(src.VEHICLE_DAMAGE),  ''), '')
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
EXEC etl.usp_load_dim_damage;

SELECT COUNT(*) AS dim_damage_row_count FROM dbo.dim_damage;

SELECT TOP 10 * FROM dbo.dim_damage ORDER BY damage_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
