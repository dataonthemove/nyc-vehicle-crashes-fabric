# 09: Rebuild and validate Prod (human-in-the-loop)

**What to build:** Prod runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 08

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [x] **CC** captures Prod's pre-drop fact counts (ticket 06 step) and records them in Comments
- [x] **Pat** runs only the DROP cells of the DDL notebooks currently in Prod (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [x] **Pat** applies the new definitions: deploy Test → Prod
- [x] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [x] **CC** runs the Prod stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [x] Results recorded in Comments

## Comments
- 2026-09-27 22:4x UTC (CC): Prod pre-drop fact counts (Spark, OneLake path, Warehouse `a72a40c8-…`): `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 — identical to Dev, Test and the spec Baseline. Prod still on the old item set (incl. `04_ETL_dim_collision` `3524ee23-…`, `08_ETL_dim_damage`). Per ticket 08: the deploy will rename `08_…` in place but leave `04_ETL_dim_collision` behind — Pat to delete it in the Fabric UI. Livy session `be48ba89-…` left open for the post-load checks.
- 2026-09-27 (Pat): Deploy Test → Prod **failed twice** (ops `1f0ab174-…` 22:46, `3a5d5e6c-…` 22:51 UTC): Warehouse import `DmsImportDatabaseException` — `ALTER PROCEDURE etl.usp_load_bridge_crash_factor` hit `Invalid column name 'factor_set_hash'`, because the old `dim_factor_group` was still in place. Pat then ran the DROP cells; redeploy `7bc133aa-…` 23:13–23:15 UTC **Succeeded**. Lesson: the Warehouse import validates procedures against live tables, so DROP must precede the deploy.
- 2026-09-27 23:2x UTC (CC): Confirmed via Spark `synapsesql`: 12 `etl` procs, none stale; `vl_NYC_Crashes` active value set = `Prod`; `dbo.etl_watermark` untouched (Delta history: v0 only, 2026-09-21; 0 rows, as before). **Unlike Test, the deploy created no star tables** — `dbo` held only `etl_watermark`. Cause unknown. Fallback: CC ran `01_DDL_Dimensions` (job `2e5ca522-…`) then `02_DDL_Facts_Bridges` (job `d5abe15d-…`) in full — both Completed; all 12 star tables now present. `04_ETL_dim_collision` (`3524ee23-…`) still in Prod — Pat to delete.
- 2026-09-27 (CC): `pl_stage_load_NYC_Crashes` job `f9a7cd2a-…` 23:28–23:33 UTC **Completed** (incl. its Refresh activity — no framing race this time); manual `refresh_semantic_model` 23:33:30 Completed. `/dax-smoke-test` — **all six checks PASS** (Spark 42 of 42):

  | Check | Result | Detail |
  |---|---|---|
  | 1 Fact counts = pre-drop | PASS | Spark and DAX both 2,269,187 / 5,984,110 / 4,551,002 |
  | 2 Line header keys = crash's | PASS | 0 mismatches on 6 key/fact pairs; 0 lines without a crash; 0 duplicate `collision_id` |
  | 3 No orphaned keys | PASS | 0 null / 0 unmatched on all 15 relationships; 0 duplicate dim keys |
  | 4 Factor groups | PASS | 1 empty-set group, 0 bridge rows on it; 0 duplicate hashes / pairs; 1 Unknown location; 0 duplicate `dim_driver` sets |
  | 5 Bridged factors filter all facts | PASS | 63 of 63 factors, 0 failing |
  | 6 Relationships | PASS | 0 missing/wrong, 0 extra, `dim_collision` absent |

  Dims identical to Dev and Test: `dim_factor_group` 1,581 · `bridge_crash_factor` 3,610 · `dim_location` 246 · `dim_vehicle` 155,594 · `dim_vehicle_circumstance` 21,430 · `dim_driver` 670 · `dim_person` 25,990 · `dim_contributing_factor` 66 · `dim_date` 6,940. Open follow-up (Pat): delete stale `04_ETL_dim_collision` from Test and Prod.
