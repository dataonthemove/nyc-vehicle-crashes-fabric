CREATE TABLE [dbo].[fact_crash_vehicle] (

	[fact_crash_vehicle_id] bigint IDENTITY NOT NULL, 
	[collision_key] bigint NOT NULL, 
	[vehicle_key] bigint NOT NULL, 
	[damage_key] bigint NOT NULL
);