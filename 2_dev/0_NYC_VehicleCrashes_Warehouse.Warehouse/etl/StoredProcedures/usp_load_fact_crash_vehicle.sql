CREATE PROCEDURE etl.usp_load_fact_crash_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_crash_vehicle
    (
        date_key,
        collision_id,
        location_key,
        factor_group_key,
        vehicle_key,
        damage_key,
        vehicle_occupants
    )
    SELECT
        fc.date_key,
        fc.collision_id,
        fc.location_key,
        fc.factor_group_key,
        dv.vehicle_key,
        dd.damage_key,
        CASE
            WHEN TRY_CAST(src.vehicle_occupants AS INT) > 100 THEN NULL
            ELSE TRY_CAST(src.vehicle_occupants AS INT)
        END AS vehicle_occupants
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src

    -- Header keys (date_key, location_key, factor_group_key) come from the vehicle's crash,
    -- never the vehicle row (ADR-0005). Vehicles with no loaded crash are dropped.
    INNER JOIN dbo.fact_crashes fc
        ON fc.collision_id = TRY_CAST(src.collision_id AS INT)

    -- Resolve vehicle_key
    INNER JOIN dbo.dim_vehicle dv
        ON  ISNULL(dv.vehicle_type,                '') = ISNULL(NULLIF(TRIM(src.vehicle_type),                ''), '')
        AND ISNULL(dv.vehicle_make,                '') = ISNULL(NULLIF(TRIM(src.vehicle_make),                ''), '')
        AND ISNULL(dv.vehicle_model,               '') = ISNULL(NULLIF(TRIM(src.vehicle_model),               ''), '')
        AND ISNULL(dv.vehicle_year,                -1) = ISNULL(TRY_CAST(src.vehicle_year AS SMALLINT),       -1)
        AND ISNULL(dv.state_registration,          '') = ISNULL(NULLIF(TRIM(src.state_registration),         ''), '')
        AND ISNULL(dv.travel_direction,            '') = ISNULL(NULLIF(TRIM(src.travel_direction),           ''), '')
        AND ISNULL(dv.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.driver_sex),                 ''), '')
        AND ISNULL(dv.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.driver_license_status),      ''), '')
        AND ISNULL(dv.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.driver_license_jurisdiction),''), '')

    -- Resolve damage_key
    INNER JOIN dbo.dim_damage dd
        ON  ISNULL(dd.pre_crash,       '') = ISNULL(NULLIF(TRIM(src.pre_crash),       ''), '')
        AND ISNULL(dd.point_of_impact, '') = ISNULL(NULLIF(TRIM(src.point_of_impact), ''), '')
        AND ISNULL(dd.vehicle_damage,  '') = ISNULL(NULLIF(TRIM(src.vehicle_damage),  ''), '')

    -- Incremental: skip collisions already loaded
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crash_vehicle tgt
        WHERE  tgt.collision_id = fc.collision_id
    );

END;

GO