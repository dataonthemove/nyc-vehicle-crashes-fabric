CREATE TABLE [dbo].[bridge_crash_factor] (
    [bridge_id]        BIGINT IDENTITY NOT NULL,
    [factor_group_key] BIGINT NOT NULL,
    [factor_key]       BIGINT NOT NULL
);


GO