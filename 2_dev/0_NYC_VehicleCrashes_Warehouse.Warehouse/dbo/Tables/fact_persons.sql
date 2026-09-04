CREATE TABLE [dbo].[fact_persons] (
    [fact_person_id] BIGINT IDENTITY NOT NULL,
    [date_key]       INT    NOT NULL,
    [collision_key]  BIGINT NOT NULL,
    [person_key]     BIGINT NOT NULL,
    [person_age]     INT    NULL,
    [is_injured]     BIT    NOT NULL,
    [is_killed]      BIT    NOT NULL
);


GO