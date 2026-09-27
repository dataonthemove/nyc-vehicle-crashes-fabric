# 08: Rebuild and validate Test (human-in-the-loop)

**What to build:** Test runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 07

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [x] **CC** captures Test's pre-drop fact counts (ticket 06 step) and records them in Comments
- [x] **Pat** runs only the DROP cells of the DDL notebooks currently in Test (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [x] **Pat** applies the new definitions: deploy Dev → Test
- [x] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [x] **CC** runs the Test stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [x] Results recorded in Comments

## Comments
- 2026-09-27 22:1x UTC (CC): Test pre-drop fact counts (Spark, OneLake path, Warehouse `c2ce6eed-…`): `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 — identical to Dev and the spec Baseline. Test still on the old 22 items (incl. `04_ETL_dim_collision`, `08_ETL_dim_damage`); Livy session `f5af0601-…` left open for the post-load checks.
- 2026-09-27 (Pat): Ran `01_DDL_Dimensions` DROP cells only, deployed Dev → Test, dropped `etl.usp_load_dim_collision` / `usp_load_dim_damage`.
- 2026-09-27 22:2x UTC (CC): Confirmed via Spark `synapsesql`: 12 `etl` procs, none stale; the deploy created all 12 new-schema star tables, all empty (no fallback DDL needed); `vl_NYC_Crashes` active value set = `Test` (Fabric REST). The deploy paired notebooks by logical ID: `08_ETL_dim_damage` was **renamed in place** to `08_ETL_dim_vehicle_circumstance`, but **`04_ETL_dim_collision` (`a53a86fa-…`) is still in Test** — a deploy does not delete items removed from the source stage. It's not in the pipeline, so it's harmless, but it's stale: Pat to delete it in the Fabric UI (expect the same in Prod, ticket 09).
- 2026-09-27 (CC): `pl_stage_load_NYC_Crashes` job `85448133-…` 22:28–22:32 UTC: Ingest ×3 and all 12 SP activities Succeeded; **`Refresh_Semantic_Model` Failed** — Direct Lake auto-framing ran mid-load, and the enhanced refresh then hit `ParquetStatusException … 404 BlobNotFound` on parquet files the Warehouse had already replaced. Transient: framing at 22:32:09 completed, and a manual `refresh_semantic_model` at 22:32:45 Completed. Not seen in Dev; if it recurs in Prod, same remedy. `/dax-smoke-test` — **all six checks PASS**:

  | Check | Result | Detail |
  |---|---|---|
  | 1 Fact counts = pre-drop | PASS | Spark and DAX both 2,269,187 / 5,984,110 / 4,551,002 |
  | 2 Line header keys = crash's | PASS | 0 mismatches on 6 key/fact pairs; 0 lines without a crash; 0 duplicate `collision_id` |
  | 3 No orphaned keys | PASS | 0 null / 0 unmatched on all 15 relationships; 0 duplicate dim keys |
  | 4 Factor groups | PASS | 1 empty-set group, 0 bridge rows on it; 0 duplicate hashes / pairs; 1 Unknown location; 0 duplicate `dim_driver` sets |
  | 5 Bridged factors filter all facts | PASS | 63 of 63 factors, 0 failing |
  | 6 Relationships | PASS | 0 missing/wrong, 0 extra, `dim_collision` absent |

  Dims identical to Dev: `dim_factor_group` 1,581 · `bridge_crash_factor` 3,610 · `dim_location` 246 · `dim_vehicle` 155,594 · `dim_vehicle_circumstance` 21,430 · `dim_driver` 670 · `dim_person` 25,990 · `dim_contributing_factor` 66 · `dim_date` 6,940. Ticket 09 unblocked.
