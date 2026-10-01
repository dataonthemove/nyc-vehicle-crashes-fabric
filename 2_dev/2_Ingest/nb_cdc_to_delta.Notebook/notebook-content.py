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
#
# WHAT THIS NOTEBOOK DOES
# One run turns the raw CSV files for ONE source (crashes, persons or vehicles) into ONE Delta
# table in this stage's lakehouse:
#     Files/raw_nyc_crashes/<source>/*   →   Tables/dbo/nyc_<source>
# Pipeline pl_stage_load_NYC_Crashes runs it three times in parallel (once per source). The
# Warehouse procedures etl.usp_load_* then read those three Delta tables to build the star schema.
#
# How the cells connect:
#   1 Parameters  — which source this run handles
#   2 Imports     — tools used by the later cells
#   3 Schema      — the list of columns (and types) we expect for that source
#   4 Read        — read every file, keep only the expected columns, check the data is usable
#   5 Audit       — stamp each row with when it was loaded and which file it came from
#   6 Merge       — upsert the rows into the Delta table (create the table on first run)
#   7 Exit        — report success back to the pipeline
#
# Where the files come from: the landing workspace's pipeline downloads from NYC Open Data into
# landing Files/raw/<source>. This lakehouse sees those files through OneLake shortcut
# raw_nyc_crashes — a pointer, not a copy (ADR-0002).
#
# Despite "cdc" in the name, every run re-reads ALL files in the folder, not just the newest.
# Cell 6's merge is what makes that safe: rows already in the table are overwritten with the
# same values and only genuinely new keys are added, so a rerun gives the same table.
#
# The values below are the defaults for a manual run (crashes). The pipeline passes its own
# values per source; persons and vehicles use natural_key = "unique_id".

source_name    = "crashes"                  # crashes | persons | vehicles — picks the schema (cell 3) and target table (cell 6)
file_subfolder = "raw_nyc_crashes/crashes"  # Files/ subfolder via OneLake shortcut to landing Files/raw/
file_pattern   = "*"                        # Copy sink emits extensionless files — do not use *.csv
natural_key    = "collision_id"             # merge key — unique per source row; cell 6 matches existing rows on it


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 2 — Imports & config
#
# Nothing runs against data here; this just loads the tools the later cells use:
#   F (pyspark functions)  — column operations: casting types (cell 4), timestamps and file
#                            names (cell 5).
#   pyspark types          — StructType / LongType etc., used to describe the columns in cell 3.
#   DeltaTable             — the Delta Lake API that performs the MERGE (upsert) in cell 6.
#   nbutils                — Fabric's notebook utilities. Used for notebook.exit(), which stops
#                            the notebook and hands a text value back to the calling pipeline
#                            (cells 4 and 7).

from pyspark.sql import functions as F
from pyspark.sql.types import *
from delta.tables import DeltaTable

# notebookutils replaced mssparkutils in newer Fabric Spark runtimes
try:
    import notebookutils as nbutils
except ImportError:
    import mssparkutils as nbutils

# Paths below are relative to this notebook's attached default lakehouse. No workspace or
# lakehouse name is embedded, so the notebook survives deployment to Test/Prod unchanged.


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 3 — Schema definitions
#
# SCHEMAS is the "contract" for each source: the exact columns we keep and the data type each
# one is converted to. Think of it as the column list of a staging table's CREATE TABLE.
#   - Cell 4 uses it to check the file header has every column, then to select and cast them.
#   - Any column in the file that is NOT listed here is dropped (e.g. the crashes feed's
#     `location` column, which only repeats latitude/longitude).
#   - Names must match the CSV header exactly. Oddities like vehicle_type_code1 vs
#     vehicle_type_code_3 are NYC's own naming, not typos — do not "fix" them.
#   - crash_date / crash_time stay strings here; the Warehouse procs convert them to DATE
#     (e.g. TRY_CAST in etl.usp_load_fact_crashes).
#   - Every field is nullable (the final True) because the source data has gaps.
# The two lines at the bottom pick the one schema this run needs, based on cell 1's parameters.

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
        StructField("ped_role", StringType(), True),
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

