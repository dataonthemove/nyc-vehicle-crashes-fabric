# 10: Documentation refresh

**What to build:** Project docs describe the remodelled star as built in all three stages.

**Blocked by:** 09

**Status:** done

- [x] Semantic model doc describes the new tables and relationships, and the absence of measures
- [x] Environment reference drops `dim_collision` and its notebook, adds `dim_driver` and its notebook with **physical** IDs per stage (via MCP, never from repo files), applies the D16 rename, corrects the notebook count
- [x] Capacity-reassignment runbook baseline counts refreshed from the post-rebuild counts
- [x] Spec status set to done

## Comments
- 2026-09-28 (CC): Done. `SEMANTIC_MODEL.md` rewritten for the header/line star: 12 tables, 15 relationships with a dimension × fact matrix, no measures, no roles. Its diagram `img/SemanticModel.png` predates the remodel and is flagged as stale in the doc; regenerating it is Pat's call. `environment-reference.md` updated from MCP `list_items` / `list_folders`, run on all three stages today, with no IDs taken from repo files: `04_ETL_dim_collision` removed, `07b_ETL_dim_driver` added, D16 rename applied, notebook count still 16 in Dev (−04, +07b), per-stage remodel notebook table, reports and `Borough_Reader` removed, `6_Orchestration` folder added, baseline counts replaced. Runbook baseline refreshed to the ticket 07–09 post-rebuild counts. Spec status → done.
  **Finding (Pat):** `07b_ETL_dim_driver` exists only in Dev (`1e560818-…`). The deploys to Test and Prod did not carry it, so those stages hold 20 items against Dev's 21. Loads are unaffected, because the pipeline calls `etl.usp_load_dim_driver` from the Warehouse item, but the stages differ until the notebook is deployed Dev → Test → Prod. The stale `04_ETL_dim_collision` is now gone from Test and Prod. Minor: the live `05_ETL_dim_location` item description still says "borough/zip/lat/long". It lives in `.platform`, so fix it in git.
