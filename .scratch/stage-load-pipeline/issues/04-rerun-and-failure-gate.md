# 04: Rerun safety and failure gate

**What to build:** Evidence that the Stage load is safe to rerun and never refreshes a half-loaded star.

**Blocked by:** 03

**Status:** ready-for-agent

- [x] Spec Test 2: a second run with no new landed files succeeds, and every Delta and Warehouse count is unchanged
- [ ] Spec Test 3: with one Transform activity forced to fail in a throwaway branch workspace (never Dev), the run is Failed and Refresh did not execute
- [ ] The failing activity is identifiable from the Monitor hub run history
- [ ] The throwaway branch and workspace are cleaned up (CLAUDE.md SDLC rule 10)

## Test 2 outcome: idempotent rerun (2026-09-23 UTC)

- Before the run: the landed files were unchanged since 2026-09-10 (`list_lakehouse_files` on landing `Files/raw`), and the live Dev graph matched the repo (16 activities, same edges, procedures and parameters).
- Run `3a09367b-6dac-4acf-9f45-7007c4941bd7` Succeeded 01:06:14 → 01:09:49 UTC. All 16 activities succeeded, and Refresh ran last (01:09:08 → 01:09:46).
- Counts were taken via Spark on OneLake paths immediately before and after the run. All 15 tables are unchanged:

| Table | Rows (before = after) | Delta version before → after |
|---|---|---|
| nyc_crashes | 2,269,187 | 7 → 8 (MERGE, no net rows) |
| nyc_persons | 5,984,110 | 5 → 6 (MERGE, no net rows) |
| nyc_vehicles | 4,551,002 | 5 → 6 (MERGE, no net rows) |
| dim_date | 6,940 | 5484 → 5486 (truncate + reload) |
| dim_collision · dim_factor_group · fact_crashes | 2,269,187 each | unchanged |
| fact_persons | 5,984,110 | unchanged |
| fact_crash_vehicle | 4,551,002 | unchanged |
| bridge_crash_factor | 1,648,599 | unchanged |
| dim_location · dim_vehicle · dim_damage · dim_person · dim_contributing_factor | 381,068 · 596,157 · 4,602 · 25,990 · 66 | unchanged |

- Each Delta MERGE commits a new version but adds no rows. Every insert-only Transform procedure wrote no commit at all (its Warehouse table version is unchanged). The only other write is `dim_date`'s truncate and reload.
- There are still 0 duplicate `collision_key` in fact_crashes and 0 duplicate (`factor_group_key`, `factor_key`) pairs in the bridge.
