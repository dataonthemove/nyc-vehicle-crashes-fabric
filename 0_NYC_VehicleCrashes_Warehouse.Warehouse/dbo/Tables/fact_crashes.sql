CREATE TABLE [dbo].[fact_crashes] (

	[crash_id] bigint IDENTITY NOT NULL, 
	[date_key] int NOT NULL, 
	[collision_key] bigint NOT NULL, 
	[location_key] bigint NOT NULL, 
	[factor_group_key] bigint NOT NULL, 
	[persons_injured] int NULL, 
	[persons_killed] int NULL, 
	[pedestrians_injured] int NULL, 
	[pedestrians_killed] int NULL, 
	[cyclists_injured] int NULL, 
	[cyclists_killed] int NULL, 
	[motorists_injured] int NULL, 
	[motorists_killed] int NULL
);