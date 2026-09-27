CREATE TABLE [dbo].[dim_vehicle_circumstance] (
    [vehicle_circumstance_key] BIGINT        IDENTITY NOT NULL,
    [pre_crash]                VARCHAR (100) NULL,
    [travel_direction]         VARCHAR (20)  NULL,
    [point_of_impact]          VARCHAR (100) NULL,
    [vehicle_damage]           VARCHAR (100) NULL
);


GO