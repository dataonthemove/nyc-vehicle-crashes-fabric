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
-- **Updated:** 2026-09-26 — collision_key replaced by degenerate collision_id on all three facts (dim_collision dropped); fact_persons and fact_crash_vehicle carry the header keys location_key and factor_group_key (ADR-0005)
-- **Updated:** 2026-09-27 — fact_crashes: latitude/longitude moved here from dim_location (ADR-0005, D8)
-- **Updated:** 2026-09-27 — fact_crash_vehicle: damage_key renamed vehicle_circumstance_key (dim_vehicle_circumstance); added driver_key (FK dim_driver) (ADR-0005, D6/D16)
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
-- > FK references: dim_date, dim_location, dim_factor_group; collision_id is a degenerate dimension
-- > 2026-06-12: added factor_group_key — restores conventional many-to-one join to bridge_crash_factor via dim_factor_group

-- CELL ********************

CREATE TABLE dbo.fact_crashes (
    crash_id            BIGINT  NOT NULL IDENTITY,
    date_key            INT     NOT NULL,  -- FK dim_date (YYYYMMDD)        
    collision_id        INT     NOT NULL,  -- degenerate dimension
    location_key        BIGINT  NOT NULL,  -- FK dim_location
    factor_group_key    BIGINT  NOT NULL,  -- FK dim_factor_group
    latitude            FLOAT   NULL,      -- crash point, moved from dim_location (D8)
    longitude           FLOAT   NULL,
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
-- > date_key, location_key, factor_group_key are header keys copied from fact_crashes by collision_id (ADR-0005)
-- > PERSON_INJURY source column drives is_injured and is_killed flags

-- CELL ********************

CREATE TABLE dbo.fact_persons (
    fact_person_id    BIGINT  NOT NULL IDENTITY,
    date_key          INT     NOT NULL,  -- FK dim_date (YYYYMMDD)
    collision_id      INT     NOT NULL,  -- degenerate dimension
    location_key      BIGINT  NOT NULL,  -- FK dim_location (header key)
    factor_group_key  BIGINT  NOT NULL,  -- FK dim_factor_group (header key)
    person_key        BIGINT  NOT NULL,  -- FK dim_person
    person_age        INT     NULL,
    is_injured        BIT     NOT NULL,
    is_killed         BIT     NOT NULL
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
-- > vehicle_circumstance_key links to dim_vehicle_circumstance junk dimension (PRE_CRASH, TRAVEL_DIRECTION, POINT_OF_IMPACT, VEHICLE_DAMAGE)
-- > driver_key links to dim_driver (DRIVER_SEX, DRIVER_LICENSE_STATUS, DRIVER_LICENSE_JURISDICTION)
-- > Replaces VEHICLE_TYPE_CODE_1-5 columns on fact_crashes
-- > 2026-06-12: added vehicle_occupants (INT) — relocated from dim_vehicle, source is numeric by nature
-- > date_key, location_key, factor_group_key are header keys copied from fact_crashes by collision_id (ADR-0005)

-- CELL ********************

CREATE TABLE dbo.fact_crash_vehicle (
    fact_crash_vehicle_id   BIGINT  NOT NULL IDENTITY,
    date_key                INT     NOT NULL,  -- FK dim_date (YYYYMMDD)
    collision_id            INT     NOT NULL,  -- degenerate dimension
    location_key            BIGINT  NOT NULL,  -- FK dim_location (header key)
    factor_group_key        BIGINT  NOT NULL,  -- FK dim_factor_group (header key)
    vehicle_key             BIGINT  NOT NULL,  -- FK dim_vehicle
    vehicle_circumstance_key BIGINT NOT NULL,  -- FK dim_vehicle_circumstance
    driver_key              BIGINT  NOT NULL,  -- FK dim_driver
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
