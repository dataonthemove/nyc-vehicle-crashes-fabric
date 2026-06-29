CREATE PROCEDURE etl.usp_load_dim_damage
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_damage
    (
        pre_crash,
        point_of_impact,
        vehicle_damage
    )
    SELECT DISTINCT
        NULLIF(TRIM(src.PRE_CRASH),       '') AS pre_crash,
        NULLIF(TRIM(src.POINT_OF_IMPACT), '') AS point_of_impact,
        NULLIF(TRIM(src.VEHICLE_DAMAGE),  '') AS vehicle_damage
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionsvehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_damage tgt
        WHERE  ISNULL(tgt.pre_crash,       '') = ISNULL(NULLIF(TRIM(src.PRE_CRASH),       ''), '')
          AND  ISNULL(tgt.point_of_impact, '') = ISNULL(NULLIF(TRIM(src.POINT_OF_IMPACT), ''), '')
          AND  ISNULL(tgt.vehicle_damage,  '') = ISNULL(NULLIF(TRIM(src.VEHICLE_DAMAGE),  ''), '')
    );

END;