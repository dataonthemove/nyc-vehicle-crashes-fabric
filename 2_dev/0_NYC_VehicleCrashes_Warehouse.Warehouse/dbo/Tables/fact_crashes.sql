CREATE TABLE [dbo].[fact_crashes] (
    [crash_id]            BIGINT IDENTITY NOT NULL,
    [date_key]            INT    NOT NULL,
    [collision_id]        INT    NOT NULL,
    [location_key]        BIGINT NOT NULL,
    [factor_group_key]    BIGINT NOT NULL,
    [latitude]            FLOAT (53) NULL,
    [longitude]           FLOAT (53) NULL,
    [persons_injured]     INT    NULL,
    [persons_killed]      INT    NULL,
    [pedestrians_injured] INT    NULL,
    [pedestrians_killed]  INT    NULL,
    [cyclists_injured]    INT    NULL,
    [cyclists_killed]     INT    NULL,
    [motorists_injured]   INT    NULL,
    [motorists_killed]    INT    NULL
);


GO