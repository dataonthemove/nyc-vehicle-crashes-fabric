CREATE PROCEDURE etl.usp_load_bridge_crash_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot 5 contributing factor columns into collision x factor pairs
    WITH unpivoted AS
    (
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT collision_id, NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    )
    INSERT INTO dbo.bridge_crash_factor (factor_group_key, factor_key)
    SELECT
        dfg.factor_group_key,
        df.factor_key
    FROM  unpivoted u

    INNER JOIN dbo.dim_collision dc
        ON dc.collision_id = TRY_CAST(u.collision_id AS INT)

    -- Resolve factor_group_key (1:1 with collision_key)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.collision_key = dc.collision_key

    INNER JOIN dbo.dim_contributing_factor df
        ON df.factor_desc = u.factor_desc

    WHERE u.factor_desc IS NOT NULL
      AND u.factor_desc <> 'Unspecified'
      AND TRY_CAST(u.collision_id AS INT) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM   dbo.bridge_crash_factor tgt
          WHERE  tgt.factor_group_key = dfg.factor_group_key
      );

END;

GO