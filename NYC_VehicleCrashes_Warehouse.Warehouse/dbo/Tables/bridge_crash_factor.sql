CREATE TABLE [dbo].[bridge_crash_factor] (

	[bridge_id] bigint IDENTITY NOT NULL, 
	[factor_group_key] bigint NOT NULL, 
	[factor_key] bigint NOT NULL
);