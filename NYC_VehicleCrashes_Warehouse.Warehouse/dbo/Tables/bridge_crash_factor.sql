CREATE TABLE [dbo].[bridge_crash_factor] (

	[bridge_id] bigint IDENTITY NOT NULL, 
	[collision_key] bigint NOT NULL, 
	[factor_key] bigint NOT NULL
);