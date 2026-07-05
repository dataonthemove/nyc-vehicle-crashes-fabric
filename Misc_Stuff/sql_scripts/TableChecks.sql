
use NYC_VehicleCrashes_lakehouse
/*
select count(*) FROM [dbo].[nyc_crashes]
select count(*) FROM [dbo].[nyc_ersons]
select count(*) FROM [dbo].[nyc_vehicles]
*/
SELECT TOP (10) *  FROM [dbo].[nyc_crashes]
SELECT TOP (10) *  FROM [dbo].[nyc_persons]
SELECT TOP (10) *  FROM [dbo].[nyc_vehicles]


USE NYC_VehicleCrashes_Warehouse
/*
select count(*) FROM [dbo].[fact_crashes]
select count(*) FROM [dbo].[fact_persons]
select count(*) FROM [dbo].[fact_crash_vehicle]
*/
select top 10 * FROM [dbo].[fact_crashes]
select top 10 * FROM [dbo].[fact_persons]
select top 10 * FROM [dbo].[fact_crash_vehicle]
