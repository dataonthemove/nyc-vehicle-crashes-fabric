# 06: Promote to Prod

**What to build:** Prod carries all four fixes proven in Test, with rows already loaded remediated the same way: the Person Age backfill runs, and both vehicle tables are rebuilt. Row counts are checked after the deploy. Once this ticket is done, the measure layer can start from a clean model in every stage.

**Blocked by:** 05

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Capture Prod row counts for every Warehouse table before the deploy | CC | Counts recorded in Comments | todo |
| 2 | Deploy Test → Prod via deployment pipeline `dp_NYC_VehicleCrashes` | Pat | Deployment succeeds | todo |
| 3 | Check Prod row counts survived the deploy | CC | Every table matches step 1 | todo |
| 4 | Capture Prod pre-drop counts (`/dax-smoke-test` check 1) and the Person Age baseline (blank count, expected increase) | CC | Recorded in Comments | todo |
| 5 | Run the Person Age backfill in the Prod Warehouse SQL editor, then empty `dim_vehicle` and `fact_crash_vehicle` (scripts supplied by CC) | Pat | Backfill reports rows affected; both vehicle tables report 0 rows | todo |
| 6 | Run the stage load pipeline in Prod; then `refresh_semantic_model` | CC | Pipeline succeeds; refresh completes | todo |
| 7 | Profile checks: Month/Day of Week sort-by and Date format; the referential-integrity result matches Dev; Person Age range and zero-by-role checks; Model Year range check; fact counts equal pre-drop | CC | All hold | todo |
| 8 | Run the full `/dax-smoke-test` on Prod | CC | Checks 1–6 pass | todo |
