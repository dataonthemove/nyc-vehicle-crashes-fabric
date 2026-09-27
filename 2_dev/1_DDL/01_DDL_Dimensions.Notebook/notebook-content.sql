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

-- # 01 — DDL: Dimension Tables
-- **Warehouse:** NYC_VehicleCrashes_Warehouse  
-- **Created:** 2026-06-08  
-- **Updated:** 2026-06-09 — added dim_damage; removed pre_crash, point_of_impact from dim_vehicle
-- **Updated:** 2026-06-10 — dim_vehicle: vehicle_make VARCHAR(60), vehicle_occupants VARCHAR(15)
-- **Updated:** 2026-06-10 — dim_person: position_in_vehicle VARCHAR(100) — source max 86 chars
-- **Updated:** 2026-06-12 — added dim_factor_group (Kimball factor-group bridge pattern); removed vehicle_occupants from dim_vehicle (relocated to fact_crash_vehicle as numeric measure)
-- **Updated:** 2026-09-26 — dim_collision dropped; collision_id is a degenerate dimension on the facts (ADR-0005)
-- **Updated:** 2026-09-27 — dim_factor_group: one row per distinct factor set; collision_id replaced by factor_set_hash (ADR-0005, D3)
-- **Updated:** 2026-09-27 — dim_location: latitude/longitude moved to fact_crashes; borough/zip_code only, plus an Unknown member row inserted by the load (ADR-0005, D8/D15)
-- **Updated:** 2026-09-27 — dim_damage renamed dim_vehicle_circumstance and gains travel_direction; new dim_driver takes the driver columns; dim_vehicle drops vehicle_model (ADR-0005, D6/D7/D9/D16)
-- **Fabric Warehouse T-SQL constraints:**
-- - No PRIMARY KEY or UNIQUE constraints in CREATE TABLE
-- - No TINYINT — use SMALLINT
-- - IDENTITY columns must be BIGINT with no SEED/INCREMENT params
-- - Uniqueness enforced at stored procedure level
-- - Drop order respects dependencies — facts and bridges dropped before dims

-- MARKDOWN ********************

-- ## Step 1 — Drop dependent tables first (reverse dependency order)

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

-- ## Step 2 — Drop dimension tables

-- CELL ********************

IF OBJECT_ID('dbo.dim_factor_group',        'U') IS NOT NULL DROP TABLE dbo.dim_factor_group;
IF OBJECT_ID('dbo.dim_driver',              'U') IS NOT NULL DROP TABLE dbo.dim_driver;
IF OBJECT_ID('dbo.dim_vehicle_circumstance', 'U') IS NOT NULL DROP TABLE dbo.dim_vehicle_circumstance;
IF OBJECT_ID('dbo.dim_damage',              'U') IS NOT NULL DROP TABLE dbo.dim_damage;  -- legacy, renamed dim_vehicle_circumstance 2026-09-27 (ADR-0005)
IF OBJECT_ID('dbo.dim_vehicle',             'U') IS NOT NULL DROP TABLE dbo.dim_vehicle;
IF OBJECT_ID('dbo.dim_person',              'U') IS NOT NULL DROP TABLE dbo.dim_person;
IF OBJECT_ID('dbo.dim_contributing_factor', 'U') IS NOT NULL DROP TABLE dbo.dim_contributing_factor;
IF OBJECT_ID('dbo.dim_location',            'U') IS NOT NULL DROP TABLE dbo.dim_location;
IF OBJECT_ID('dbo.dim_collision',           'U') IS NOT NULL DROP TABLE dbo.dim_collision;  -- legacy, dropped 2026-09-26 (ADR-0005)
IF OBJECT_ID('dbo.dim_date',                'U') IS NOT NULL DROP TABLE dbo.dim_date;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 3 — Create dim_date
-- > date_key is INT (YYYYMMDD format) — not an IDENTITY column.

-- CELL ********************

