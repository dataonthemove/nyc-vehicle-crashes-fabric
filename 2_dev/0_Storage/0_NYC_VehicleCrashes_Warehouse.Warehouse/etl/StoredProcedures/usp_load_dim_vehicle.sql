CREATE PROCEDURE etl.usp_load_dim_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    -- Vehicle only: driver attributes live in dim_driver, travel_direction in
    -- dim_vehicle_circumstance, vehicle_model is dropped (ADR-0005, D6/D7/D9).
    INSERT INTO dbo.dim_vehicle
    (
        vehicle_type,
        vehicle_make,
        vehicle_year,
        state_registration
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.vehicle_type),       '') AS vehicle_type,
        NULLIF(TRIM(src.vehicle_make),       '') AS vehicle_make,
        -- Model year cleansing: NULL unless 1900 to the source row's crash year + 1.
        -- Identical in usp_load_dim_vehicle and usp_load_fact_crash_vehicle (vehicle_key lookup).
        CASE WHEN TRY_CAST(src.vehicle_year AS SMALLINT)
                  BETWEEN 1900 AND YEAR(TRY_CAST(src.crash_date AS DATE)) + 1
             THEN TRY_CAST(src.vehicle_year AS SMALLINT) END  AS vehicle_year,
        NULLIF(TRIM(src.state_registration), '') AS state_registration
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_vehicle tgt
        WHERE  ISNULL(tgt.vehicle_type,       '') = ISNULL(NULLIF(TRIM(src.vehicle_type),       ''), '')
          AND  ISNULL(tgt.vehicle_make,       '') = ISNULL(NULLIF(TRIM(src.vehicle_make),       ''), '')
          AND  ISNULL(tgt.vehicle_year,       -1) = ISNULL(CASE WHEN TRY_CAST(src.vehicle_year AS SMALLINT)
                                                        BETWEEN 1900 AND YEAR(TRY_CAST(src.crash_date AS DATE)) + 1
                                                   THEN TRY_CAST(src.vehicle_year AS SMALLINT) END, -1)
          AND  ISNULL(tgt.state_registration, '') = ISNULL(NULLIF(TRIM(src.state_registration), ''), '')
    );

END;

GO