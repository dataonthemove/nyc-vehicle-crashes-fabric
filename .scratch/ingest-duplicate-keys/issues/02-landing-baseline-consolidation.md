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

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | List each source folder; record file names, sizes, and `multiLine` row and distinct-key counts | CC | Inventory and counts recorded here | todo |
| 2 | Copy every original file to the archive folder | CC | Archive file count and sizes equal the originals per source | todo |
| 3 | Write one de-duplicated CSV per source; move its single part file to `full_2026-10-11.csv`; remove temp output | CC | Baseline file exists per source; no stray part or `_SUCCESS` files | todo |
| 4 | Read each baseline back with `multiLine`; compare rows to distinct keys of the originals; spot-check a record with embedded line breaks | CC | Baseline rows = distinct keys, no NULL keys, multi-line record intact | todo |
| 5 | Pat approves deleting the originals | Pat | Approval given in session | todo |
| 6 | Delete the originals, keeping `.keep` and the baseline | CC | Each folder lists only `.keep` and `full_2026-10-11.csv` | todo |
| 7 | Read `etl_watermark` over Livy | CC | All three still 2026-06-11 | todo |
| 8 | Run `pl_stage_load_NYC_Crashes` in Dev | CC | All activities succeed; `nyc_*` row counts equal ticket 01 step 10; key uniqueness holds | todo |
| 9 | Add the baseline file and archive folder to `docs/socrata-ingestion.md`; commit locally (`CC Commit: landing_raw-files_baseline-consolidation`) | CC | Doc describes folder contents; commit exists | todo |
