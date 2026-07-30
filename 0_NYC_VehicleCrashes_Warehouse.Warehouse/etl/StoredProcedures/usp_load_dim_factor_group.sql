CREATE PROCEDURE etl.usp_load_dim_factor_group
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.dim_factor_group (collision_key)
    SELECT dc.collision_key
    FROM   dbo.dim_collision dc
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_factor_group tgt
        WHERE  tgt.collision_key = dc.collision_key
    );

END;

GO