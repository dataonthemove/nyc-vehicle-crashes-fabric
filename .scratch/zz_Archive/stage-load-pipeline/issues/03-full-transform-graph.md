# 03: Full Transform graph

**What to build:** All twelve Transform procedures run as Stored Procedure activities in the spec's three waves. 
- Wave 1: the seven independent dimensions, in parallel. 
- Wave 2: the factor group dimension, after collision. 
- Wave 3: the three facts and the bridge, in parallel, each after every dimension it references. 
- Refresh depends on all of Wave 3. 


A Stage load now produces a complete star.

**Blocked by:** 02

**Status:** done (2026-09-23)

- [x] Every edge is a Succeeded dependency; no On failure or On completion branches
- [x] If adding dependencies times out, collapsing a wave into a barrier is acceptable. Note it in the ticket.
- [x] A manual run ends Succeeded (spec Test 1)
- [x] Warehouse fact and bridge counts are non-zero with no duplicate business keys, checked via Spark on OneLake paths
- [x] `/dax-smoke-test` passes against the Dev model

## Authoring notes (2026-09-23)

The graph was authored as local JSON, not via `add_activity_dependency`. There was no timeout, so no wave was collapsed into a barrier.
Upstream sets were taken from each procedure's joins:

- `fact_crashes` ← collision, factor_group, location, date
- `fact_persons` ← collision, person, date
- `fact_crash_vehicle` ← collision, vehicle, damage, date
- `bridge_crash_factor` ← collision, factor_group, contributing_factor
- `dim_factor_group` ← collision only (reads `dim_collision` alone)

No fact joins `dim_date` (each derives `date_key` from `crash_date`). `Load_dim_date` is still an upstream of every fact, so the truncate-and-reload finishes before any fact that carries a `date_key`.
Every Wave 1 dimension feeds at least one Wave 3 activity, so Refresh transitively waits on all twelve.

## Outcome (2026-09-22 UTC)

- Commit `be9715d`. 
- Before the run, the live Dev graph was checked against the repo and matched (16 activities, same edges and procedure names).
- Run `2c6f52f6-e16e-45cf-930b-d2fdaf4cfae5` Succeeded 23:28:47 → 23:33:18 UTC, and all 16 activities succeeded.
- Ingest ran 23:28:57 → 23:31:58 (Vehicles was last, 181 s). 
- All seven Wave 1 dimensions started at 23:31:59.
- `Load_dim_factor_group` started at 23:32:13, after `Load_dim_collision` ended at 23:32:12. 
- Each Wave 3 activity started after its last
- upstream finished. Refresh ran 23:32:39 → 23:33:15.

This was a warm run. The landed files were unchanged since ticket 02, so every count below matches the counts taken before the run.

| Table | Rows | Duplicate check (Spark, OneLake path) |
|---|---|---|
| fact_crashes | 2,269,187 | 0 duplicate `collision_key` |
| fact_persons | 5,984,110 | equals distinct `nyc_persons.unique_id` |
| fact_crash_vehicle | 4,551,002 | equals distinct `nyc_vehicles.unique_id` |
| bridge_crash_factor | 1,648,599 | 0 duplicate (`factor_group_key`, `factor_key`); 0 factor groups missing from fact_crashes |

`fact_persons` and `fact_crash_vehicle` have no business key column. `person_key`/`vehicle_key` are shared lookup dimensions, and each
row carries a `BIGINT IDENTITY` column. So the duplicate check is row count = distinct source merge key, which shows no fan-out.

`/dax-smoke-test` passed. DAX row counts equal the Warehouse counts for all 12 tables. There are 0 orphan fact rows on all 13 relationships.
Total Crashes is 2,269,187, and Persons Injured is 756,353. One contributing factor filters crashes to 489,682, so the bridge filter works.
In Direct Lake, a DAX `EXCEPT` over the 2.2M `factor_group_key` values fell back to DirectQuery and hit the 1M-row limit, so the bridge
orphan check ran in Spark instead.
