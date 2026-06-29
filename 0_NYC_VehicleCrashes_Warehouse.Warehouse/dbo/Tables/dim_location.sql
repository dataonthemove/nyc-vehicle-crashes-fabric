CREATE TABLE [dbo].[dim_location] (

	[location_key] bigint IDENTITY NOT NULL, 
	[borough] varchar(50) NULL, 
	[zip_code] varchar(10) NULL, 
	[latitude] float NULL, 
	[longitude] float NULL
);