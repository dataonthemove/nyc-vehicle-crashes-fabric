# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "b7f1c383-0af0-4b21-bf6b-4ac398b84391",
# META       "default_lakehouse_name": "NYC_VehicleCrashes_Landing_Lakehouse",
# META       "default_lakehouse_workspace_id": "bae79a94-0103-45dc-9993-d9041fbd4e80",
# META       "known_lakehouses": [
# META         {
# META           "id": "b7f1c383-0af0-4b21-bf6b-4ac398b84391"
# META         }
# META       ]
# META     }
# META   }
# META }

# PARAMETERS CELL ********************

# CELL 1 — Parameters (pipeline overrides these at runtime)
# Tag this cell as a "parameters" cell in Fabric UI (... > Toggle parameter cell)
#
# WHAT THIS NOTEBOOK IS
#   The one and only writer of the Delta table `etl_watermark` (one row per source:
#   crashes / persons / vehicles). A "watermark" is the timestamp of the last successful
#   load — the next load asks Socrata only for rows newer than it. Think of it as the
#   T-SQL `dbo.etl_watermark` pattern, but stored in the landing lakehouse and written by Spark.
#
# HOW IT IS CALLED — the same notebook runs in three different "modes":
#   seed    -> one-time setup, run by hand. Puts a starting row (1900-01-01) in the table for
#              every source that does not have one yet, so the first load pulls all history.
#   read    -> pipeline step `Read_Watermarks` (first activity in pl_cdc_NYC_Crashes_Landing).
#              Hands all three watermarks back to the pipeline as JSON (see CELL 6). The three
#              Copy_*_CDC activities plug those values into their Socrata `$where=crash_date>...`.
#   advance -> pipeline steps `Advance_Watermark_Crashes/_Persons/_Vehicles`, each run after
#              its own Copy succeeds. Sets one source's watermark in one of two ways:
#                loaded_file -> from the data: the newest crash_date in the file that Copy just
#                               landed. Never moves the watermark backwards, and a file with no
#                               data rows leaves it where it is (see CELL 4).
#                new_value   -> by hand: sets the watermark to exactly this value, even if that
#                               is earlier. For manual resets and fixes only.
#              If both are given, loaded_file wins. If neither is given, the run fails.
#              (Until the pipeline is switched over, it still passes new_value = utcnow().)
#
# HOW THESE VARIABLES WORK
#   The values below are only DEFAULTS for a manual run. Because this cell is tagged as the
#   parameters cell, the pipeline's Notebook activity injects its own values (its
#   "Base parameters") in a new cell right after this one, which overwrites these at runtime.
#   Every later cell reads these five variables.

mode         = "seed"          # seed | advance | read
source_name  = "crashes"       # crashes | persons | vehicles — used by advance/read
loaded_file  = ""              # mode="advance": landed file, relative to Files/, e.g. raw/crashes/<file>
new_value    = ""              # mode="advance" manual override: ISO timestamp, e.g. 2026-06-11T00:00:00
seed_value   = "1900-01-01T00:00:00"


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 2 — Imports & config
#
# Loads the libraries the later cells use and defines constants. Nothing is read or written here.
#   F           -> PySpark's built-in column functions (to_timestamp, current_timestamp), used in CELL 4.
#   StructType/StructField/... -> a way to describe a table's columns in Python (like a column list
#                  in CREATE TABLE). SCHEMA below documents the table shape; CELL 3 creates the
#                  actual table with the same three columns in SQL.
#   DeltaTable  -> gives access to Delta's MERGE (upsert) API, used by all three writers in CELL 4.
#   TABLE_NAME  -> the table every cell targets.
#   SOURCES     -> the three Socrata datasets; seed (CELL 4) creates one row for each, and the
#                  verify step (CELL 6) checks all three exist.

from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType, TimestampType
from delta.tables import DeltaTable

# Table path is relative to this notebook's attached default lakehouse — the landing lakehouse.
# No workspace or item name is embedded, so the notebook is portable if the landing workspace
# is ever rebuilt. The SQL analytics endpoint over this table is read-only; Spark is the writer.
TABLE_NAME = "etl_watermark"
SOURCES    = ["crashes", "persons", "vehicles"]

SCHEMA = StructType([
    StructField("source_name",       StringType(),    True),
    StructField("last_loaded_value", TimestampType(), True),
    StructField("last_run_utc",      TimestampType(), True),
])


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 3 — Create the Delta table if absent (no-op when it already exists)
#
# Runs on EVERY call, in every mode — a safety net so CELL 4's helpers and CELL 6's read never
# hit a missing table (e.g. on a freshly rebuilt lakehouse). `spark.sql(...)` simply runs the SQL
# text inside the triple quotes; the f"..." prefix lets {TABLE_NAME} from CELL 2 be substituted in.
# Columns:
#   source_name        -> which dataset: crashes | persons | vehicles  (the "key" of each row)
#   last_loaded_value  -> the watermark itself; Copy_*_CDC loads rows with crash_date > this value
#   last_run_utc       -> audit only: when this notebook last wrote the row

spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {TABLE_NAME} (
        source_name       STRING,
        last_loaded_value TIMESTAMP,
        last_run_utc      TIMESTAMP
    ) USING DELTA
""")

print(f"{TABLE_NAME} ready")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 4 — Helpers
#
# Defines four functions (`def` = define a reusable routine, like a stored procedure).
# Defining them does NOT run them — CELL 5 decides which one to call based on `mode`, and CELL 6
# calls read_watermarks(). All three writers use Delta MERGE, which behaves like T-SQL MERGE:
#   .merge(source, "t.source_name = s.source_name")  -> ON clause
#   .whenMatchedUpdateAll()                           -> WHEN MATCHED THEN UPDATE (all columns)
#   .whenNotMatchedInsertAll()                        -> WHEN NOT MATCHED THEN INSERT (all columns)
#   .whenMatchedUpdate(set={...})                     -> WHEN MATCHED THEN UPDATE SET col = ..., ...
#   .whenNotMatchedInsertAll(condition="...")         -> WHEN NOT MATCHED AND <condition> THEN INSERT
#   .execute()                                        -> actually run it
# The pattern `spark.createDataFrame(...)` + `.withColumn(...)` builds the small in-memory
# "source" rowset for the MERGE (like a VALUES table constructor), converting the text
# timestamp to a real TIMESTAMP and stamping last_run_utc with the current time.

# Called by CELL 5 when mode = "seed". Builds one row per entry in SOURCES (CELL 2), all set to
# seed_value (CELL 1), then MERGEs with INSERT-only — existing rows are left untouched, so
# re-running seed can never roll back a watermark the pipeline has already advanced.
def seed_watermarks(value: str = seed_value):
    """Insert a floor row for any source that has none. Never overwrites an advanced value."""
    rows  = [(s, value, None) for s in SOURCES]
    seeds = (spark.createDataFrame(rows, "source_name STRING, last_loaded_value STRING, last_run_utc STRING")
                  .withColumn("last_loaded_value", F.to_timestamp("last_loaded_value"))
                  .withColumn("last_run_utc",      F.current_timestamp()))
    (DeltaTable.forName(spark, TABLE_NAME).alias("t")
        .merge(seeds.alias("s"), "t.source_name = s.source_name")
        .whenNotMatchedInsertAll()
        .execute())


# Called by CELL 5 when mode = "advance" with new_value set — a manual override. Builds a single
# row (source_name, new_value) and MERGEs with UPDATE + INSERT (a true upsert), overwriting the
# old watermark. It may move the watermark backwards on purpose, e.g. to reset it. Text that is
# not a valid timestamp would convert to NULL, so that fails with an error instead of being written.
def advance_watermark(source: str, value: str):
    """Upsert the watermark for one source to an explicit value."""
    row = (spark.createDataFrame([(source, value)], "source_name STRING, last_loaded_value STRING")
                .withColumn("last_loaded_value", F.to_timestamp("last_loaded_value"))
                .withColumn("last_run_utc",      F.current_timestamp()))
    if row.first()["last_loaded_value"] is None:
        raise ValueError(f"new_value is not a valid timestamp: {value!r}")
    (DeltaTable.forName(spark, TABLE_NAME).alias("t")
        .merge(row.alias("s"), "t.source_name = s.source_name")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute())


# Called by CELL 5 when mode = "advance" with loaded_file set — the pipeline's Advance_Watermark_*
# activities, once per source, only after that source's Copy succeeded. Step by step:
#   1. Read the one CSV file Copy landed (same read options as nb_cdc_to_delta) and find the
#      newest crash_date in it — like SELECT MAX(CAST(crash_date AS DATETIME2)) FROM <file>.
#      Socrata writes crash_date as text, e.g. 2026-06-11T00:00:00.000, so it is converted to a
#      real timestamp first and never compared as text.
#   2. Safety check: if any crash_date fails that conversion, stop with an error rather than
#      quietly ignoring rows and computing a wrong date. Like T-SQL COUNT(col), F.count skips
#      NULLs, so a value that failed to convert shows up as parsed_rows < dated_rows.
#   3. MERGE the result. On the existing row, the watermark becomes the LATER of the stored value
#      and the file's newest date (`greatest` skips NULLs, like a MAX across two columns), so it
#      never moves backwards. A header-only file gives NULL, so the watermark stays put, but
#      last_run_utc is still stamped to show the source was checked. A source with no row yet
#      only gets one when the file has data (normally seed has already created every row).
def advance_watermark_from_file(source: str, path: str):
    """Move one source's watermark up to the newest crash_date in a landed file; never back."""
    stats = (spark.read
                 .option("header", True)
                 .option("inferSchema", False)
                 .option("nullValue", "")
                 .option("multiLine", True)
                 .csv(f"Files/{path}")
                 .agg(F.max(F.to_timestamp("crash_date")).alias("newest"),
                      F.count("crash_date").alias("dated_rows"),
                      F.count(F.to_timestamp("crash_date")).alias("parsed_rows"))
                 .first())
    if stats["dated_rows"] != stats["parsed_rows"]:
        raise ValueError(f"{stats['dated_rows'] - stats['parsed_rows']} crash_date value(s) in "
                         f"{path} are not valid timestamps")
    print(f"newest crash_date in {path}: {stats['newest']}")
    row = (spark.createDataFrame([(source, stats["newest"])],
                                 "source_name STRING, last_loaded_value TIMESTAMP")
                .withColumn("last_run_utc", F.current_timestamp()))
    (DeltaTable.forName(spark, TABLE_NAME).alias("t")
        .merge(row.alias("s"), "t.source_name = s.source_name")
        .whenMatchedUpdate(set={
            "last_loaded_value": "greatest(t.last_loaded_value, s.last_loaded_value)",
            "last_run_utc":      "s.last_run_utc"})
        .whenNotMatchedInsertAll(condition="s.last_loaded_value IS NOT NULL")
        .execute())


