CREATE PROCEDURE etl.usp_load_dim_driver
AS
BEGIN
    SET NOCOUNT ON;

    -- Driver attributes, split out of dim_vehicle (ADR-0005, D6).
    INSERT INTO dbo.dim_driver
    (
        driver_sex,
        driver_license_status,
        driver_license_jurisdiction
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.driver_sex),                  '') AS driver_sex,
        NULLIF(TRIM(src.driver_license_status),       '') AS driver_license_status,
        NULLIF(TRIM(src.driver_license_jurisdiction), '') AS driver_license_jurisdiction
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_driver tgt
        WHERE  ISNULL(tgt.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.driver_sex),                  ''), '')
          AND  ISNULL(tgt.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.driver_license_status),       ''), '')
          AND  ISNULL(tgt.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.driver_license_jurisdiction), ''), '')
    );

END;

GO