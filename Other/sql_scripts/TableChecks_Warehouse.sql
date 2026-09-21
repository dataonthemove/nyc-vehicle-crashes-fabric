
USE NYC_VehicleCrashes_Warehouse  -- The same warehouse name for all workspaces. 

/*
select count(*) FROM [dbo].[fact_crashes]       -- 2,269,187 -- 2269187 (after new workspace restructuring)
select count(*) FROM [dbo].[fact_persons]       -- 5,984,110 -- 5984110 (after new workspace restructuring)
select count(*) FROM [dbo].[fact_crash_vehicle] -- 4,551,002 -- 4551002 (after new workspace restructuring)
*/

select top 10 * FROM [dbo].[fact_crashes]
select top 10 * FROM [dbo].[fact_persons]
select top 10 * FROM [dbo].[fact_crash_vehicle]
