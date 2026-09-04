CREATE TABLE [dbo].[dim_location] (
    [location_key] BIGINT       IDENTITY NOT NULL,
    [borough]      VARCHAR (50) NULL,
    [zip_code]     VARCHAR (10) NULL,
    [latitude]     FLOAT (53)   NULL,
    [longitude]    FLOAT (53)   NULL
);


GO