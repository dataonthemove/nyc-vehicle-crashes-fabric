# 04: Rerun safety and failure gate

**What to build:** Evidence that the Stage load is safe to rerun and never refreshes a half-loaded star.

**Blocked by:** 03

**Status:** done (2026-09-23)

- [x] Spec Test 2: a second run with no new landed files succeeds, and every Delta and Warehouse count is unchanged
- [x] Spec Test 3: with one Transform activity forced to fail in a throwaway branch workspace (never Dev), the run is Failed and Refresh did not execute
- [x] The failing activity is identifiable from the Monitor hub run history
- [x] The throwaway branch and workspace are cleaned up (CLAUDE.md SDLC rule 10)

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

## Test 3 outcome: failure gate (2026-09-23 UTC)

Setup: Fabric branch-out from Dev created workspace `2_NYC_VehicleCrashes_failgate` (`468f2064-1fe9-4935-b9d5-091fce6fac93`) and branch `feature/stage-load-failure-gate`.
The forced failure was a pipeline-JSON change on the branch only: `Load_bridge_crash_factor` → `[etl].[usp_load_bridge_crash_factor_FORCE_FAIL]`, which doesn't exist. No procedure was renamed in any Warehouse.
The bridge is in Wave 3, so the test shows that one late failure among succeeding siblings still holds back Refresh.

**Result: run `8760b5dc-6e59-4426-9679-7bf8acdddf72` Failed (02:19:42 → 02:22:51).**
- There were 15 activity runs. 14 Succeeded: 3 Ingest, 7 Wave 1 dimensions, factor group, and the facts fact_crashes, fact_persons and fact_crash_vehicle.
- `Load_bridge_crash_factor` Failed: "Could not find stored procedure 'etl.usp_load_bridge_crash_factor_FORCE_FAIL'".
- `Refresh_Semantic_Model` has no activity run. It never executed.
- The run-level `failure_reason` names the activity: "Operation on target Load_bridge_crash_factor failed: …". The same text shows in the Monitor hub.

### Branch-out does not give an isolated workspace

It took four runs to reach a clean result. Each earlier run exposed a binding that branch-out leaves pointing at Dev. The gate held every time: every run was Failed, and Refresh never ran.

| Run | Failure | Cause |
|---|---|---|
| `f7e462a5` | All 7 Wave 1 procs: "database was not found" | The SP activity's `linkedService.endpoint` is a literal Dev TDS host. Branch-out rehydrated `artifactId` to the branch Warehouse but not `endpoint`, so the host and database didn't match. The fix was to repoint the endpoint on the branch. |
| `4c7361a1`, `59173fc1` | Wave 1 dims: `Invalid object name 'NYC_VehicleCrashes_Lakehouse.dbo.nyc_*'` (only `dim_date` succeeded) | `nb_cdc_to_delta`'s `default_lakehouse` META is Dev's physical ID, and branch-out doesn't rebind it. **The branch's Ingest wrote to Dev's Lakehouse** (runs `f7e462a5`, `4c7361a1`, `59173fc1`). The branch Lakehouse stayed empty. The fix was to repoint the notebook META on the branch. |
| `10397766` | Bridge (intended), plus person/vehicle/damage dims | This was the first run that created the branch Delta tables. The SQL endpoint hadn't synced `nyc_persons`/`nyc_vehicles` yet. A metadata refresh plus a warm rerun cleared it. |

**The Dev side effect was checked:** Spark on Dev's Lakehouse shows the three stray MERGEs per `nyc_*` table as 0 inserted, 0 deleted, and all rows updated. All three tables are still at the Test 2 counts (2,269,187 / 5,984,110 / 4,551,002), with distinct keys equal to row count.
Dev's Warehouse was never touched. The branch's SP activities either failed to connect or ran against the branch Warehouse.

The `endpoint` and notebook-binding findings feed ticket 06. See the note there.

## Cleanup (2026-09-23)

- Pat confirmed in the Monitor hub that `Load_bridge_crash_factor` is the failed activity and Refresh did not run.
- Branch `feature/stage-load-failure-gate` is deleted in ADO and locally (`git fetch --prune` confirms).
- Workspace `2_NYC_VehicleCrashes_failgate` is removed; MCP returns `WORKSPACE_NOT_FOUND`. None of the branch commits reached main.
