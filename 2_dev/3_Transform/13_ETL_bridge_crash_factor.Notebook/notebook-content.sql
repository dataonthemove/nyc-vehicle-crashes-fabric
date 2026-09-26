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

-- # 13_ETL_bridge_crash_factor
-- **Purpose:** Create stored procedure `etl.usp_load_bridge_crash_factor`.
-- -- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- -- **Target:** `dbo.bridge_crash_factor`
-- -- **Grain:** One row per factor-group x contributing factor combination.
-- -- **Source profile (non-null counts):** CF1: 2,232,018 | CF2: 1,878,117 | CF3: 162,137 | CF4: 37,055 | CF5: 10,154
-- -- **2026-06-12 — Kimball factor-group bridge pattern (Fig. 14-4 analog):**
-- `collision_key` replaced by `factor_group_key`. fact_crashes -> dim_factor_group -> bridge_crash_factor -> dim_contributing_factor,
-- conventional many-to-one joins in all directions.
-- -- **Key logic:**
-- - UNION all 5 factor columns to produce collision_id x factor_desc pairs
-- - Filter out NULL and 'Unspecified' factors
-- - Resolve `factor_group_key` via INNER JOIN to `dim_factor_group` on `collision_id`
-- - Resolve `factor_key` via INNER JOIN to `dim_contributing_factor`
-- - Incremental: skip factor_group_keys already in target
-- -- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure dim_factor_group and dim_contributing_factor are populated first (run 09b_ETL_dim_factor_group before this).
-- 3. Run Cell 1 — DROP/CREATE procedure.
-- 4. Run Cell 2 — execute and verify.


-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_bridge_crash_factor', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_bridge_crash_factor;
GO

CREATE PROCEDURE etl.usp_load_bridge_crash_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot 5 contributing factor columns into collision x factor pairs
    WITH unpivoted AS
    (
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    )
    INSERT INTO dbo.bridge_crash_factor (factor_group_key, factor_key)
    SELECT
        dfg.factor_group_key,
        df.factor_key
    FROM  unpivoted u

    -- Resolve factor_group_key (1:1 with collision_id)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.collision_id = TRY_CAST(u.collision_id AS INT)

    INNER JOIN dbo.dim_contributing_factor df
        ON df.factor_desc = u.factor_desc

    WHERE u.factor_desc IS NOT NULL
      AND u.factor_desc <> 'Unspecified'
      AND TRY_CAST(u.collision_id AS INT) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM   dbo.bridge_crash_factor tgt
          WHERE  tgt.factor_group_key = dfg.factor_group_key
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
EXEC etl.usp_load_bridge_crash_factor;

SELECT COUNT(*) AS bridge_crash_factor_row_count FROM dbo.bridge_crash_factor;

SELECT TOP 10 * FROM dbo.bridge_crash_factor ORDER BY factor_group_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