CREATE TABLE dbo.dim_date (
    date_key        INT          NOT NULL,
    full_date       DATE         NOT NULL,
    year            SMALLINT     NOT NULL,
    quarter         SMALLINT     NOT NULL,
    month           SMALLINT     NOT NULL,
    month_name      VARCHAR(10)  NOT NULL,
    day             SMALLINT     NOT NULL,
    day_of_week     SMALLINT     NOT NULL,
    day_name        VARCHAR(10)  NOT NULL,
    is_weekend      BIT          NOT NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 4 — Create dim_location

-- CELL ********************

CREATE TABLE dbo.dim_location (
    location_key    BIGINT       NOT NULL IDENTITY,
    borough         VARCHAR(50)  NULL,
    zip_code        VARCHAR(10)  NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 5 — Create dim_contributing_factor

-- CELL ********************

CREATE TABLE dbo.dim_contributing_factor (
    factor_key      BIGINT        NOT NULL IDENTITY,
    factor_desc     VARCHAR(100)  NOT NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 6 — Create dim_person
-- > 2026-06-10: position_in_vehicle VARCHAR(100) — source max 86 chars

-- CELL ********************

CREATE TABLE dbo.dim_person (
    person_key              BIGINT        NOT NULL IDENTITY,
    person_type             VARCHAR(50)   NULL,
    person_sex              VARCHAR(10)   NULL,
    ejection                VARCHAR(50)   NULL,
    emotional_status        VARCHAR(50)   NULL,
    bodily_injury           VARCHAR(100)  NULL,
    position_in_vehicle     VARCHAR(100)  NULL,
    safety_equipment        VARCHAR(100)  NULL,
    ped_location            VARCHAR(100)  NULL,
    ped_action              VARCHAR(100)  NULL,
    ped_role                VARCHAR(50)   NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 7 — Create dim_vehicle
-- > pre_crash and point_of_impact removed — those belong exclusively to dim_vehicle_circumstance
-- > 2026-06-10: vehicle_make VARCHAR(60), vehicle_occupants VARCHAR(15) — profiled from source
-- > 2026-06-12: vehicle_occupants removed — relocated to fact_crash_vehicle as numeric measure
-- > 2026-09-27: driver columns moved to dim_driver, travel_direction to dim_vehicle_circumstance, vehicle_model dropped (ADR-0005, D6/D7/D9)

-- CELL ********************

CREATE TABLE dbo.dim_vehicle (
    vehicle_key                  BIGINT       NOT NULL IDENTITY,
    vehicle_type                 VARCHAR(100) NULL,
    vehicle_make                 VARCHAR(60)  NULL,
    vehicle_year                 SMALLINT     NULL,
    state_registration           VARCHAR(10)  NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 8 — Create dim_vehicle_circumstance (junk dimension)
-- > Junk dimension collapsing low-cardinality descriptors of the vehicle's circumstances in one crash
-- > Profiled distinct combinations: 4,523 across 4.4M vehicle rows (before travel_direction was added)
-- > pre_crash and point_of_impact exclusively here — removed from dim_vehicle
-- > 2026-09-27: renamed from dim_damage (damage_key → vehicle_circumstance_key); travel_direction moved here from dim_vehicle (ADR-0005, D7/D16)

-- CELL ********************

CREATE TABLE dbo.dim_vehicle_circumstance (
    vehicle_circumstance_key  BIGINT        NOT NULL IDENTITY,
    pre_crash                 VARCHAR(100)  NULL,
    travel_direction          VARCHAR(20)   NULL,
    point_of_impact           VARCHAR(100)  NULL,
    vehicle_damage            VARCHAR(100)  NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 9 — Create dim_driver
-- > 2026-09-27: driver attributes split out of dim_vehicle (ADR-0005, D6)

-- CELL ********************

CREATE TABLE dbo.dim_driver (
    driver_key                   BIGINT       NOT NULL IDENTITY,
    driver_sex                   VARCHAR(10)  NULL,
    driver_license_status        VARCHAR(50)  NULL,
    driver_license_jurisdiction  VARCHAR(50)  NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 10 — Create dim_factor_group
-- > 2026-06-12: Kimball factor-group bridge pattern (Fig. 14-4 analog)
-- > Restores conventional many-to-one joins on both
-- > fact_crashes (factor_group_key FK) and bridge_crash_factor (factor_group_key FK)
-- > 2026-09-27: one row per distinct factor set (ADR-0005, D3); collision_id removed
-- > factor_set_hash: SHA-256 hex over the sorted distinct factor_desc values — ETL plumbing used to
-- > resolve factor_group_key, not a descriptive attribute; hidden in the semantic model

-- CELL ********************

CREATE TABLE dbo.dim_factor_group (
    factor_group_key  BIGINT       NOT NULL IDENTITY,
    factor_set_hash   VARCHAR(64)  NOT NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 11 — Verify all dimension tables created

-- CELL ********************

SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'dim_%'
ORDER BY TABLE_NAME;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
