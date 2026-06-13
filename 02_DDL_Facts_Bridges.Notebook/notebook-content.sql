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

-- # 02 — DDL: Fact & Bridge Tables
-- **Warehouse:** NYC_VehicleCrashes_Warehouse  
-- **Created:** 2026-06-08  
-- **Updated:** 2026-06-09 — added damage_key to fact_crash_vehicle
-- **Updated:** 2026-06-12 — fact_crashes: added factor_group_key (FK dim_factor_group); bridge_crash_factor: collision_key replaced by factor_group_key (Kimball factor-group bridge pattern); fact_crash_vehicle: added vehicle_occupants (relocated from dim_vehicle, now numeric)
-- **Fabric Warehouse T-SQL constraints:**
-- - No PRIMARY KEY or UNIQUE constraints in CREATE TABLE
-- - No TINYINT — use SMALLINT
-- - IDENTITY columns must be BIGINT with no SEED/INCREMENT params
-- - No FK constraints supported — referential integrity enforced at proc level
-- - Run notebook 01_DDL_Dimensions first — dims must exist before facts

-- MARKDOWN ********************

-- ## Step 1 — Drop fact and bridge tables (reverse dependency order)

-- CELL ********************

IF OBJECT_ID('dbo.bridge_crash_factor',  'U') IS NOT NULL DROP TABLE dbo.bridge_crash_factor;
IF OBJECT_ID('dbo.fact_crash_vehicle',   'U') IS NOT NULL DROP TABLE dbo.fact_crash_vehicle;
IF OBJECT_ID('dbo.fact_persons',         'U') IS NOT NULL DROP TABLE dbo.fact_persons;
IF OBJECT_ID('dbo.fact_crashes',         'U') IS NOT NULL DROP TABLE dbo.fact_crashes;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 2 — Create fact_crashes
-- > Grain: one row per collision event (COLLISION_ID)
-- > All measure columns cast to INT at load time via stored proc
-- > FK references: dim_collision, dim_date, dim_location, dim_factor_group
-- > 2026-06-12: added factor_group_key — restores conventional many-to-one join to bridge_crash_factor via dim_factor_group

-- CELL ********************

CREATE TABLE dbo.fact_crashes (
    crash_id            BIGINT  NOT NULL IDENTITY,
    date_key            INT     NOT NULL,  -- FK dim_date (YYYYMMDD)        
    collision_key       BIGINT  NOT NULL,  -- FK dim_collision
    location_key        BIGINT  NOT NULL,  -- FK dim_location
    factor_group_key    BIGINT  NOT NULL,  -- FK dim_factor_group
    persons_injured     INT     NULL,
    persons_killed      INT     NULL,
    pedestrians_injured INT     NULL,
    pedestrians_killed  INT     NULL,
    cyclists_injured    INT     NULL,
    cyclists_killed     INT     NULL,
    motorists_injured   INT     NULL,
    motorists_killed    INT     NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 3 — Create fact_persons
-- > Grain: one row per person per collision (UNIQUE_ID from source)
-- > CRASH_DATE removed — date resolved via dim_collision join to fact_crashes
-- > PERSON_INJURY source column drives is_injured and is_killed flags

-- CELL ********************

CREATE TABLE dbo.fact_persons (
    fact_person_id  BIGINT  NOT NULL IDENTITY,
    collision_key   BIGINT  NOT NULL,  -- FK dim_collision
    person_key      BIGINT  NOT NULL,  -- FK dim_person
    person_age      INT     NULL,
    is_injured      BIT     NOT NULL,
    is_killed       BIT     NOT NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 4 — Create fact_crash_vehicle (factless fact)
-- > Grain: one row per collision x vehicle combination
-- > Resolves many-to-many between crashes and vehicles
-- > damage_key links to dim_damage junk dimension (PRE_CRASH, POINT_OF_IMPACT, VEHICLE_DAMAGE)
-- > Replaces VEHICLE_TYPE_CODE_1-5 columns on fact_crashes
-- > 2026-06-12: added vehicle_occupants (INT) — relocated from dim_vehicle, source is numeric by nature

-- CELL ********************

CREATE TABLE dbo.fact_crash_vehicle (
    fact_crash_vehicle_id   BIGINT  NOT NULL IDENTITY,
    collision_key           BIGINT  NOT NULL,  -- FK dim_collision
    vehicle_key             BIGINT  NOT NULL,  -- FK dim_vehicle
    damage_key              BIGINT  NOT NULL,  -- FK dim_damage
    vehicle_occupants       INT     NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 5 — Create bridge_crash_factor
-- > Resolves many-to-many between crash factor-groups and contributing factors
-- > Source: CONTRIBUTING_FACTOR_VEHICLE_1-5 unpivoted from motor_vehicle_collisionscrashes
-- > 2026-06-12: collision_key replaced by factor_group_key — Kimball factor-group bridge pattern.
-- > fact_crashes -> dim_factor_group -> bridge_crash_factor -> dim_contributing_factor,
-- > conventional many-to-one joins in all directions (Fig. 14-4 analog)

-- CELL ********************

CREATE TABLE dbo.bridge_crash_factor (
    bridge_id         BIGINT  NOT NULL IDENTITY,
    factor_group_key  BIGINT  NOT NULL,  -- FK dim_factor_group
    factor_key        BIGINT  NOT NULL   -- FK dim_contributing_factor
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 6 — Verify all fact and bridge tables created

-- CELL ********************

SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'fact_%'
   OR TABLE_NAME LIKE 'bridge_%'
ORDER BY TABLE_NAME;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
