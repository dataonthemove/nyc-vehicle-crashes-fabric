CREATE PROCEDURE etl.usp_load_dim_date
    @start_date DATE = '2012-01-01',
    @end_date   DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.dim_date;

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
    SELECT
        (YEAR(full_date) * 10000) + (MONTH(full_date) * 100) + DAY(full_date),
        full_date,
        YEAR(full_date),
        DATEPART(QUARTER, full_date),
        MONTH(full_date),
        DATENAME(MONTH, full_date),
        DAY(full_date),
        DATEPART(WEEKDAY, full_date),
        DATENAME(WEEKDAY, full_date),
        CASE WHEN DATEPART(WEEKDAY, full_date) IN (1,7) THEN 1 ELSE 0 END
    FROM
    (
        -- Digit tally -> 10,000 day offsets (covers ~27 years), trimmed by DATEDIFF.
        SELECT DATEADD(DAY, (d3.d * 1000) + (d2.d * 100) + (d1.d * 10) + d0.d, @start_date) AS full_date
        FROM       (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d0 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d1 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d2 (d)
        CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d3 (d)
        WHERE (d3.d * 1000) + (d2.d * 100) + (d1.d * 10) + d0.d
              <= DATEDIFF(DAY, @start_date, @end_date)
    ) calendar;

END;

GO