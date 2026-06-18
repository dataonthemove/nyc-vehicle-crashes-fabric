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

-- CELL ********************

-- Create etl_watermark control table 
IF OBJECT_ID('dbo.etl_watermark', 'U') IS NOT NULL drop table [dbo].[etl_watermark] 


BEGIN
    CREATE TABLE dbo.etl_watermark
    (
        source_name       VARCHAR(100),
        last_loaded_value DATETIME2(6),
        last_run_utc      DATETIME2(6)
    )
END

-- Seed initial watermark values with floor date for full historical load
INSERT INTO dbo.etl_watermark (source_name, last_loaded_value, last_run_utc)
SELECT 'crashes', '1900-01-01T00:00:00', SYSUTCDATETIME()
WHERE NOT EXISTS (SELECT 1 FROM dbo.etl_watermark WHERE source_name = 'crashes');

INSERT INTO dbo.etl_watermark (source_name, last_loaded_value, last_run_utc)
SELECT 'persons', '1900-01-01T00:00:00', SYSUTCDATETIME()
WHERE NOT EXISTS (SELECT 1 FROM dbo.etl_watermark WHERE source_name = 'persons');

INSERT INTO dbo.etl_watermark (source_name, last_loaded_value, last_run_utc)
SELECT 'vehicles', '1900-01-01T00:00:00', SYSUTCDATETIME()
WHERE NOT EXISTS (SELECT 1 FROM dbo.etl_watermark WHERE source_name = 'vehicles');


-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Verify

SELECT TOP (1000) 
       [source_name]                      
      ,[last_loaded_value]
      ,[last_run_utc]
FROM [dbo].[etl_watermark] 

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
