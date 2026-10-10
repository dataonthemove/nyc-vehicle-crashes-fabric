# 05: Promote to Test

**What to build:** Test carries all four fixes proven in Dev (calendar sort and ISO date; the referential-integrity flag, or not, per ticket 02's result; Person Age cleansing; Vehicle Model Year cleansing). Rows already loaded in Test are remediated: the Person Age backfill runs, and both vehicle tables are rebuilt. No table schema changes, so no drop-first is needed, but row counts are checked after the deploy to catch a repeat of the 2026-09-28 Test wipe.

**Blocked by:** 01, 02, 03, 04

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Capture Test row counts for every Warehouse table before the deploy | CC | Counts recorded in Comments | todo |
| 2 | Deploy Dev → Test via deployment pipeline `dp_NYC_VehicleCrashes` | Pat | Deployment succeeds | todo |
| 3 | Check Test row counts survived the deploy | CC | Every table matches step 1 | todo |
| 4 | Capture Test pre-drop counts (`/dax-smoke-test` check 1) and the Person Age baseline (blank count, expected increase) | CC | Recorded in Comments | todo |
| 5 | Run the Person Age backfill in the Test Warehouse SQL editor, then empty `dim_vehicle` and `fact_crash_vehicle` (scripts supplied by CC) | Pat | Backfill reports rows affected; both vehicle tables report 0 rows | todo |
| 6 | Run the stage load pipeline in Test; then `refresh_semantic_model` | CC | Pipeline succeeds; refresh completes | todo |
| 7 | Profile checks: Month/Day of Week sort-by and Date format; the referential-integrity result matches Dev; Person Age range and zero-by-role checks; Model Year range check; fact counts equal pre-drop | CC | All hold | todo |
| 8 | Run the full `/dax-smoke-test` on Test | CC | Checks 1–6 pass | todo |
