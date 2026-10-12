# 05: Promote to Prod and close

**What to build:** Prod carries the same measure layer as Test, validated the same way, and the spec is closed.

**Blocked by:** 04

**Status:** done (2026-10-12)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Deploy Test → Prod via the deployment pipeline, selecting only the semantic model | Pat | Deployment succeeds; Warehouse not in the deployed set | done |
| 2 | `refresh_semantic_model` on Prod to frame | CC | Refresh completes | done |
| 3 | Metadata check: 38 measures (2 hidden), each with description, format string and display folder; the 10 columns hidden | CC | All hold | done |
| 4 | Re-run the validation queries from tickets 01–03 on Prod | CC | All hold; figures in Comments | done |
| 5 | Run `/dax-smoke-test` on Prod | CC | All checks pass | done |
| 6 | Update the environment reference's last-deploy line; set the spec to `Status: done (date)`; commit | CC | Both updated and committed | done |

## Comments

**2026-10-12 — CC, step 1 check.** Before the deploy, Prod had 0 measures (12 tables). After Pat's
deploy, 38. CC cannot see the deployed set, but check 1 below shows the Prod Warehouse fact tables
untouched (Spark counts equal the model counts, which also equal Test's and Dev's).

**2026-10-12 — CC, steps 2–4.**
- Step 2: `refresh_semantic_model` Completed (refresh `460255456`).
- Step 3: `INFO.VIEW.MEASURES`: 38 measures, all `Valid`, 2 hidden (`First Data Date`,
  `Last Data Date`), 38 with description and display folder. The whole live TMDL
  (`get_semantic_model_definition`) equals git apart from `lineageTag` lines and line order, so all
  38 format strings equal git. One expected exception: `expressions.tmdl` points `Sql.Database` at
  the Prod Warehouse endpoint and ID (the deployment rule's rebinding). `INFO.VIEW.COLUMNS`: the 10
  columns hidden (8 `Fact Crashes` casualty columns, Person Age, Vehicle Occupants), plus the
  technical `dim_factor_group[factor_set_hash]`; Latitude, Longitude, Is Injured and Is Killed visible.
- Step 4: every figure equals Test's and Dev's.
  - `Fact Crashes`, by `Dim Date`[Year]: 15 years, 0 failing (11 base measures vs `COUNTROWS`/`SUMX`/
    `FILTER`, plus `Geocoded Crash %`). Totals 2,269,187 crashes · 3,617 killed · 558,603 injury
    crashes · 3,469 fatal crashes. Helpers equal independent `MINX`/`MAXX` (2012-07-01 → 2026-06-11).
  - Date regressions: 0 years after 2026 with a value. For 2026: `Crashes PY` 36,774 and `Crashes
    Rolling 12M` 85,196, both equal to independent counts. `Crashes YoY %` −0.95%. `Avg Daily Crashes`
    under the rarest bridged factor (4 crashes) = 0.000785 = 4 ÷ 5,094 calendar days.
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

**2026-10-12 — CC, step 5.** `/dax-smoke-test` on Prod: all pass. No rebuild preceded it, so check 1
compared the Spark counts with the model's DAX counts.

| Check | Subject | Result | Offending | Expected vs actual |
|---|---|---|---|---|
| 1 | Fact rows, Spark vs model (3) | PASS | 0 | 2,269,187 · 5,984,110 · 4,551,002 on both sides |
| 2 | Line → header key agreement, duplicate `collision_id` (9) | PASS | 0 | 0 mismatches |
| 3 | Orphaned / null keys on 15 relationships; duplicate dim keys (7) | PASS | 0 | 0 |
| 4 | Factor-group integrity, Unknown location, `dim_driver` uniqueness (7) | PASS | 0 | 1 empty-set group, 1 Unknown |
| 5 | Every bridged factor filters all three facts | PASS | 0 | 63 factors, 0 failing |
| 6 | Relationships match spec | PASS | 0 | 0 missing/wrong, 0 extra, 0 RI off |

**2026-10-12 — CC, step 6.** Environment reference last-deploy line updated (Dev → Test → Prod, all
three stages carry the measures); spec set to `Status: done (2026-10-12)`. Ticket and spec closed;
archiving to `.scratch/_Archive/` is left to `/closeout_pat`.
