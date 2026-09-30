# 07: Rebuild and validate Dev (human-in-the-loop)

**What to build:** Dev runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 06

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [x] **CC** captures Dev's pre-drop fact counts (ticket 06 step) and records them in Comments
- [x] **Pat** runs only the DROP cells of the DDL notebooks currently in Dev (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [x] **Pat** applies the new definitions: Source Control → Update All (ends the Update All hold)
- [x] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [x] **CC** runs the Dev stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [x] Results recorded in Comments

## Comments
- 2026-09-27 21:06 UTC (CC): Dev pre-drop fact counts (Spark, OneLake path, Warehouse `324e2ac0-…`): `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 — identical to the spec Baseline. Dev still on the old items (22, incl. `04_ETL_dim_collision`, `08_ETL_dim_damage`); Livy session `286dea0a-…` left open for the post-load checks.
- 2026-09-27 (Pat): Ran `01_DDL_Dimensions` Step 1–2 DROP cells only (all 12 old star tables incl. `dim_collision`, `dim_damage`), Source Control → Update All, dropped `etl.usp_load_dim_collision` / `usp_load_dim_damage`.
- 2026-09-27 21:2x UTC (CC): Confirmed via Spark `synapsesql` on `sys.procedures` / `sys.tables`: 12 `etl` procs, none stale; Update All created all 12 new-schema star tables empty (no fallback DDL run needed); `04_ETL_dim_collision` / `08_ETL_dim_damage` notebooks removed. Lakehouse source unchanged pre-load (2,269,187 / 5,984,110 / 4,551,002), so Ingest moved nothing.
- 2026-09-27 (CC): `pl_stage_load_NYC_Crashes` job `9f6f209f-…` Succeeded, 16/16 activities, 21:31–21:35 UTC; then `refresh_semantic_model` Completed. `/dax-smoke-test` — **all six checks PASS**:

  | Check | Result | Detail |
  |---|---|---|
  | 1 Fact counts = pre-drop | PASS | Spark and DAX both 2,269,187 / 5,984,110 / 4,551,002 |
  | 2 Line header keys = crash's | PASS | 0 mismatches on 6 key/fact pairs; 0 lines without a crash; 0 duplicate `collision_id` |
  | 3 No orphaned keys | PASS | 0 null / 0 unmatched on all 15 relationships; 0 duplicate dim keys |
  | 4 Factor groups | PASS | 1 empty-set group, 0 bridge rows on it; 0 duplicate hashes / pairs; 1 Unknown location; 0 duplicate `dim_driver` sets |
  | 5 Bridged factors filter all facts | PASS | 63 of 63 factors, 0 failing |
  | 6 Relationships | PASS | 0 missing/wrong, 0 extra, `dim_collision` absent |

  Post-load dims vs Baseline: `dim_factor_group` 2,269,187 → 1,581 · `bridge_crash_factor` 1,648,599 → 3,610 · `dim_location` 381,068 → 246 · `dim_vehicle` 596,157 → 155,594 · `dim_vehicle_circumstance` 21,430 (was `dim_damage` 4,602 — grew, as expected) · `dim_driver` 670 · `dim_person` 25,990 (unchanged). Update All hold ended; ticket 08 unblocked.
