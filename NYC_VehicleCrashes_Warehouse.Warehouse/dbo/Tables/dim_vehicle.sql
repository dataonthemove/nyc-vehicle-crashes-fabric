CREATE TABLE [dbo].[dim_vehicle] (

	[vehicle_key] bigint IDENTITY NOT NULL, 
	[vehicle_type] varchar(100) NULL, 
	[vehicle_make] varchar(50) NULL, 
	[vehicle_model] varchar(50) NULL, 
	[vehicle_year] smallint NULL, 
	[state_registration] varchar(10) NULL, 
	[travel_direction] varchar(20) NULL, 
	[vehicle_occupants] varchar(10) NULL, 
	[driver_sex] varchar(10) NULL, 
	[driver_license_status] varchar(50) NULL, 
	[driver_license_jurisdiction] varchar(50) NULL
);