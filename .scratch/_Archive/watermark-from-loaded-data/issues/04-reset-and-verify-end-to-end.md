# 04: Reset watermarks to 2026-06-11 and verify end to end

**What to build:** All three watermarks reset to 2026-06-11T00:00:00, the newest `crash_date` at source
(NYC Open Data has been frozen since 2026-06-15). When NYC resumes, its June–September backfill is then
captured instead of skipped. A final **CDC run** then shows the whole fix working together: the run
lands files named by run ID, queries Socrata from 2026-06-04 (the 7-day lookback), and leaves the
watermarks at 2026-06-11.

Parent spec: `.scratch/watermark-from-loaded-data/spec.md`

**Blocked by:** 02, 03

**Status:** resolved (2026-10-02)

| Step | Description | Owner | Status |
|---|---|---|---|
| 1 | Run `nb_etl_watermark` advance mode with explicit `new_value = 2026-06-11T00:00:00` once per source | CC | done |
| 2 | Read `etl_watermark` over Livy; confirm all three are 2026-06-11 | CC | done |
| 3 | Run one full CDC run | CC (Pat asked) | done — run `8552e9f4-c872-42b7-ac6c-4162c77fef0c` |
| 4 | Check the Copy step inputs in the run output and the landed files; read `etl_watermark` | CC | done |
| 5 | Mark the spec done; move `.scratch/watermark-from-loaded-data` to `_Archive`; commit | CC | done |

- [x] `etl_watermark` holds 2026-06-11T00:00:00 for crashes, persons and vehicles
- [x] Each Copy step's resolved query is `$where=crash_date>'2026-06-04T00:00:00'`
- [x] Three run-ID-named files land holding real rows dated after 06-04 up to 06-11 (the re-pulled overlap), so this run exercises the data path, not just the empty path
- [x] Watermarks remain 2026-06-11 after the run (no regression, no advance past landed data)
- [x] Spec status set to done with the date

Results (2026-10-02): the reset ran as three on-demand notebook jobs. The CDC run's Read_Watermarks
exited `2026-06-04T00:00:00` for all three sources, and each Copy resolved
`?$where=crash_date>'2026-06-04T00:00:00'`. Landed `<runId>.csv` files, read with `multiLine`:
crashes 1,278 rows · persons 4,221 · vehicles 2,470, all with `crash_date` 2026-06-05 → 2026-06-11.
Watermarks after the run: 2026-06-11 for all three; `last_run_utc` set by the run.
Copy inputs came from Fabric REST `queryactivityruns` (`az rest`); `get_pipeline_activity_runs` doesn't show them.
A plain CSV read without `multiLine` gives 3,816 crashes rows, because quoted fields contain line breaks.
