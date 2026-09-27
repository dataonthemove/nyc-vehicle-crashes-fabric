CREATE PROCEDURE etl.usp_load_dim_location
AS
BEGIN
    SET NOCOUNT ON;

    -- Unknown member (ADR-0005, D15): IDENTITY cannot take an explicit key, so the row is
    -- identified by its sentinel attributes and fact loads resolve its key by lookup.
    IF NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_location
        WHERE  borough = 'UNKNOWN' AND zip_code = 'UNKNOWN'
    )
        INSERT INTO dbo.dim_location (borough, zip_code)
        VALUES ('UNKNOWN', 'UNKNOWN');

    -- Crashes with neither borough nor ZIP get no row of their own: they resolve to Unknown.
    INSERT INTO dbo.dim_location
    (
        borough,
        zip_code
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.borough),  '') AS borough,
        NULLIF(TRIM(src.zip_code), '') AS zip_code
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src
    WHERE (NULLIF(TRIM(src.borough), '') IS NOT NULL OR NULLIF(TRIM(src.zip_code), '') IS NOT NULL)
      AND NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_location tgt
        WHERE  ISNULL(tgt.borough,  '') = ISNULL(NULLIF(TRIM(src.borough),  ''), '')
          AND  ISNULL(tgt.zip_code, '') = ISNULL(NULLIF(TRIM(src.zip_code), ''), '')
    );

END;

GO