-- Fabric notebook source


-- MARKDOWN ********************

-- # 01 — DDL: Dimension Tables
-- **Warehouse:** NYC_VehicleCrashes_Warehouse  
-- **Created:** 2026-06-08  
-- **Updated:** 2026-06-09 — added dim_damage; removed pre_crash, point_of_impact from dim_vehicle
-- **Updated:** 2026-06-10 — dim_vehicle: vehicle_make VARCHAR(60), vehicle_occupants VARCHAR(15)
-- **Updated:** 2026-06-10 — dim_person: position_in_vehicle VARCHAR(100) — source max 86 chars
-- **Updated:** 2026-06-12 — added dim_factor_group (Kimball factor-group bridge pattern); removed vehicle_occupants from dim_vehicle (relocated to fact_crash_vehicle as numeric measure)
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
IF OBJECT_ID('dbo.dim_damage',              'U') IS NOT NULL DROP TABLE dbo.dim_damage;
IF OBJECT_ID('dbo.dim_vehicle',             'U') IS NOT NULL DROP TABLE dbo.dim_vehicle;
IF OBJECT_ID('dbo.dim_person',              'U') IS NOT NULL DROP TABLE dbo.dim_person;
IF OBJECT_ID('dbo.dim_contributing_factor', 'U') IS NOT NULL DROP TABLE dbo.dim_contributing_factor;
IF OBJECT_ID('dbo.dim_location',            'U') IS NOT NULL DROP TABLE dbo.dim_location;
IF OBJECT_ID('dbo.dim_collision',           'U') IS NOT NULL DROP TABLE dbo.dim_collision;
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

-- ## Step 4 — Create dim_collision (conformed dimension)

-- CELL ********************

CREATE TABLE dbo.dim_collision (
    collision_key   BIGINT  NOT NULL IDENTITY,
    collision_id    INT     NOT NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 5 — Create dim_location

-- CELL ********************

CREATE TABLE dbo.dim_location (
    location_key    BIGINT       NOT NULL IDENTITY,
    borough         VARCHAR(50)  NULL,
    zip_code        VARCHAR(10)  NULL,
    latitude        FLOAT        NULL,
    longitude       FLOAT        NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 6 — Create dim_contributing_factor

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

-- ## Step 7 — Create dim_person
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

-- ## Step 8 — Create dim_vehicle
-- > pre_crash and point_of_impact removed — those belong exclusively to dim_damage
-- > 2026-06-10: vehicle_make VARCHAR(60), vehicle_occupants VARCHAR(15) — profiled from source
-- > 2026-06-12: vehicle_occupants removed — relocated to fact_crash_vehicle as numeric measure

-- CELL ********************

CREATE TABLE dbo.dim_vehicle (
    vehicle_key                  BIGINT       NOT NULL IDENTITY,
    vehicle_type                 VARCHAR(100) NULL,
    vehicle_make                 VARCHAR(60)  NULL,
    vehicle_model                VARCHAR(50)  NULL,
    vehicle_year                 SMALLINT     NULL,
    state_registration           VARCHAR(10)  NULL,
    travel_direction             VARCHAR(20)  NULL,
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

-- ## Step 9 — Create dim_damage (junk dimension)
-- > Junk dimension collapsing low-cardinality vehicle-event damage descriptors
-- > Profiled distinct combinations: 4,523 across 4.4M vehicle rows
-- > pre_crash and point_of_impact exclusively here — removed from dim_vehicle

-- CELL ********************

CREATE TABLE dbo.dim_damage (
    damage_key       BIGINT        NOT NULL IDENTITY,
    pre_crash        VARCHAR(100)  NULL,
    point_of_impact  VARCHAR(100)  NULL,
    vehicle_damage   VARCHAR(100)  NULL
);

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- MARKDOWN ********************

-- ## Step 10 — Create dim_factor_group
-- > 2026-06-12: Kimball factor-group bridge pattern (Fig. 14-4 analog)
-- > One row per collision — restores conventional many-to-one joins on both
-- > fact_crashes (factor_group_key FK) and bridge_crash_factor (factor_group_key FK)
-- > collision_key: 1:1 correlation to dim_collision — used by ETL to resolve factor_group_key,
-- > not a descriptive attribute (Kimball diagram shows this as ETL plumbing, omitted from the figure)

-- CELL ********************

CREATE TABLE dbo.dim_factor_group (
    factor_group_key  BIGINT  NOT NULL IDENTITY,
    collision_key     BIGINT  NOT NULL
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
