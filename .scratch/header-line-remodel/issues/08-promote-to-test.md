# 08: Rebuild and validate Test (human-in-the-loop)

**What to build:** Test runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 07

**Status:** ready-for-human

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [ ] **CC** captures Test's pre-drop fact counts (ticket 06 step) and records them in Comments
- [ ] **Pat** runs only the DROP cells of the DDL notebooks currently in Test (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [ ] **Pat** applies the new definitions: deploy Dev → Test
- [ ] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [ ] **CC** runs the Test stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [ ] Results recorded in Comments

## Comments
