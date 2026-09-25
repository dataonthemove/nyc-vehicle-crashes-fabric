# 07: Rebuild and validate Dev (human-in-the-loop)

**What to build:** Dev runs the remodelled star, loaded and passing every acceptance check, via the spec's Risks sequence.

**Blocked by:** 06

**Status:** ready-for-human

> Spec: `.scratch/header-line-remodel/spec.md` → Risks, Acceptance checks.

- [ ] **CC** captures Dev's pre-drop fact counts (ticket 06 step) and records them in Comments
- [ ] **Pat** runs only the DROP cells of the DDL notebooks currently in Dev (star tables only; `dbo.etl_watermark` and procedures untouched; Warehouse item not deleted)
- [ ] **Pat** applies the new definitions: Source Control → Update All (ends the Update All hold)
- [ ] **Pat** drops any stale `etl` procedures (`usp_load_dim_collision`, `usp_load_dim_damage`); **CC** confirms via MCP listing
- [ ] **CC** runs the Dev stage load, then `refresh_semantic_model`, then `/dax-smoke-test` — all six checks pass
- [ ] Results recorded in Comments

## Comments
