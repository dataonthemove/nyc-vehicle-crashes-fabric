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

mode         = "seed"          # seed | advance | read
source_name  = "crashes"       # crashes | persons | vehicles — used by advance/read
new_value    = ""              # ISO timestamp for mode="advance", e.g. 2026-09-09T00:00:00
seed_value   = "1900-01-01T00:00:00"


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 2 — Imports & config

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


def advance_watermark(source: str, value: str):
    """Upsert the watermark for one source to an explicit value."""
    if not value:
        raise ValueError("new_value is required when mode='advance'")
    row = (spark.createDataFrame([(source, value)], "source_name STRING, last_loaded_value STRING")
                .withColumn("last_loaded_value", F.to_timestamp("last_loaded_value"))
                .withColumn("last_run_utc",      F.current_timestamp()))
    (DeltaTable.forName(spark, TABLE_NAME).alias("t")
        .merge(row.alias("s"), "t.source_name = s.source_name")
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute())


def read_watermarks():
    return spark.table(TABLE_NAME).orderBy("source_name")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# CELL 5 — Execute the requested mode

if mode == "seed":
    seed_watermarks()
elif mode == "advance":
    advance_watermark(source_name, new_value)
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

wm = read_watermarks()
wm.show(truncate=False)

if mode == "seed":
    missing = set(SOURCES) - {r["source_name"] for r in wm.collect()}
    assert not missing, f"missing watermark rows: {missing}"
    print(f"watermark rows: {wm.count()}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
