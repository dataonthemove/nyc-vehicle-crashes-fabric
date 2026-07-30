CREATE PROCEDURE etl.usp_load_dim_collision
AS
BEGIN
    SET NOCOUNT ON;

    -- Incremental insert: only new collision_ids not yet in dim_collision
    INSERT INTO dbo.dim_collision (collision_id)
        SELECT DISTINCT CAST(src.COLLISION_ID AS INT)
        FROM   NYC_VehicleCrashes_Lakehouse.dbo.motor_vehicle_collisionscrashes src
        WHERE  src.COLLISION_ID IS NOT NULL
        AND  NOT EXISTS (
                SELECT 1
                FROM   dbo.dim_collision tgt
                WHERE  tgt.collision_id = CAST(src.COLLISION_ID AS INT)
            );

END;

GO