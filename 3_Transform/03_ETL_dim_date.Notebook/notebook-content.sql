-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "sqldatawarehouse"
-- META   },
-- META   "dependencies": {
-- META     "lakehouse": {
-- META       "default_lakehouse_name": "",
-- META       "default_lakehouse_workspace_id": ""
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

-- # 03_ETL_dim_date
-- **Purpose:** Create stored procedure `etl.usp_load_dim_date` in NYC_VehicleCrashes_Warehouse.
-- 
-- **Date range:** 2012-01-01 → 2030-12-31 (6,940 rows)
-- 
-- **Instructions:**
-- 1. Connect this notebook to the `NYC_VehicleCrashes_Warehouse` data source.
-- 2. Run Cell 1 to create the procedure (DROP/CREATE pattern).
-- 3. Run Cell 2 to execute and populate `dim_date`.
-- 4. Run Cell 3 to verify row count, boundaries and continuity.
-- 5. In production, invoke via Pipeline Script activity.
-- 
-- **Note:** sys.all_objects cross join unsupported in Fabric Warehouse distributed mode, and
-- MAXRECURSION is not available. Row source is a VALUES-constructor digit tally cross-joined
-- to 10,000 offsets, filtered by DATEDIFF — set-based, no system tables, no recursion.
-- 
-- **Set-based rewrite (2026-08-01):** replaced a row-by-row WHILE loop that issued one INSERT
-- per day and took ~29 minutes for 5,479 rows. Same output, single INSERT. `date_key` is a
-- deterministic YYYYMMDD smart key (not IDENTITY), so TRUNCATE-and-reload regenerates identical
-- key values and existing fact rows stay joined. Range extended 2026 → 2030.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_date', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_date;
GO

CREATE PROCEDURE etl.usp_load_dim_date
    @start_date DATE = '2012-01-01',
    @end_date   DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.dim_date;

    INSERT INTO dbo.dim_date
    (
        date_key,
        full_date,
        year,
        quarter,
        month,
        month_name,
        day,
        day_of_week,
        day_name,
        is_weekend
    )
    SELECT
        (YEAR(full_date) * 10000) + (MONTH(full_date) * 100) + DAY(full_date),
        full_date,
        YEAR(full_date),
        DATEPART(QUARTER, full_date),
        MONTH(full_date),
        DATENAME(MONTH, full_date),
        DAY(full_date),
        DATEPART(WEEKDAY, full_date),
        DATENAME(WEEKDAY, full_date),
        CASE WHEN DATEPART(WEEKDAY, full_date) IN (1,7) THEN 1 ELSE 0 END
    FROM
    (
        -- Digit tally -> 10,000 day offsets (covers ~27 years), trimmed by DATEDIFF.
        SELECT DATEADD(DAY, (d3.d * 1000) + (d2.d * 100) + (d1.d * 10) + d0.d, @start_date) AS full_date
        FROM       (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d0 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d1 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d2 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d3 (d)
        WHERE (d3.d * 1000) + (d2.d * 100) + (d1.d * 10) + d0.d
              <= DATEDIFF(DAY, @start_date, @end_date)
    ) calendar;

END;
GO

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 2: Execute the procedure
EXEC etl.usp_load_dim_date
    @start_date = '2012-01-01',
    @end_date   = '2030-12-31';

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Cell 3: Verify. Expected 6,940 rows, 2012-01-01 -> 2030-12-31, no gaps, no duplicates.
SELECT
    COUNT(*)                                                  AS row_count,
    COUNT(DISTINCT date_key)                                  AS distinct_keys,
    MIN(full_date)                                            AS first_date,
    MAX(full_date)                                            AS last_date,
    DATEDIFF(DAY, MIN(full_date), MAX(full_date)) + 1         AS expected_row_count,
    SUM(CASE WHEN date_key <> (YEAR(full_date) * 10000)
                              + (MONTH(full_date) * 100)
                              + DAY(full_date) THEN 1 ELSE 0 END) AS bad_date_keys
FROM dbo.dim_date;

-- Orphan check: every date_key referenced by the facts must still resolve after the reload.
SELECT
    (SELECT COUNT(*) FROM dbo.fact_crashes f
      WHERE NOT EXISTS (SELECT 1 FROM dbo.dim_date d WHERE d.date_key = f.date_key))       AS orphan_fact_crashes,
    (SELECT COUNT(*) FROM dbo.fact_crash_vehicle f
      WHERE NOT EXISTS (SELECT 1 FROM dbo.dim_date d WHERE d.date_key = f.date_key))       AS orphan_fact_crash_vehicle,
    (SELECT COUNT(*) FROM dbo.fact_persons f
      WHERE NOT EXISTS (SELECT 1 FROM dbo.dim_date d WHERE d.date_key = f.date_key))       AS orphan_fact_persons;

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
