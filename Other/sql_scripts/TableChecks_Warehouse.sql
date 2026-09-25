
USE NYC_VehicleCrashes_Landing_Lakehouse  -- Only in 1_NYC_VehicleCrashes_Landing workspace.
/*
select top 10 * FROM [dbo].[etl_watermark]

source_name	    last_loaded_value	        last_run_utc
vehicles	    2026-09-10 13:06:06.000000  2026-09-10 13:06:33.811315
persons	        2026-09-10 13:05:12.000000	2026-09-10 13:05:37.119364
crashes	        2026-09-10 13:04:16.000000	2026-09-10 13:04:42.437451
*/

USE NYC_VehicleCrashes_Lakehouse  -- The same Lakehouse name for all workspaces. 
/*
select count(*) FROM [dbo].[nyc_crashes]      -- 2,269,187 
select count(*) FROM [dbo].[nyc_persons]      -- 5,984,110 
select count(*) FROM [dbo].[nyc_vehicles]     -- 4,551,002 
*/


USE NYC_VehicleCrashes_Warehouse  -- The same warehouse name for all workspaces. 
/*
select count(*) FROM [dbo].[fact_crashes]           -- 2,269,187 
select count(*) FROM [dbo].[fact_persons]           -- 5,984,110 
select count(*) FROM [dbo].[fact_crash_vehicle]     -- 4,551,002 
select count(*) FROM [dbo].[bridge_crash_factor]    -- 1,648,599

select count(*) FROM [dbo].[dim_collision]              -- 2269187         
select count(*) FROM [dbo].[dim_contributing_factor]    -- 66
select count(*) FROM [dbo].[dim_damage]                 -- 4602
select count(*) FROM [dbo].[dim_date]                   -- 6940
select count(*) FROM [dbo].[dim_factor_group]           -- 2269187
select count(*) FROM [dbo].[dim_location]               -- 381068
select count(*) FROM [dbo].[dim_person]                 -- 25990     
select count(*) FROM [dbo].[dim_vehicle]                -- 596157
*/
select top 10 * FROM [dbo].[fact_crashes]
select top 10 * FROM [dbo].[fact_persons]
select top 10 * FROM [dbo].[fact_crash_vehicle]
select top 10 * FROM [dbo].[bridge_crash_factor]  

select top 10 * FROM [dbo].[dim_collision]
select top 10 * FROM [dbo].[dim_contributing_factor]
select top 10 * FROM [dbo].[dim_damage]
select top 10 * FROM [dbo].[dim_date]
select top 10 * FROM [dbo].[dim_factor_group]
select top 10 * FROM [dbo].[dim_location]
select top 10 * FROM [dbo].[dim_person]
select top 10 * FROM [dbo].[dim_vehicle]
