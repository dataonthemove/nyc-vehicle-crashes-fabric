CREATE PROCEDURE etl.usp_load_dim_factor_group
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_factor_group (collision_id)
    SELECT DISTINCT TRY_CAST(src.collision_id AS INT)
    FROM   NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes src
    WHERE  TRY_CAST(src.collision_id AS INT) IS NOT NULL
    AND NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_factor_group tgt
        WHERE  tgt.collision_id = TRY_CAST(src.collision_id AS INT)
    );

END;

GO