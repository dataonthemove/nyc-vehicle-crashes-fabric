CREATE PROCEDURE etl.usp_load_dim_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_vehicle
    (
        vehicle_type,
        vehicle_make,
        vehicle_model,
        vehicle_year,
        state_registration,
        travel_direction,
        driver_sex,
        driver_license_status,
        driver_license_jurisdiction
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.vehicle_type),                 '') AS vehicle_type,
        NULLIF(TRIM(src.vehicle_make),                 '') AS vehicle_make,
        NULLIF(TRIM(src.vehicle_model),                '') AS vehicle_model,
        TRY_CAST(src.vehicle_year AS SMALLINT)            AS vehicle_year,
        NULLIF(TRIM(src.state_registration),           '') AS state_registration,
        NULLIF(TRIM(src.travel_direction),             '') AS travel_direction,
        NULLIF(TRIM(src.driver_sex),                   '') AS driver_sex,
        NULLIF(TRIM(src.driver_license_status),        '') AS driver_license_status,
        NULLIF(TRIM(src.driver_license_jurisdiction),  '') AS driver_license_jurisdiction
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle tgt
        WHERE  ISNULL(tgt.vehicle_type,                '') = ISNULL(NULLIF(TRIM(src.vehicle_type),               ''), '')
          AND  ISNULL(tgt.vehicle_make,                '') = ISNULL(NULLIF(TRIM(src.vehicle_make),               ''), '')
          AND  ISNULL(tgt.vehicle_model,               '') = ISNULL(NULLIF(TRIM(src.vehicle_model),              ''), '')
          AND  ISNULL(tgt.vehicle_year,                -1) = ISNULL(TRY_CAST(src.vehicle_year AS SMALLINT),      -1)
          AND  ISNULL(tgt.state_registration,          '') = ISNULL(NULLIF(TRIM(src.state_registration),        ''), '')
          AND  ISNULL(tgt.travel_direction,            '') = ISNULL(NULLIF(TRIM(src.travel_direction),          ''), '')
          AND  ISNULL(tgt.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.driver_sex),                ''), '')
          AND  ISNULL(tgt.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.driver_license_status),     ''), '')
          AND  ISNULL(tgt.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.driver_license_jurisdiction),''), '')
    );

END;

GO