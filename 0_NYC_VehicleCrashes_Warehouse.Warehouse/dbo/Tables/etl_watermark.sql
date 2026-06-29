CREATE TABLE [dbo].[etl_watermark] (

	[source_name] varchar(100) NULL, 
	[last_loaded_value] datetime2(6) NULL, 
	[last_run_utc] datetime2(6) NULL
);