CREATE TABLE [dbo].[dim_person] (

	[person_key] bigint IDENTITY NOT NULL, 
	[person_type] varchar(50) NULL, 
	[person_sex] varchar(10) NULL, 
	[ejection] varchar(50) NULL, 
	[emotional_status] varchar(50) NULL, 
	[bodily_injury] varchar(100) NULL, 
	[position_in_vehicle] varchar(50) NULL, 
	[safety_equipment] varchar(100) NULL, 
	[ped_location] varchar(100) NULL, 
	[ped_action] varchar(100) NULL, 
	[ped_role] varchar(50) NULL
);