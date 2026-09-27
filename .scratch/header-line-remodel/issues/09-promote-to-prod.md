# 09: Rebuild and validate Prod (human-in-the-loop)

**What to build:** Prod runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 08

**Status:** ready-for-human

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [x] **CC** captures Prod's pre-drop fact counts (ticket 06 step) and records them in Comments
- [ ] **Pat** runs only the DROP cells of the DDL notebooks currently in Prod (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [ ] **Pat** applies the new definitions: deploy Test → Prod
- [ ] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [ ] **CC** runs the Prod stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [ ] Results recorded in Comments

## Comments
- 2026-09-27 22:4x UTC (CC): Prod pre-drop fact counts (Spark, OneLake path, Warehouse `a72a40c8-…`): `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 — identical to Dev, Test and the spec Baseline. Prod still on the old item set (incl. `04_ETL_dim_collision` `3524ee23-…`, `08_ETL_dim_damage`). Per ticket 08: the deploy will rename `08_…` in place but leave `04_ETL_dim_collision` behind — Pat to delete it in the Fabric UI. Livy session `be48ba89-…` left open for the post-load checks.
