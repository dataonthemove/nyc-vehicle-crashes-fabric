
/*
USE NYC_VehicleCrashes_Landing_Lakehouse  -- Only in 1_NYC_VehicleCrashes_Landing workspace.
select top 10 * FROM [dbo].[etl_watermark]
*/


USE NYC_VehicleCrashes_Lakehouse  -- The same Lakehouse name for all workspaces. 
/*
select count(*) FROM [dbo].[nyc_crashes]      -- 2,269,187 -- 2269187 (after new workspace restructuring)
select count(*) FROM [dbo].[nyc_persons]      -- 5,984,110 -- 5984110 (after new workspace restructuring)
select count(*) FROM [dbo].[nyc_vehicles]     -- 4,551,002 -- 4551002 (after new workspace restructuring)
*/
select top 10 * FROM [dbo].[nyc_crashes]
select top 10 * FROM [dbo].[nyc_persons]
select top 10 * FROM [dbo].[nyc_vehicles]


USE NYC_VehicleCrashes_Warehouse  -- The same warehouse name for all workspaces. 
/*
select count(*) FROM [dbo].[fact_crashes]           -- 2,269,187 -- 2269187 (after new workspace restructuring)
select count(*) FROM [dbo].[fact_persons]           -- 5,984,110 -- 5984110 (after new workspace restructuring)
select count(*) FROM [dbo].[fact_crash_vehicle]     -- 4,551,002 -- 4551002 (after new workspace restructuring)
select count(*) FROM [dbo].[bridge_crash_factor]    -- 1,648,599

select count(*) FROM [dbo].[dim_collision]
select count(*) FROM [dbo].[dim_contributing_factor]
select count(*) FROM [dbo].[dim_damage]
select count(*) FROM [dbo].[dim_date]
select count(*) FROM [dbo].[dim_factor_group]
select count(*) FROM [dbo].[dim_location]
select count(*) FROM [dbo].[dim_person]
select count(*) FROM [dbo].[dim_vehicle]
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
