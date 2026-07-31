# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "69699b13-5771-422f-874c-461430f81d9b",
# META       "default_lakehouse_name": "NYC_VehicleCrashes_Lakehouse",
# META       "default_lakehouse_workspace_id": "73d1612d-023e-40bb-914b-fcd796620223",
# META       "known_lakehouses": [
# META         {
# META           "id": "69699b13-5771-422f-874c-461430f81d9b"
# META         }
# META       ]
# META     }
# META   }
# META }

# PARAMETERS CELL ********************

# CELL 1 — Parameters (pipeline overrides these at runtime)
# Tag this cell as a "parameters" cell in Fabric UI (... > Toggle parameter cell)

source_name    = "crashes"                  # crashes | persons | vehicles
file_subfolder = "NYC_CrashData/crashes"    # Files subfolder where CDC drop lands
file_pattern   = "*"                        # Copy sink emits extensionless files — do not use *.csv
natural_key    = "collision_id"             # merge key — unique per source row


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 2 — Imports & config

from pyspark.sql import functions as F
from pyspark.sql.types import *
from delta.tables import DeltaTable

# notebookutils replaced mssparkutils in newer Fabric Spark runtimes
try:
    import notebookutils as nbutils
except ImportError:
    import mssparkutils as nbutils

# OneLake requires the item-type extension on the item name ({itemname}.{itemtype}).
# The filesystem segment is the workspace, not the lakehouse.
WORKSPACE_NAME = "NYC_VehicleCrashes"
LAKEHOUSE_NAME = "NYC_VehicleCrashes_Lakehouse"
LAKEHOUSE_ROOT = f"abfss://{WORKSPACE_NAME}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_NAME}.Lakehouse"


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 3 — Schema definitions

SCHEMAS = {
    "crashes": StructType([
        StructField("collision_id", LongType(), True),
        StructField("crash_date", StringType(), True),
        StructField("crash_time", StringType(), True),
        StructField("borough", StringType(), True),
        StructField("zip_code", StringType(), True),
        StructField("latitude", DoubleType(), True),
        StructField("longitude", DoubleType(), True),
        StructField("on_street_name", StringType(), True),
        StructField("cross_street_name", StringType(), True),
        StructField("off_street_name", StringType(), True),
        StructField("number_of_persons_injured", IntegerType(), True),
        StructField("number_of_persons_killed", IntegerType(), True),
        StructField("number_of_pedestrians_injured", IntegerType(), True),
        StructField("number_of_pedestrians_killed", IntegerType(), True),
        StructField("number_of_cyclist_injured", IntegerType(), True),
        StructField("number_of_cyclist_killed", IntegerType(), True),
        StructField("number_of_motorist_injured", IntegerType(), True),
        StructField("number_of_motorist_killed", IntegerType(), True),
        StructField("contributing_factor_vehicle_1", StringType(), True),
        StructField("contributing_factor_vehicle_2", StringType(), True),
        StructField("contributing_factor_vehicle_3", StringType(), True),
        StructField("contributing_factor_vehicle_4", StringType(), True),
        StructField("contributing_factor_vehicle_5", StringType(), True),
        StructField("vehicle_type_code1", StringType(), True),
        StructField("vehicle_type_code2", StringType(), True),
        StructField("vehicle_type_code_3", StringType(), True),
        StructField("vehicle_type_code_4", StringType(), True),
        StructField("vehicle_type_code_5", StringType(), True),
    ]),
    "persons": StructType([
        StructField("unique_id", StringType(), True),
        StructField("collision_id", LongType(), True),
        StructField("crash_date", StringType(), True),
        StructField("crash_time", StringType(), True),
        StructField("person_id", StringType(), True),
        StructField("person_type", StringType(), True),
        StructField("person_injury", StringType(), True),
        StructField("vehicle_id", StringType(), True),
        StructField("person_age", IntegerType(), True),
        StructField("ejection", StringType(), True),
        StructField("emotional_status", StringType(), True),
        StructField("bodily_injury", StringType(), True),
        StructField("position_in_vehicle", StringType(), True),
        StructField("safety_equipment", StringType(), True),
        StructField("ped_location", StringType(), True),
        StructField("ped_action", StringType(), True),
        StructField("complaint", StringType(), True),
        StructField("contributing_factor_1", StringType(), True),
        StructField("contributing_factor_2", StringType(), True),
        StructField("person_sex", StringType(), True),
    ]),
    "vehicles": StructType([
        StructField("unique_id", StringType(), True),
        StructField("collision_id", LongType(), True),
        StructField("crash_date", StringType(), True),
        StructField("crash_time", StringType(), True),
        StructField("vehicle_id", StringType(), True),
        StructField("state_registration", StringType(), True),
        StructField("vehicle_type", StringType(), True),
        StructField("vehicle_make", StringType(), True),
        StructField("vehicle_model", StringType(), True),
        StructField("vehicle_year", IntegerType(), True),
        StructField("travel_direction", StringType(), True),
        StructField("vehicle_occupants", IntegerType(), True),
        StructField("driver_sex", StringType(), True),
        StructField("driver_license_status", StringType(), True),
        StructField("driver_license_jurisdiction", StringType(), True),
        StructField("pre_crash", StringType(), True),
        StructField("point_of_impact", StringType(), True),
        StructField("vehicle_damage", StringType(), True),
        StructField("vehicle_damage_1", StringType(), True),
        StructField("vehicle_damage_2", StringType(), True),
        StructField("vehicle_damage_3", StringType(), True),
        StructField("public_property_damage", StringType(), True),
        StructField("public_property_damage_type", StringType(), True),
        StructField("contributing_factor_1", StringType(), True),
        StructField("contributing_factor_2", StringType(), True),
    ]),
}

schema = SCHEMAS[source_name]
merge_key = natural_key


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 4 — Read staged files from Files/

df_new = (
    spark.read
    .option("header", True)
    .option("inferSchema", False)
    .option("nullValue", "")
    .schema(schema)
    .csv(f"{LAKEHOUSE_ROOT}/Files/{file_subfolder}/{file_pattern}")
)

row_count = df_new.count()
print(f"[{source_name}] Staged rows: {row_count}")

if row_count == 0:
    nbutils.notebook.exit("NO_NEW_DATA")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 5 — Add audit columns

df_new = (
    df_new
    .withColumn("_load_timestamp", F.current_timestamp())
    .withColumn("_source_file", F.input_file_name())
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 6 — Merge into Delta target

target_path = f"{LAKEHOUSE_ROOT}/Tables/{source_name}_raw"

if DeltaTable.isDeltaTable(spark, target_path):
    delta_tbl = DeltaTable.forPath(spark, target_path)
    (
        delta_tbl.alias("tgt")
        .merge(df_new.alias("src"), f"tgt.{merge_key} = src.{merge_key}")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute()
    )
    print(f"[{source_name}] Merge complete.")
else:
    df_new.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save(target_path)
    print(f"[{source_name}] Initial Delta table created.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 7 — Exit

nbutils.notebook.exit(f"SUCCESS|{source_name}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
