CREATE TABLE [dbo].[fact_crash_vehicle] (
    [fact_crash_vehicle_id] BIGINT IDENTITY NOT NULL,
    [date_key]              INT    NOT NULL,
    [collision_key]         BIGINT NOT NULL,
    [vehicle_key]           BIGINT NOT NULL,
    [damage_key]            BIGINT NOT NULL,
    [vehicle_occupants]     INT    NULL
);


GO