CREATE PROCEDURE etl.usp_load_dim_date
    @start_date DATE = '2012-01-01',
    @end_date   DATE = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.dim_date;

    DECLARE @current_date DATE = @start_date;

    WHILE @current_date <= @end_date
    BEGIN
        INSERT INTO dbo.dim_date
        (
            date_key,
            full_date,
            year,
            quarter,
            month,
            month_name,
            day,
            day_of_week,
            day_name,
            is_weekend
        )
        VALUES
        (
            CAST(FORMAT(@current_date, 'yyyyMMdd') AS INT),
            @current_date,
            YEAR(@current_date),
            DATEPART(QUARTER, @current_date),
            MONTH(@current_date),
            DATENAME(MONTH, @current_date),
            DAY(@current_date),
            DATEPART(WEEKDAY, @current_date),
            DATENAME(WEEKDAY, @current_date),
            CASE WHEN DATEPART(WEEKDAY, @current_date) IN (1,7) THEN 1 ELSE 0 END
        );

        SET @current_date = DATEADD(DAY, 1, @current_date);
    END;

END;