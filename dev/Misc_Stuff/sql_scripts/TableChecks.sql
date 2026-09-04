
use NYC_VehicleCrashes_lakehouse
/*
select count(*) FROM [dbo].[nyc_crashes]    -- 2,269,187;  2,269,187 (After vehicle occupancy count fix)
select count(*) FROM [dbo].[nyc_persons]    -- 5,984,110;  5,984,110 (After vehicle occupancy count fix)
select count(*) FROM [dbo].[nyc_vehicles]   -- 5,984,110;  4,551,002 (After vehicle occupancy count fix)
*/
SELECT TOP (10) *  FROM [dbo].[nyc_crashes]
SELECT TOP (10) *  FROM [dbo].[nyc_persons]
SELECT TOP (10) *  FROM [dbo].[nyc_vehicles]



USE NYC_VehicleCrashes_Warehouse

SELECT TOP (1000) [source_name] ,[last_loaded_value] ,[last_run_utc]
FROM [dbo].[etl_watermark]

/*
source_name	    last_loaded_value	last_run_utc
vehicles        2026-08-02 	        2026-08-02 
persons 	    2026-08-02 	        2026-08-02 
crashes	        2026-08-02 	        2026-08-02 
*/


/*
select count(*) FROM [dbo].[fact_crashes]       -- 2,269,187
select count(*) FROM [dbo].[fact_persons]       -- 5,984,110
select count(*) FROM [dbo].[fact_crash_vehicle] -- 4,551,002
*/
select top 10 * FROM [dbo].[fact_crashes]
select top 10 * FROM [dbo].[fact_persons]
select top 10 * FROM [dbo].[fact_crash_vehicle]
