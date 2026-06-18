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

-- # 04_ETL_dim_collision
-- **Purpose:** Create stored procedure `etl.usp_load_dim_collision`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes`
-- 
-- **Target:** `dbo.dim_collision`
-- 
-- **Logic:** INSERT distinct `COLLISION_ID` values not already present in target (incremental load).
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute procedure.
-- 4. In production, invoke via Pipeline Script activity.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_collision', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_collision;
GO

CREATE PROCEDURE etl.usp_load_dim_collision
AS
BEGIN
    SET NOCOUNT ON;

    -- Incremental insert: only new collision_ids not yet in dim_collision
    INSERT INTO dbo.dim_collision (collision_id)
        SELECT DISTINCT CAST(src.COLLISION_ID AS INT)
        FROM   NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes src
        WHERE  src.COLLISION_ID IS NOT NULL
        AND  NOT EXISTS (
                SELECT 1
                FROM   dbo.dim_collision tgt
                WHERE  tgt.collision_id = CAST(src.COLLISION_ID AS INT)
            );

END;
GO

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 2: Execute the procedure
EXEC etl.usp_load_dim_collision;

-- Verify
SELECT COUNT(*) AS dim_collision_row_count FROM dbo.dim_collision;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
