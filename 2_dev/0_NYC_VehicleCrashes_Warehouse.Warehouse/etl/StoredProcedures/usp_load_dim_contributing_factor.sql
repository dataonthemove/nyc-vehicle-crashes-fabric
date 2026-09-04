CREATE PROCEDURE etl.usp_load_dim_contributing_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot all 5 contributing factor columns into a single distinct list
    WITH all_factors AS
    (
        SELECT NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    )
    INSERT INTO dbo.dim_contributing_factor (factor_desc)
    SELECT factor_desc
    FROM   all_factors src
    WHERE  src.factor_desc IS NOT NULL
      AND  NOT EXISTS
           (
               SELECT 1
               FROM   dbo.dim_contributing_factor tgt
               WHERE  tgt.factor_desc = src.factor_desc
           );

END;

GO