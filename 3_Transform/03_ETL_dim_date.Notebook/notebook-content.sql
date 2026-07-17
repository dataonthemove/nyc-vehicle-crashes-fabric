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
-- **Date range:** 2012-01-01 → 2026-12-31
-- 
-- **Instructions:**
-- 1. Connect this notebook to the `NYC_VehicleCrashes_Warehouse` data source.
-- 2. Run Cell 1 to create the procedure (DROP/CREATE pattern).
-- 3. Run Cell 2 to execute and populate `dim_date`.
-- 4. In production, invoke via Pipeline Script activity.
-- 
-- **Note:** sys.all_objects cross join unsupported in Fabric Warehouse distributed mode.
-- WHILE loop used instead.

-- CELL ********************

-- Cell 1: DROP and CREATE stored procedure
IF OBJECT_ID('etl.usp_load_dim_date', 'P') IS NOT NULL
    DROP PROCEDURE etl.usp_load_dim_date;
GO

CREATE PROCEDURE etl.usp_load_dim_date
    @start_date DATE = '2012-01-01',
    @end_date   DATE = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.dim_date;

    DECLARE @current_date DATE = @start_date;

    WHILE @current_date <= @end_date
    BEGIN
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
        VALUES
        (
            CAST(FORMAT(@current_date, 'yyyyMMdd') AS INT),
            @current_date,
            YEAR(@current_date),
            DATEPART(QUARTER, @current_date),
            MONTH(@current_date),
            DATENAME(MONTH, @current_date),
            DAY(@current_date),
            DATEPART(WEEKDAY, @current_date),
            DATENAME(WEEKDAY, @current_date),
            CASE WHEN DATEPART(WEEKDAY, @current_date) IN (1,7) THEN 1 ELSE 0 END
        );

        SET @current_date = DATEADD(DAY, 1, @current_date);
    END;

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
    @end_date   = '2026-12-31';

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
