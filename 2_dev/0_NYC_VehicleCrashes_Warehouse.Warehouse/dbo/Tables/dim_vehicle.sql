CREATE TABLE [dbo].[dim_vehicle] (
    [vehicle_key]                 BIGINT        IDENTITY NOT NULL,
    [vehicle_type]                VARCHAR (100) NULL,
    [vehicle_make]                VARCHAR (60)  NULL,
    [vehicle_model]               VARCHAR (50)  NULL,
    [vehicle_year]                SMALLINT      NULL,
    [state_registration]          VARCHAR (10)  NULL,
    [travel_direction]            VARCHAR (20)  NULL,
    [driver_sex]                  VARCHAR (10)  NULL,
    [driver_license_status]       VARCHAR (50)  NULL,
    [driver_license_jurisdiction] VARCHAR (50)  NULL
);


GO