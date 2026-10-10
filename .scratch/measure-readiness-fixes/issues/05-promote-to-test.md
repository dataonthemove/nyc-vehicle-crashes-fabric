# 05: Promote to Test

**What to build:** Test carries all four fixes proven in Dev (calendar sort and ISO date; the referential-integrity flag, or not, per ticket 02's result; Person Age cleansing; Vehicle Model Year cleansing). Rows already loaded in Test are remediated: the Person Age backfill runs, and both vehicle tables are rebuilt. No table schema changes, so no drop-first is needed, but row counts are checked after the deploy to catch a repeat of the 2026-09-28 Test wipe.

**Blocked by:** 01, 02, 03, 04

**Status:** closed

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Capture Test row counts for every Warehouse table before the deploy | CC | Counts recorded in Comments | done |
| 2 | Deploy Dev → Test via deployment pipeline `dp_NYC_VehicleCrashes` | Pat | Deployment succeeds | done |
| 3 | Check Test row counts survived the deploy | CC | Every table matches step 1 | done |
| 4 | Capture Test pre-drop counts (`/dax-smoke-test` check 1) and the Person Age baseline (blank count, expected increase) | CC | Recorded in Comments | done |
| 5 | Run the Person Age backfill in the Test Warehouse SQL editor, then empty `dim_vehicle` and `fact_crash_vehicle` (scripts supplied by CC) | Pat | Backfill reports rows affected; both vehicle tables report 0 rows | done |
| 6 | ~~Run the stage load pipeline in Test~~ Pat runs the two vehicle procedures directly (see Comments); then `refresh_semantic_model` | Pat + CC | Procedures load; refresh completes | done |
| 7 | Profile checks: Month/Day of Week sort-by and Date format; the referential-integrity result matches Dev; Person Age range and zero-by-role checks; Model Year range check; fact counts equal pre-drop | CC | All hold | done |
| 8 | Run the full `/dax-smoke-test` on Test | CC | Checks 1–6 pass | done |

## Comments

- **2026-10-10 — Plan change (Pat).** Step 6 does not run the stage load pipeline: its Ingest
  activities fail on duplicate keys across landing files (`.scratch/ingest-duplicate-keys/issue.md`),
  as they did in Dev. Pat runs `etl.usp_load_dim_vehicle` then `etl.usp_load_fact_crash_vehicle`
  directly after emptying the two tables; CC then runs `refresh_semantic_model`.
- **2026-10-10 ~20:50 UTC — Steps 1 and 4: Test before deploy (Spark).** Warehouse: `bridge_crash_factor` 3,610 ·
  `dim_contributing_factor` 66 · `dim_date` 6,940 · `dim_driver` 670 · `dim_factor_group` 1,581 ·
  `dim_location` 246 · `dim_person` 25,990 · `dim_vehicle` 155,594 · `dim_vehicle_circumstance` 21,430 ·
  `etl_watermark` 0 · `fact_crash_vehicle` 4,551,002 · `fact_crashes` 2,269,187 · `fact_persons` 5,984,110.
  Lakehouse `nyc_crashes` / `nyc_persons` / `nyc_vehicles` = 2,269,187 / 5,984,110 / 4,551,002.
  Person Age baseline: blank 675,911, min −999, max 9999; rows to null 535,179 → **expected blank
  after backfill 1,211,090**. `dim_vehicle` years 1000–20063. All identical to Dev before its fixes,
  so Dev's expectations apply: `dim_vehicle` → 154,057, `fact_crash_vehicle` 4,551,002.
- **2026-10-10 — Steps 2–3.** Pat deployed Dev → Test. All 13 Warehouse tables match step 1 exactly;
  no table added or removed. `sys.sql_modules` in Test carries the new rules: the vehicle-year
  expression twice in `usp_load_dim_vehicle` and once in `usp_load_fact_crash_vehicle`; the
  Passenger/Pedestrian age rule in `usp_load_fact_persons`.
- **2026-10-10 ~20:55 UTC — Step 5 first attempt ran in Dev by mistake.** The backfill found nothing to change
  (rows_to_null 0; blank 1,211,090), and the vehicle rebuild reproduced Dev's counts (154,057 / 4,551,002)
  with regenerated `vehicle_key` values. Dev model refreshed (459797764). Test confirmed untouched
  (Spark: `dim_vehicle` 155,594, blank ages 675,911); Test refresh 459797322 was on old data. Rerun in Test.
- **2026-10-10 ~21:00 UTC — Steps 5–6 (Test).** Backfill: rows_to_null 535,179; after: rows 5,984,110, blank 1,211,090,
  min 0, max 110, non-infant zeros 0. Vehicle rebuild: `dim_vehicle` 154,057, `fact_crash_vehicle`
  4,551,002. `refresh_semantic_model` Completed (459799625). All exactly as predicted from Dev.
- **2026-10-10 — Steps 7–8 (Test).** DAX: Month → sort by Month Number, Day of Week → Day of Week Number,
  Date `yyyy-mm-dd`, IsKey true; Person Age min 0 / max 110 / blank 1,211,090 / non-infant zeros 0;
  Vehicle Model Year 1900–2027, below 1900 0, above crash year + 1 0, blank-year vehicles 1,984,832,
  classic 1,019; fact counts = pre-drop (2,269,187 / 5,984,110 / 4,551,002). `/dax-smoke-test`: Spark
  checks 1–4 43/43 PASS; check 5 PASS (63 factors); check 6 PASS (`ri_off` 0, matching Dev). Closed.
