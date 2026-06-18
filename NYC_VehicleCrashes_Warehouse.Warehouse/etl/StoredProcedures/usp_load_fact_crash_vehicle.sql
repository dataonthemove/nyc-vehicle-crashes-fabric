CREATE PROCEDURE etl.usp_load_fact_crash_vehicle
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.fact_crash_vehicle
    (
        collision_key,
        vehicle_key,
        damage_key,
        vehicle_occupants
    )
    SELECT
        dc.collision_key,
        dv.vehicle_key,
        dd.damage_key,
        TRY_CAST(src.VEHICLE_OCCUPANTS AS INT) AS vehicle_occupants
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles src

    -- Resolve collision_key
    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(src.COLLISION_ID AS INT)

    -- Resolve vehicle_key
    INNER JOIN dbo.dim_vehicle dv
        ON  ISNULL(dv.vehicle_type,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_TYPE),                ''), '')
        AND ISNULL(dv.vehicle_make,                '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MAKE),                ''), '')
        AND ISNULL(dv.vehicle_model,               '') = ISNULL(NULLIF(TRIM(src.VEHICLE_MODEL),               ''), '')
        AND ISNULL(dv.vehicle_year,                -1) = ISNULL(TRY_CAST(src.VEHICLE_YEAR AS SMALLINT),       -1)
        AND ISNULL(dv.state_registration,          '') = ISNULL(NULLIF(TRIM(src.STATE_REGISTRATION),         ''), '')
        AND ISNULL(dv.travel_direction,            '') = ISNULL(NULLIF(TRIM(src.TRAVEL_DIRECTION),           ''), '')
        AND ISNULL(dv.driver_sex,                  '') = ISNULL(NULLIF(TRIM(src.DRIVER_SEX),                 ''), '')
        AND ISNULL(dv.driver_license_status,       '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_STATUS),      ''), '')
        AND ISNULL(dv.driver_license_jurisdiction, '') = ISNULL(NULLIF(TRIM(src.DRIVER_LICENSE_JURISDICTION),''), '')

    -- Resolve damage_key
    INNER JOIN dbo.dim_damage dd
        ON  ISNULL(dd.pre_crash,       '') = ISNULL(NULLIF(TRIM(src.PRE_CRASH),       ''), '')
        AND ISNULL(dd.point_of_impact, '') = ISNULL(NULLIF(TRIM(src.POINT_OF_IMPACT), ''), '')
        AND ISNULL(dd.vehicle_damage,  '') = ISNULL(NULLIF(TRIM(src.VEHICLE_DAMAGE),  ''), '')

    -- Incremental: skip collision_keys already loaded
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.fact_crash_vehicle tgt
        WHERE  tgt.collision_key = dc.collision_key
    )
    AND TRY_CAST(src.COLLISION_ID AS INT) IS NOT NULL;

END;