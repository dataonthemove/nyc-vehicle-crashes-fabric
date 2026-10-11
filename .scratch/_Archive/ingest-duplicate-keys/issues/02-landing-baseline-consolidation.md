# 02: Consolidate landing source files into one baseline per source

**What to build:** Each landing folder `Files/raw/<source>/` in `NYC_VehicleCrashes_Landing_Lakehouse`
holds one de-duplicated baseline file `full_2026-10-11.csv` plus the `.keep` placeholder, replacing the
extensionless full extract and every `<runId>.csv` (header-only or overlapping). The originals are
backed up to `Files/archive/2026-10-11/<source>/` first. The baseline keeps every source column, is a
standard header-row CSV with `"` as quote and escape, and uses the same newest-row-per-key rule as
ticket 01. Watermarks are not touched. A Dev stage load afterwards leaves `nyc_*` row counts
unchanged. Runs once over Livy against the landing lakehouse (data operation, not an item change);
the script used is recorded under Comments.

**Blocked by:** 01

**Status:** done (2026-10-11)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | List each source folder; record file names, sizes, and `multiLine` row and distinct-key counts | CC | Inventory and counts recorded here | done |
| 2 | Copy every original file to the archive folder | CC | Archive file count and sizes equal the originals per source | done |
| 3 | Write one de-duplicated CSV per source; move its single part file to `full_2026-10-11.csv`; remove temp output | CC | Baseline file exists per source; no stray part or `_SUCCESS` files | done |
| 4 | Read each baseline back with `multiLine`; compare rows to distinct keys of the originals; spot-check a record with embedded line breaks | CC | Baseline rows = distinct keys, no NULL keys, multi-line record intact | done |
| 5 | Pat approves deleting the originals | Pat | Approval given in session | done |
| 6 | Delete the originals, keeping `.keep` and the baseline | CC | Each folder lists only `.keep` and `full_2026-10-11.csv` | done |
| 7 | Read `etl_watermark` over Livy | CC | All three still 2026-06-11 | done |
| 8 | Run `pl_stage_load_NYC_Crashes` in Dev | CC | All activities succeed; `nyc_*` row counts equal ticket 01 step 10; key uniqueness holds | done |
| 9 | Add the baseline file and archive folder to `docs/socrata-ingestion.md`; commit locally (`CC Commit: landing_raw-files_baseline-consolidation`) | CC | Doc describes folder contents; commit exists | done |

## Comments

- **2026-10-11, step 1** — `.keep` lives at `Files/raw/.keep`, not in each source folder; it is left
  as is and the source folders end with the baseline only. All files in a folder share one header.
  `multiLine` counts (RFC read, `"` quote and escape):

  | Source | Files (bytes) | Full extract `18d27ca4…` rows | Run `8552e9f4….csv` rows | Header-only files | Rows | Distinct keys |
  |---|---|---|---|---|---|---|
  | crashes | 6 (600,766,336) | 2,269,187 | 1,278 | 4 | 2,270,465 | 2,269,187 |
  | persons | 5 (1,246,549,944) | 5,984,110 | 4,221 | 3 | 5,988,331 | 5,984,110 |
  | vehicles | 5 (1,046,904,807) | 4,551,002 | 2,470 | 3 | 4,553,472 | 4,551,002 |

  No within-file duplicates and no NULL keys in any source.
- **2026-10-11, step 2** — Every original copied to `Files/archive/2026-10-11/<source>/`; file names,
  counts and byte sizes match per source (6/5/5 files).
- **2026-10-11, step 3** — Baselines written: crashes 511,701,448 B, persons 1,080,546,168 B,
  vehicles 901,841,520 B. Smaller than the originals because Socrata quotes every field and Spark
  quotes only where needed. Temp folder `Files/tmp/` removed; no part or `_SUCCESS` files left.
- **2026-10-11, step 4** — Each baseline row count = distinct keys of the originals, 0 NULL keys,
  and `exceptAll` both ways against the de-duplicated originals = 0, both with an RFC read and with
  `nb_cdc_to_delta`'s own read options. 467,146 crash records hold a multi-line `location`; spot key
  3415658 (`'
,  
(40.620785, -73.924164)'`) is identical to its original row. All 1,278 run-file crash
  rows are in the baseline unchanged (newer file won). No value contains an embedded `"`.

- **2026-10-11, step 5** — Pat approved deleting the originals in session.
- **2026-10-11, step 6** — Each original deleted only after its archive copy matched by name and
  size. Each source folder now lists only `full_2026-10-11.csv`; `Files/raw/` still holds `.keep`.
- **2026-10-11, step 7** — `etl_watermark` (landing, `Tables/dbo/`): crashes, persons, vehicles all
  `last_loaded_value` 2026-06-11, `last_run_utc` unchanged since 2026-10-02.
- **2026-10-11, step 8** — Dev pipeline run `adfdfbb8-f79b-4a10-a6ec-effd47534e06`: all 16 activities
  succeeded, Refresh included. Dev `nyc_crashes` 2,269,187 · `nyc_persons` 5,984,110 ·
  `nyc_vehicles` 4,551,002, equal to ticket 01 step 10; `count = countDistinct(key)` for all three.
  Every row's `_source_file` is now the baseline (the lineage trade-off the spec accepts).
- **2026-10-11, step 9** — Baseline and archive added to `docs/socrata-ingestion.md` section 5 and
  `Context/environment-reference.md` landing artifacts.

### Script (Livy, landing lakehouse, session `f11b5a6e`)

```python
BASE = "abfss://<landing ws>@onelake.dfs.fabric.microsoft.com/<landing lakehouse>/Files"
KEYS = {"crashes": "collision_id", "persons": "unique_id", "vehicles": "unique_id"}
BASELINE = "full_2026-10-11.csv"

def read_raw(path, rfc=True):
    r = (spark.read.option("header", True).option("inferSchema", False)
         .option("nullValue", "").option("multiLine", True))
    if rfc:
        r = r.option("quote", '"').option("escape", '"')
    return r.csv(path)

# step 2 — archive
for s in KEYS:
    for fi in nbutils.fs.ls(f"{BASE}/raw/{s}"):
        nbutils.fs.cp(fi.path, f"{BASE}/archive/2026-10-11/{s}/{fi.name}")

# step 3 — newest row per key, same rule as nb_cdc_to_delta cell 5
TMP = f"{BASE}/tmp/baseline_2026-10-11"
for s, k in KEYS.items():
    originals = [fi.path for fi in nbutils.fs.ls(f"{BASE}/raw/{s}") if fi.name != BASELINE]
    df = read_raw(originals)
    w = Window.partitionBy(k).orderBy(F.col("_metadata.file_modification_time").desc(),
                                      F.col("_metadata.file_path").desc())
    kept = df.withColumn("_rank", F.row_number().over(w)).filter("_rank = 1").select(df.columns)
    (kept.repartition(1).write.mode("overwrite")
        .option("header", True).option("quote", '"').option("escape", '"')
        .option("ignoreLeadingWhiteSpace", False).option("ignoreTrailingWhiteSpace", False)
        .csv(f"{TMP}/{s}"))
    part = [fi.path for fi in nbutils.fs.ls(f"{TMP}/{s}") if fi.name.startswith("part-")]
    assert len(part) == 1
    nbutils.fs.mv(part[0], f"{BASE}/raw/{s}/{BASELINE}")
nbutils.fs.rm(f"{BASE}/tmp", True)
```
