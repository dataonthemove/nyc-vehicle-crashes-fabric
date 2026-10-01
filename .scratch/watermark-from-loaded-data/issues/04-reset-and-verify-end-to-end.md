# 04: Reset watermarks to 2026-06-11 and verify end to end

**What to build:** All three watermarks reset to 2026-06-11T00:00:00, the newest `crash_date` at source
(NYC Open Data has been frozen since 2026-06-15). When NYC resumes, its June–September backfill is then
captured instead of skipped. A final **CDC run** then shows the whole fix working together: the run
lands files named by run ID, queries Socrata from 2026-06-04 (the 7-day lookback), and leaves the
watermarks at 2026-06-11.

Parent spec: `.scratch/watermark-from-loaded-data/spec.md`

**Blocked by:** 02, 03

**Status:** ready-for-agent

| Step | Description | Owner | Status |
|---|---|---|---|
| 1 | Run `nb_etl_watermark` advance mode with explicit `new_value = 2026-06-11T00:00:00` once per source | CC | todo |
| 2 | Read `etl_watermark` over Livy; confirm all three are 2026-06-11 | CC | todo |
| 3 | Run one full CDC run | Pat | todo |
| 4 | Check the Copy step inputs in the run output and the landed files; read `etl_watermark` | CC | todo |
| 5 | Mark the spec done; move `.scratch/watermark-from-loaded-data` to `_Archive`; commit | CC | todo |

- [ ] `etl_watermark` holds 2026-06-11T00:00:00 for crashes, persons and vehicles
- [ ] Each Copy step's resolved query is `$where=crash_date>'2026-06-04T00:00:00'`
- [ ] Three run-ID-named files land holding real rows dated after 06-04 up to 06-11 (the re-pulled overlap), so this run exercises the data path, not just the empty path
- [ ] Watermarks remain 2026-06-11 after the run (no regression, no advance past landed data)
- [ ] Spec status set to done with the date
