CREATE TABLE [dbo].[dim_damage] (

	[damage_key] bigint IDENTITY NOT NULL, 
	[pre_crash] varchar(100) NULL, 
	[point_of_impact] varchar(100) NULL, 
	[vehicle_damage] varchar(100) NULL
);