-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "sqldatawarehouse"
-- META   },
-- META   "dependencies": {
-- META     "lakehouse": {
-- META       "default_lakehouse_name": "",
-- META       "default_lakehouse_workspace_id": "",
-- META       "known_lakehouses": []
-- META     },
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

-- # 09b_ETL_dim_factor_group
-- **Purpose:** Create stored procedure `etl.usp_load_dim_factor_group`.
-- 
-- **Source:** `dbo.dim_collision`
-- 
-- **Target:** `dbo.dim_factor_group`
-- 
-- **Grain:** One row per collision (1:1 with dim_collision).
-- 
-- **Kimball factor-group bridge pattern (2026-06-12, Fig. 14-4 analog):**
-- `dim_factor_group` sits between `fact_crashes` and `bridge_crash_factor`, restoring
-- conventional many-to-one joins on both sides. `collision_key` is a 1:1 correlation
-- column (not a descriptive attribute) used by 10_ETL_fact_crashes and
-- 13_ETL_bridge_crash_factor to resolve `factor_group_key`.
-- 
-- **Key logic:**
-- - One row inserted per `collision_key` from `dim_collision` not yet in `dim_factor_group`
-- - Incremental: skips collision_keys already present
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure dim_collision is populated first.
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.
-- 5. Run BEFORE 10_ETL_fact_crashes and 13_ETL_bridge_crash_factor — both depend on dim_factor_group.


-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_factor_group', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_factor_group;
GO

CREATE PROCEDURE etl.usp_load_dim_factor_group
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_factor_group (collision_key)
    SELECT dc.collision_key
    FROM   dbo.dim_collision dc
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_factor_group tgt
        WHERE  tgt.collision_key = dc.collision_key
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
EXEC etl.usp_load_dim_factor_group;

SELECT COUNT(*) AS dim_factor_group_row_count FROM dbo.dim_factor_group;

SELECT TOP 10 * FROM dbo.dim_factor_group ORDER BY factor_group_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
