# 06: Promote to Prod

**What to build:** Prod carries all four fixes proven in Test, with rows already loaded remediated the same way: the Person Age backfill runs, and both vehicle tables are rebuilt. Row counts are checked after the deploy. Once this ticket is done, the measure layer can start from a clean model in every stage.

**Blocked by:** 05

**Status:** closed

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Capture Prod row counts for every Warehouse table before the deploy | CC | Counts recorded in Comments | done |
| 2 | Deploy Test → Prod via deployment pipeline `dp_NYC_VehicleCrashes` | Pat | Deployment succeeds | done |
| 3 | Check Prod row counts survived the deploy | CC | Every table matches step 1 | done |
| 4 | Capture Prod pre-drop counts (`/dax-smoke-test` check 1) and the Person Age baseline (blank count, expected increase) | CC | Recorded in Comments | done |
| 5 | Run the Person Age backfill in the Prod Warehouse SQL editor, then empty `dim_vehicle` and `fact_crash_vehicle` (scripts supplied by CC) | Pat | Backfill reports rows affected; both vehicle tables report 0 rows | done |
| 6 | Pat runs `etl.usp_load_dim_vehicle` then `etl.usp_load_fact_crash_vehicle` directly (the pipeline's Ingest fails, `.scratch/ingest-duplicate-keys/issue.md`); then CC runs `refresh_semantic_model` | Pat + CC | Procedures load; refresh completes | done |
| 7 | Profile checks: Month/Day of Week sort-by and Date format; the referential-integrity result matches Dev; Person Age range and zero-by-role checks; Model Year range check; fact counts equal pre-drop | CC | All hold | done |
| 8 | Run the full `/dax-smoke-test` on Prod | CC | Checks 1–6 pass | done |

## Comments

- **2026-10-10 ~21:10 UTC — Steps 1 and 4: Prod before deploy (Spark).** Identical to Test before its deploy:
  13 Warehouse tables (`bridge_crash_factor` 3,610 · `dim_contributing_factor` 66 · `dim_date` 6,940 ·
  `dim_driver` 670 · `dim_factor_group` 1,581 · `dim_location` 246 · `dim_person` 25,990 ·
  `dim_vehicle` 155,594 · `dim_vehicle_circumstance` 21,430 · `etl_watermark` 0 ·
  `fact_crash_vehicle` 4,551,002 · `fact_crashes` 2,269,187 · `fact_persons` 5,984,110); Lakehouse
  sources 2,269,187 / 5,984,110 / 4,551,002. Person Age: blank 675,911, rows to null 535,179 →
  expected blank 1,211,090. `dim_vehicle` years 1000–20063 → expected 154,057 rows after rebuild.
- **2026-10-10 — Steps 2–3.** Pat deployed Test → Prod. All 13 Warehouse tables match step 1 exactly;
  no table added or removed. `sys.sql_modules` in Prod carries the vehicle-year expression (2× dim, 1× fact)
  and the Passenger/Pedestrian age rule.
- **2026-10-10 ~21:15 UTC — Step 5 first attempt ran in another stage by mistake** (backfill rows_to_null 0; rebuild
  154,057 / 4,551,002). Prod confirmed untouched by Spark. Dev and Test models refreshed afterwards
  (459803264, 459803257) to re-frame any regenerated `vehicle_key` values.
- **2026-10-10 ~21:20 UTC — Steps 5–6 (Prod).** Backfill: rows_to_null 535,179; after: rows 5,984,110, blank
  1,211,090, min 0, max 110, non-infant zeros 0. Vehicle rebuild: `dim_vehicle` 154,057,
  `fact_crash_vehicle` 4,551,002. `refresh_semantic_model` Completed (459803132).
- **2026-10-10 — Steps 7–8 (Prod).** Identical to Dev and Test: Month/Day of Week sort-by and Date
  `yyyy-mm-dd` (IsKey true); Person Age 0–110, blank 1,211,090, non-infant zeros 0; Vehicle Model Year
  1900–2027, 0 below 1900, 0 above crash year + 1, blank-year vehicles 1,984,832, classic 1,019; fact
  counts = pre-drop. `/dax-smoke-test`: Spark 43/43 PASS; check 5 PASS (63 factors); check 6 PASS
  (`ri_off` 0). Closed — all three stages carry the four fixes.
