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

-- # 08_ETL_dim_vehicle_circumstance
-- **Purpose:** Create stored procedure `etl.usp_load_dim_vehicle_circumstance`.
-- 
-- **Source:** `NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles`
-- 
-- **Target:** `dbo.dim_vehicle_circumstance` (junk dimension — the vehicle's circumstances in one crash)
-- 
-- **Source columns (max lengths profiled):** PRE_CRASH (26), POINT_OF_IMPACT (25), VEHICLE_DAMAGE (25) — all within VARCHAR(100); TRAVEL_DIRECTION keeps the VARCHAR(20) it had on dim_vehicle
-- 
-- **Updated 2026-09-27:** renamed from dim_damage (damage_key → vehicle_circumstance_key); travel_direction moved here from dim_vehicle (ADR-0005, D7/D16)
-- 
-- **Logic:** Incremental insert of distinct combinations not already in target.
-- 
-- **Instructions:**
-- 1. Connect notebook to `NYC_VehicleCrashes_Warehouse`.
-- 2. Run Cell 1 — DROP/CREATE procedure.
-- 3. Run Cell 2 — execute and verify.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_vehicle_circumstance', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_vehicle_circumstance;
GO

CREATE PROCEDURE etl.usp_load_dim_vehicle_circumstance
AS
BEGIN
    SET NOCOUNT ON;

    -- The vehicle's circumstances in one crash (ADR-0005, D16); travel_direction
    -- moved here from dim_vehicle (D7).
    INSERT INTO dbo.dim_vehicle_circumstance
    (
        pre_crash,
        travel_direction,
        point_of_impact,
        vehicle_damage
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.pre_crash),        '') AS pre_crash,
        NULLIF(TRIM(src.travel_direction), '') AS travel_direction,
        NULLIF(TRIM(src.point_of_impact),  '') AS point_of_impact,
        NULLIF(TRIM(src.vehicle_damage),   '') AS vehicle_damage
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle_circumstance tgt
        WHERE  ISNULL(tgt.pre_crash,        '') = ISNULL(NULLIF(TRIM(src.pre_crash),        ''), '')
          AND  ISNULL(tgt.travel_direction, '') = ISNULL(NULLIF(TRIM(src.travel_direction), ''), '')
          AND  ISNULL(tgt.point_of_impact,  '') = ISNULL(NULLIF(TRIM(src.point_of_impact),  ''), '')
          AND  ISNULL(tgt.vehicle_damage,   '') = ISNULL(NULLIF(TRIM(src.vehicle_damage),   ''), '')
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
EXEC etl.usp_load_dim_vehicle_circumstance;

SELECT COUNT(*) AS dim_vehicle_circumstance_row_count FROM dbo.dim_vehicle_circumstance;

SELECT TOP 10 * FROM dbo.dim_vehicle_circumstance ORDER BY vehicle_circumstance_key;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
