CREATE TABLE [dbo].[fact_crash_vehicle] (
    [fact_crash_vehicle_id]    BIGINT IDENTITY NOT NULL,
    [date_key]                 INT    NOT NULL,
    [collision_id]             INT    NOT NULL,
    [location_key]             BIGINT NOT NULL,
    [factor_group_key]         BIGINT NOT NULL,
    [vehicle_key]              BIGINT NOT NULL,
    [vehicle_circumstance_key] BIGINT NOT NULL,
    [driver_key]               BIGINT NOT NULL,
    [vehicle_occupants]        INT    NULL
);


GO