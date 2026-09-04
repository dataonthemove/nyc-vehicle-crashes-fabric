CREATE TABLE [dbo].[dim_damage] (
    [damage_key]      BIGINT        IDENTITY NOT NULL,
    [pre_crash]       VARCHAR (100) NULL,
    [point_of_impact] VARCHAR (100) NULL,
    [vehicle_damage]  VARCHAR (100) NULL
);


GO