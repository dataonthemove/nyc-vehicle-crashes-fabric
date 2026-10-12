# 04: Promote to Test

**What to build:** Test carries the full measure layer proven in Dev: 38 measures (2 of them hidden) and the 10 hidden raw columns. Only the semantic model is deployed. The Warehouse is deselected, so the deploy puts no table at risk.

**Blocked by:** 01, 02, 03

**Status:** done (2026-10-12)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Deploy Dev → Test via the deployment pipeline, selecting only the semantic model | Pat | Deployment succeeds; Warehouse not in the deployed set | done |
| 2 | `refresh_semantic_model` on Test to frame | CC | Refresh completes | done |
| 3 | Metadata check: `INFO.VIEW.MEASURES` shows 38 measures (2 hidden), each with description, format string and display folder; `INFO.VIEW.COLUMNS` shows the 10 columns hidden | CC | All hold | done |
| 4 | Re-run the validation queries from tickets 01–03 on Test: base equality, date, child-casualty, denominator and guard regressions | CC | All hold; figures in Comments | done |
| 5 | Run `/dax-smoke-test` on Test | CC | All checks pass | done |

## Comments

**2026-10-12 — CC, step 1 check.** Before the deploy, Test had 0 measures (12 tables). After Pat's
deploy, 38. CC cannot see the deployed set, but check 1 below shows the Test Warehouse fact tables
untouched (Spark counts equal the pre-deploy model counts, which also equal Dev's).

**2026-10-12 — CC, steps 2–4.**
- Step 2: `refresh_semantic_model` Completed (refresh `460250453`).
- Step 3: `INFO.VIEW.MEASURES`: 38 measures, 0 not `Valid`, 2 hidden (the `Helpers`), 38 with
  description and display folder. Format strings from the live TMDL (`get_semantic_model_definition`;
  `INFO.VIEW.MEASURES` has no format column): 38 of 38, all equal git. The whole live TMDL (12 tables
  plus relationships) equals git, except for `lineageTag` lines and line order. `INFO.VIEW.COLUMNS`:
  the 10 columns hidden (8 `Fact Crashes` casualty columns, Person Age, Vehicle Occupants); Latitude,
  Longitude, Is Injured and Is Killed visible.
- Step 4: every figure equals Dev's.
  - `Fact Crashes`, by `Dim Date`[Year]: 15 years, 0 failing (11 base measures vs `COUNTROWS`/`SUMX`/
    `FILTER`, plus `Geocoded Crash %`). Totals 2,269,187 crashes · 3,617 killed · 558,603 injury
    crashes · 3,469 fatal crashes. Helpers equal independent `MINX`/`MAXX` (2012-07-01 → 2026-06-11).
  - Date regressions: 0 years after 2026 with a value. For 2026: `Crashes PY` 36,774 and `Crashes
    Rolling 12M` 85,196, both equal to independent counts. `Crashes YoY %` −0.95%. `Avg Daily Crashes`
    under factor `70` (4 crashes) = 0.000785 = 4 ÷ calendar days.
  - `Fact Crash Persons`, by year: 15 years, 0 failing (records, involved, injured, killed,
    `Child Casualties (<18)`, `Average Age`, `Ejection Rate %` vs a known-status denominator). Totals
    5,984,110 · 3,376,735 · 756,072 · 3,636. Child 2012 3,185, all years 74,365. Ejection 2025 2.9%
    over 153,084 known. Average Age 40.08 and of killed 47.17. Person Fatality Rate 0.11%.
  - `Fact Crash Vehicles`, by year: 15 years, 0 failing (vehicles, occupants, vehicles with data,
    `Unlicensed Driver %` vs a Licensed/Unlicensed/Permit denominator). 4,551,002 vehicles ·
    3,118,066 occupants · 1.15 per vehicle · 59.8% coverage · unlicensed 2.1% (2025: 3.1%) · vehicle
    age 6.76 (2026: 8.12).
  - Guard: `Avg Vehicles per Crash` is BLANK for all 2,168 Vehicle Types. By Borough it equals the
    independent ratio in all 6 (total 2.01).

**2026-10-12 — CC, step 5.** `/dax-smoke-test` on Test: all pass. No rebuild preceded it, so check 1
compared the Spark counts with the model's DAX counts.

| Check | Subject | Result | Offending | Expected vs actual |
|---|---|---|---|---|
| 1 | Fact rows, Spark vs model (3) | PASS | 0 | 2,269,187 · 5,984,110 · 4,551,002 on both sides |
| 2 | Line → header key agreement, duplicate `collision_id` (9) | PASS | 0 | 0 mismatches |
| 3 | Orphaned / null keys on 15 relationships; duplicate dim keys (7) | PASS | 0 | 0 |
| 4 | Factor-group integrity, Unknown location, `dim_driver` uniqueness (7) | PASS | 0 | 1 empty-set group, 1 Unknown |
| 5 | Every bridged factor filters all three facts | PASS | 0 | 63 factors, 0 failing |
| 6 | Relationships match spec | PASS | 0 | 0 missing/wrong, 0 extra, 0 RI off |

Ticket closed. Next: ticket 05 (promote to Prod).
