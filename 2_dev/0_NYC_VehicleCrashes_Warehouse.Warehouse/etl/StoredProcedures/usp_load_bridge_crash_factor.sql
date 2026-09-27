CREATE PROCEDURE etl.usp_load_bridge_crash_factor
AS
BEGIN
    SET NOCOUNT ON;

    -- Unpivot 5 contributing factor columns into collision x factor pairs (UNION collapses duplicates within a crash)
    WITH crash_factor AS
    (
        SELECT TRY_CAST(collision_id AS INT) AS collision_id, NULLIF(TRIM(contributing_factor_vehicle_1), '') AS factor_desc FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_2), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_3), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_4), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
        UNION
        SELECT TRY_CAST(collision_id AS INT), NULLIF(TRIM(contributing_factor_vehicle_5), '') FROM NYC_VehicleCrashes_Lakehouse.dbo.nyc_crashes
    ),
    -- One factor set per crash: SHA-256 over its sorted distinct specified factor_desc values.
    -- No specified factor (NULL or 'Unspecified') hashes '' -> the single empty-set group.
    -- Identical in usp_load_dim_factor_group, usp_load_fact_crashes and usp_load_bridge_crash_factor.
    crash_factor_set AS
    (
        SELECT
            collision_id,
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', ISNULL(
                STRING_AGG(CASE WHEN factor_desc <> 'Unspecified' THEN factor_desc END, '|')
                    WITHIN GROUP (ORDER BY factor_desc), '')), 2) AS factor_set_hash
        FROM   crash_factor
        WHERE  collision_id IS NOT NULL
        GROUP  BY collision_id
    )
    INSERT INTO dbo.bridge_crash_factor (factor_group_key, factor_key)
    SELECT DISTINCT
        dfg.factor_group_key,
        df.factor_key
    FROM  crash_factor cf

    INNER JOIN crash_factor_set cfs
        ON cfs.collision_id = cf.collision_id

    -- Resolve factor_group_key by factor-set hash (many crashes share one group)
    INNER JOIN dbo.dim_factor_group dfg
        ON dfg.factor_set_hash = cfs.factor_set_hash

    INNER JOIN dbo.dim_contributing_factor df
        ON df.factor_desc = cf.factor_desc

    -- Specified factors only (also excludes NULL): the empty-set group gets no bridge rows
    WHERE cf.factor_desc <> 'Unspecified'

    -- Incremental: insert rows only for groups not yet in the bridge
      AND NOT EXISTS
      (
          SELECT 1
          FROM   dbo.bridge_crash_factor tgt
          WHERE  tgt.factor_group_key = dfg.factor_group_key
      );

END;

GO