schema = SCHEMAS[source_name]   # the column list for this run's source
merge_key = natural_key          # alias used by cells 4 and 6


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 4 — Read staged files from Files/
#
# In plain terms: read every CSV file in the source folder, keep only the columns cell 3 lists,
# convert them to the right types, then run two sanity checks before anything is written.
#   Step 1  spark.read ... .csv()  — read all files matching Files/<file_subfolder>/<file_pattern>
#           as one dataset, every value as text. Empty values become NULL (nullValue "").
#           Header-only files (written when a download found no new rows) add zero rows.
#   Step 2  `missing` check        — stop with an error if the files lack any expected column.
#   Step 3  select + cast          — keep the expected columns, in cell 3's order, with cell 3's
#           types. Text that won't convert (e.g. "abc" into a number) becomes NULL, not an error.
#   Step 4  row count              — if there are no data rows at all, exit early with
#           "NO_NEW_DATA". The pipeline treats this as success; cells 5–7 do not run.
#   Step 5  NULL-key check         — stop with an error if any row has no merge key, because
#           cell 6 could not match it and downstream joins would drop it.
#
# Read as strings and let the header name the columns. Passing .schema() directly applies
# fields BY POSITION and ignores the header, so any difference between the API's column
# order and SCHEMAS[source_name] shifts every value one place — which is what silently
# NULLed every collision_id in nyc_crashes.
#
# multiLine is required: the crashes feed's `location` column holds a quoted value that
# contains newlines, so one record spans three physical lines. Without it Spark treats each
# line as a row and 210,428 of 2,000,000 crash records shred into 631,283 fragments.
# It costs parallelism — the file can no longer be split — but correctness wins here.
raw = (
    spark.read
    .option("header", True)
    .option("inferSchema", False)
    .option("nullValue", "")
    .option("multiLine", True)
    .csv(f"Files/{file_subfolder}/{file_pattern}")
)

missing = [f.name for f in schema.fields if f.name not in raw.columns]
if missing:
    raise ValueError(f"[{source_name}] Columns missing from source header: {missing}")

# Select by name, then cast — the file's column order no longer matters.
df_new = raw.select([F.col(f.name).cast(f.dataType).alias(f.name) for f in schema.fields])

row_count = df_new.count()

if row_count == 0:
    nbutils.notebook.exit("NO_NEW_DATA")

# A merge key that casts to NULL means a type mismatch, not absent data. Fail loudly rather
# than write a table that joins to nothing downstream.
null_keys = df_new.filter(F.col(merge_key).isNull()).count()
print(f"[{source_name}] Staged rows: {row_count} (null {merge_key}: {null_keys})")

if null_keys:
    raise ValueError(f"[{source_name}] {null_keys} of {row_count} rows have a NULL {merge_key} — aborting.")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 5 — Add audit columns
#
# Adds two lineage columns to every row, the same idea as audit columns on a staging table:
#   _load_timestamp — when this run happened. Because cell 6 rewrites every matched row, this
#                     shows the LAST run that touched the row, not when it first arrived.
#   _source_file    — the full path of the file the row was read from, so a bad row can be
#                     traced back to the download that produced it.
# Spark is lazy: df_new is still a recipe, not data in memory. The files are actually read
# again when cell 6 writes, and these columns are filled in at that point.

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
#
# Writes the rows into Delta table nyc_<source>. This is the same as a T-SQL MERGE:
#   - Table already exists → MERGE ON tgt.<key> = src.<key>
#       WHEN MATCHED     → UPDATE every column with the file's values (UpdateAll)
#       WHEN NOT MATCHED → INSERT the row (InsertAll)
#     There is no delete branch: a row in the table but no longer in the files is kept.
#   - Table does not exist yet (first run in a new stage) → plain write that creates it.
# Nothing removes duplicate keys first. If one key appears in two files, the MERGE fails with a
# "multiple source rows matched" error (on the first-run write both copies would be kept).
# The finished table is what the Warehouse procs read as NYC_VehicleCrashes_Lakehouse.dbo.nyc_<source>.
#
# Schema-enabled lakehouse: the first level under Tables/ is the SCHEMA namespace.
# Writing to Tables/<name> creates a schema, not a table — the target must be Tables/dbo/<name>.
target_path = f"Tables/dbo/nyc_{source_name}"

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
#
# Stops the notebook and returns "SUCCESS|<source>" to the pipeline as the activity's exit value.
# Possible outcomes of one run:
#   SUCCESS|<source>  — table created or merged (this cell)
#   NO_NEW_DATA       — no data rows found; also a success (cell 4)
#   Error raised      — missing columns or NULL keys (cell 4). The activity fails, and because
#                       every pipeline edge is "on success", the Warehouse procs do not run.

nbutils.notebook.exit(f"SUCCESS|{source_name}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
