CREATE TABLE [dbo].[dim_vehicle] (
    [vehicle_key]        BIGINT        IDENTITY NOT NULL,
    [vehicle_type]       VARCHAR (100) NULL,
    [vehicle_make]       VARCHAR (60)  NULL,
    [vehicle_year]       SMALLINT      NULL,
    [state_registration] VARCHAR (10)  NULL
);


GO