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
        NULLIF(TRIM(src.pre_crash),       '') AS pre_crash,
        NULLIF(TRIM(src.point_of_impact), '') AS point_of_impact,
        NULLIF(TRIM(src.vehicle_damage),  '') AS vehicle_damage
    FROM  NYC_VehicleCrashes_Lakehouse.dbo.nyc_vehicles src
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM   dbo.dim_damage tgt
        WHERE  ISNULL(tgt.pre_crash,       '') = ISNULL(NULLIF(TRIM(src.pre_crash),       ''), '')
          AND  ISNULL(tgt.point_of_impact, '') = ISNULL(NULLIF(TRIM(src.point_of_impact), ''), '')
          AND  ISNULL(tgt.vehicle_damage,  '') = ISNULL(NULLIF(TRIM(src.vehicle_damage),  ''), '')
    );

END;

GO