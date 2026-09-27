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
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes`
-- 
-- **Target:** `dbo.dim_factor_group`
-- 
-- **Grain:** One row per distinct set of contributing factors (ADR-0005, D3).
-- 
-- **Kimball factor-group bridge pattern (2026-06-12, Fig. 14-4 analog):**
-- `dim_factor_group` sits between `fact_crashes` and `bridge_crash_factor`, restoring
-- conventional many-to-one joins on both sides. Crashes with the same factor set share one group.
-- 
-- **Key logic:**
-- - UNION all 5 factor columns per crash (duplicates within a crash collapse)
-- - `factor_set_hash` = SHA-256 (hex) over the crash's sorted distinct `factor_desc` values, `|`-delimited;
--   business values, not `factor_key` (IDENTITY, unstable across a dim_contributing_factor reload)
-- - NULL and 'Unspecified' excluded: crashes with no specified factor all hash '' — one empty-set group, no bridge rows
-- - Incremental: inserts only hashes not yet in `dim_factor_group`
-- - The same hash derivation is repeated in 10_ETL_fact_crashes and 13_ETL_bridge_crash_factor — change all three together
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Ensure the Lakehouse crashes are ingested and dim_contributing_factor is loaded first.
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

    -- Unpivot 5 contributing factor columns into collision x factor pairs (UNION collapses duplicates within a crash)
    WITH crash_factor AS
    (
        SELECT TRY_CAST(collision_id AS INT) AS collision_id, NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    ),
    -- One factor set per crash: SHA-256 over its sorted distinct specified factor_desc values.
    -- No specified factor (NULL or 'Unspecified') hashes '' -> the single empty-set group.
    -- Identical in usp_load_dim_factor_group, usp_load_fact_crashes and usp_load_bridge_crash_factor.
    crash_factor_set AS
    (
        SELECT
            collision_id,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', ISNULL(
                STRING_AGG(CASE WHEN factor_desc <> 'Unspecified' THEN factor_desc END, '|')
                    WITHIN GROUP (ORDER BY factor_desc), '')), 2) AS factor_set_hash
        FROM   crash_factor
        WHERE  collision_id IS NOT NULL
        GROUP  BY collision_id
    )
    INSERT INTO dbo.dim_factor_group (factor_set_hash)
    SELECT DISTINCT cfs.factor_set_hash
    FROM   crash_factor_set cfs

    -- Incremental: add only factor sets not yet present
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_factor_group tgt
        WHERE  tgt.factor_set_hash = cfs.factor_set_hash
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
