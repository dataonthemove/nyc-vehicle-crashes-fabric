CREATE PROCEDURE etl.usp_load_bridge_crash_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot 5 contributing factor columns into collision x factor pairs
    WITH unpivoted AS
    (
        SELECT COLLISION_ID, NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes
        UNION
        SELECT COLLISION_ID, NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes
        UNION
        SELECT COLLISION_ID, NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes
        UNION
        SELECT COLLISION_ID, NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes
        UNION
        SELECT COLLISION_ID, NULLIF(TRIM(CONTRIBUTING_FACTOR_VEHICLE_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes
    )
    INSERT INTO dbo.bridge_crash_factor (collision_key, factor_key)
    SELECT
        dc.collision_key,
        df.factor_key
    FROM  unpivoted u

    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(u.COLLISION_ID AS INT)

    INNER JOIN dbo.dim_contributing_factor df
        ON df.factor_desc = u.factor_desc

    WHERE u.factor_desc IS NOT NULL
      AND u.factor_desc <> 'Unspecified'
      AND TRY_CAST(u.COLLISION_ID AS INT) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM   dbo.bridge_crash_factor tgt
          WHERE  tgt.collision_key = dc.collision_key
      );

END;