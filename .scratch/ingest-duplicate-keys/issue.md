# Ingest MERGE fails on keys repeated across landing files

**Status:** needs-triage

**What it is.** Notebook `nb_cdc_to_delta` re-reads every file under `Files/raw_nyc_crashes/<source>/`
and MERGEs on the natural key with no de-duplication (its Cell 6 comment says so). On 2026-10-02 the
landing pipeline wrote a delta file `8552e9f4-c872-42b7-ac6c-4162c77fef0c.csv` into each source folder
that repeats keys already in the 2026-09-10 full extract `18d27ca4cdde95e29dffc655284a310b`. Every
stage load since then fails in all three Ingest activities with
`DELTA_MULTIPLE_SOURCE_ROW_MATCHING_TARGET_ROW_IN_MERGE`.

**Evidence (Dev, 2026-10-10, pipeline run `c829db17-9878-4efb-9856-312774788636`).**
- crashes: 3,203,480 + 3,816 rows; 29 duplicated `collision_id`, 12 of them across files.
- persons: 5,984,110 + 4,221 rows; all 4,221 delta-file keys already in the full extract.
- Dev `nyc_*` Delta tables last MERGEd 2026-09-29 (before the delta file landed).

**Likely fix.** Before the MERGE, keep one row per key, the one from the newest file (audit columns
from Cell 5 carry the source file). Re-check within-file duplicates in the full extract for crashes
(17 keys appear twice inside one file). Test and Prod will hit the same failure on their next load.

## Comments

- **2026-10-10** — Found while running issue `measure-readiness-fixes/04` step 8. Worked around by
  running the two vehicle procedures directly; the Lakehouse vehicle table is unchanged since 2026-09-29.
