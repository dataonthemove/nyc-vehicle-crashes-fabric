CREATE TABLE [dbo].[etl_watermark] (
    [source_name]       VARCHAR (100) NULL,
    [last_loaded_value] DATETIME2 (6) NULL,
    [last_run_utc]      DATETIME2 (6) NULL
);


GO