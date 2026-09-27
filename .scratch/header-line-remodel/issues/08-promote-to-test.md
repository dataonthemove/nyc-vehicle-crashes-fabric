# 08: Rebuild and validate Test (human-in-the-loop)

**What to build:** Test runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 07

**Status:** ready-for-human

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [x] **CC** captures Test's pre-drop fact counts (ticket 06 step) and records them in Comments
- [ ] **Pat** runs only the DROP cells of the DDL notebooks currently in Test (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [ ] **Pat** applies the new definitions: deploy Dev → Test
- [ ] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [ ] **CC** runs the Test stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [ ] Results recorded in Comments

## Comments
- 2026-09-27 22:1x UTC (CC): Test pre-drop fact counts (Spark, OneLake path, Warehouse `c2ce6eed-…`): `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 — identical to Dev and the spec Baseline. Test still on the old 22 items (incl. `04_ETL_dim_collision`, `08_ETL_dim_damage`); Livy session `f5af0601-…` left open for the post-load checks.
