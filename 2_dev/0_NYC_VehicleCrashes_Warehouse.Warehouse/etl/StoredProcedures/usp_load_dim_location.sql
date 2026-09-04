CREATE PROCEDURE etl.usp_load_dim_location
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_location
    (
        borough,
        zip_code,
        latitude,
        longitude
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.borough),    '')  AS borough,
        NULLIF(TRIM(src.zip_code),   '')  AS zip_code,
        TRY_CAST(src.latitude  AS FLOAT) AS latitude,
        TRY_CAST(src.longitude AS FLOAT) AS longitude
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_location tgt
        WHERE  ISNULL(tgt.borough,   '')  = ISNULL(NULLIF(TRIM(src.borough),   ''), '')
          AND  ISNULL(tgt.zip_code,  '')  = ISNULL(NULLIF(TRIM(src.zip_code),  ''), '')
          AND  ISNULL(tgt.latitude,  -999) = ISNULL(TRY_CAST(src.latitude  AS FLOAT), -999)
          AND  ISNULL(tgt.longitude, -999) = ISNULL(TRY_CAST(src.longitude AS FLOAT), -999)
    );

END;

GO