CREATE TABLE [dbo].[dim_driver] (
    [driver_key]                  BIGINT       IDENTITY NOT NULL,
    [driver_sex]                  VARCHAR (10) NULL,
    [driver_license_status]       VARCHAR (50) NULL,
    [driver_license_jurisdiction] VARCHAR (50) NULL
);


GO