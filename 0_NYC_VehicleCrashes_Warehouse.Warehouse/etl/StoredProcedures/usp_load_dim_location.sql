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
        NULLIF(TRIM(src.BOROUGH),    '')  AS borough,
        NULLIF(TRIM(src.ZIP_CODE),   '')  AS zip_code,
        TRY_CAST(src.LATITUDE  AS FLOAT) AS latitude,
        TRY_CAST(src.LONGITUDE AS FLOAT) AS longitude
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_location tgt
        WHERE  ISNULL(tgt.borough,   '')  = ISNULL(NULLIF(TRIM(src.BOROUGH),   ''), '')
          AND  ISNULL(tgt.zip_code,  '')  = ISNULL(NULLIF(TRIM(src.ZIP_CODE),  ''), '')
          AND  ISNULL(tgt.latitude,  -999) = ISNULL(TRY_CAST(src.LATITUDE  AS FLOAT), -999)
          AND  ISNULL(tgt.longitude, -999) = ISNULL(TRY_CAST(src.LONGITUDE AS FLOAT), -999)
    );

END;

GO