CREATE TABLE [dbo].[fact_persons] (

	[fact_person_id] bigint IDENTITY NOT NULL, 
	[collision_key] bigint NOT NULL, 
	[person_key] bigint NOT NULL, 
	[person_age] int NULL, 
	[is_injured] bit NOT NULL, 
	[is_killed] bit NOT NULL
);