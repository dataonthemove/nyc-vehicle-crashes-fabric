CREATE TABLE [dbo].[dim_date] (

	[date_key] int NOT NULL, 
	[full_date] date NOT NULL, 
	[year] smallint NOT NULL, 
	[quarter] smallint NOT NULL, 
	[month] smallint NOT NULL, 
	[month_name] varchar(10) NOT NULL, 
	[day] smallint NOT NULL, 
	[day_of_week] smallint NOT NULL, 
	[day_name] varchar(10) NOT NULL, 
	[is_weekend] bit NOT NULL
);