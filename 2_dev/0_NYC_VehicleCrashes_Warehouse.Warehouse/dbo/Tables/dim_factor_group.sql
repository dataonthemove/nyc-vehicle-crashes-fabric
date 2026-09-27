CREATE TABLE [dbo].[dim_factor_group] (
    [factor_group_key] BIGINT       IDENTITY NOT NULL,
    [factor_set_hash]  VARCHAR (64) NOT NULL
);


GO