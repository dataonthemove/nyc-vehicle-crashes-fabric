CREATE TABLE [dbo].[dim_date] (
    [date_key]    INT          NOT NULL,
    [full_date]   DATE         NOT NULL,
    [year]        SMALLINT     NOT NULL,
    [quarter]     SMALLINT     NOT NULL,
    [month]       SMALLINT     NOT NULL,
    [month_name]  VARCHAR (10) NOT NULL,
    [day]         SMALLINT     NOT NULL,
    [day_of_week] SMALLINT     NOT NULL,
    [day_name]    VARCHAR (10) NOT NULL,
    [is_weekend]  BIT          NOT NULL
);


GO