# Equivalent to SELECT * FROM etl_watermark ORDER BY source_name. Returns a DataFrame (a query
# result held in Spark) rather than printing it; CELL 6 displays it and, in read mode, sends it
# back to the pipeline.
def read_watermarks():
    return spark.table(TABLE_NAME).orderBy("source_name")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 5 — Execute the requested mode
#
# The decision point — like an IF / ELSE IF block in T-SQL. Looks at `mode` (CELL 1, or the
# pipeline's override) and calls the matching helper from CELL 4:
#   seed    -> seed_watermarks()                                       writes starting rows
#   advance -> advance_watermark_from_file(source_name, loaded_file)  when loaded_file is set
#              advance_watermark(source_name, new_value)               else, if new_value is set
#              neither set -> raise an error before anything is written, rather than guess a value
#   read    -> `pass` = do nothing here; there is nothing to write. The real work for read mode
#              happens in CELL 6, which runs for every mode.
# Any other value (e.g. a typo in the pipeline parameter) raises an error and fails the
# activity, rather than silently doing nothing.

if mode == "seed":
    seed_watermarks()
elif mode == "advance":
    if loaded_file:
        advance_watermark_from_file(source_name, loaded_file)
    elif new_value:
        advance_watermark(source_name, new_value)
    else:
        raise ValueError("mode='advance' needs loaded_file or new_value")
elif mode == "read":
    pass
else:
    raise ValueError(f"unknown mode: {mode}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 6 — Read back and verify
#
# Runs for every mode. Step by step:
#   1. Query the table (read_watermarks, CELL 4) and print it to the cell output — so every run,
#      manual or pipeline, leaves a visible record of the watermarks after it finished.
#   2. seed mode only: confirm each name in SOURCES (CELL 2) now has a row. `wm.collect()` pulls
#      the rows into Python; the set subtraction finds any source that is missing; `assert`
#      fails the notebook with that message if the list is not empty.
#   3. read mode only: send the watermarks back to the pipeline (explained just below).

wm = read_watermarks()
wm.show(truncate=False)

if mode == "seed":
    missing = set(SOURCES) - {r["source_name"] for r in wm.collect()}
    assert not missing, f"missing watermark rows: {missing}"
    print(f"watermark rows: {wm.count()}")

# mode="read" returns the watermarks to the caller as JSON. Fabric Pipeline
# pl_cdc_NYC_Crashes_Landing consumes this instead of a SQL-endpoint Lookup: the SQL analytics
# endpoint is not a Git item, so a Lookup referencing it fails Git import with MissingDependencies.
#
# How the hand-off works:
#   - notebookutils (newer name) / mssparkutils (older name) is Fabric's notebook helper library;
#     the try/except just imports whichever one exists in this runtime.
#   - `payload` is a Python dictionary built from the rows, one entry per source, formatted as
#     text, e.g. {"crashes": "2026-09-30T14:05:00", "persons": "...", "vehicles": "..."}.
#   - json.dumps turns it into a JSON string; notebook.exit(...) ends the notebook and hands
#     that string to the pipeline as the activity's "exit value".
#   - In the pipeline, each Copy activity reads its own entry, e.g. for crashes:
#       @{json(activity('Read_Watermarks').output.result.exitValue).crashes}
#     and drops it into the Socrata query  $where=crash_date>'<that value>'.
if mode == "read":
    import json
    try:
        import notebookutils as nbutils
    except ImportError:
        import mssparkutils as nbutils
    payload = {r["source_name"]: r["last_loaded_value"].strftime("%Y-%m-%dT%H:%M:%S")
               for r in wm.collect()}
    nbutils.notebook.exit(json.dumps(payload))


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
