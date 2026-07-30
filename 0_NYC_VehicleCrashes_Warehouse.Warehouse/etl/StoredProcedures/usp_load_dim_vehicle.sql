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
        NULLIF(TRIM(src.VEHICLE_TYPE),                 '') AS vehicle_type,
        NULLIF(TRIM(src.VEHICLE_MAKE),                 '') AS vehicle_make,
        NULLIF(TRIM(src.VEHICLE_MODEL),                '') AS vehicle_model,
        TRY_CAST(src.VEHICLE_YEAR AS SMALLINT)            AS vehicle_year,
        NULLIF(TRIM(src.STATE_REGISTRATION),           '') AS state_registration,
        NULLIF(TRIM(src.TRAVEL_DIRECTION),             '') AS travel_direction,
        NULLIF(TRIM(src.DRIVER_SEX),                   '') AS driver_sex,
        NULLIF(TRIM(src.DRIVER_LICENSE_STATUS),        '') AS driver_license_status,
        NULLIF(TRIM(src.DRIVER_LICENSE_JURISDICTION),  '') AS driver_license_jurisdiction
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle tgt
        WHERE  ISNULL(tgt.vehicle_type,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_TYPE),               ''), '')
          AND  ISNULL(tgt.vehicle_make,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MAKE),               ''), '')
          AND  ISNULL(tgt.vehicle_model,               '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MODEL),              ''), '')
          AND  ISNULL(tgt.vehicle_year,                -1) = ISNULL(TRY_CAST(src.VEHICLE_YEAR AS SMALLINT),      -1)
          AND  ISNULL(tgt.state_registration,          '') = ISNULL(NULLIF(TRIM(src.STATE_REGISTRATION),        ''), '')
          AND  ISNULL(tgt.travel_direction,            '') = ISNULL(NULLIF(TRIM(src.TRAVEL_DIRECTION),          ''), '')
          AND  ISNULL(tgt.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.DRIVER_SEX),                ''), '')
          AND  ISNULL(tgt.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_STATUS),     ''), '')
          AND  ISNULL(tgt.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_JURISDICTION),''), '')
    );

END;

GO