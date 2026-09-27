# 03: Factor groups become distinct factor sets

**What to build:** Crashes with the same set of contributing factors share one **factor group**, so `dim_factor_group` and the bridge shrink from millions of rows to the number of distinct sets (D3).

**Blocked by:** 02

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] `dim_factor_group` holds one row per distinct factor set, identified by `factor_set_hash` over the sorted distinct `factor_desc` values (not `factor_key`); its `collision_key` is gone
- [x] Crashes with no specified factor (null or `Unspecified`) all point at **one** empty-set group with no bridge rows
- [x] Incremental: a new crash resolves to an existing group by hash; only new groups are added, and the bridge inserts rows only for new groups
- [x] `fact_crashes` resolves `factor_group_key` by hash; the factor-group load reads the Lakehouse crashes, not `dim_collision`
- [x] Pipeline: factor group waits on ingest and `dim_contributing_factor`; bridge and `fact_crashes` wait on factor group
- [x] Semantic model: `factor_set_hash` hidden; bridge cross-filter still `bothDirections`
- [x] Notebook and item-definition procedures identical, same commit

## Comments
- 2026-09-27 (CC): implemented, unsynced (Update All held until 07). `dim_factor_group` = `factor_group_key` + `factor_set_hash VARCHAR(64)` (SHA-256 hex of the sorted distinct specified `factor_desc` values, `|`-delimited; empty set hashes `''`). The same `crash_factor` / `crash_factor_set` CTEs sit in `usp_load_dim_factor_group`, `usp_load_bridge_crash_factor` and `usp_load_fact_crashes` (verified byte-identical); bridge is `SELECT DISTINCT` group × factor, new groups only. Pipeline: `Load_dim_factor_group` now also waits on `Load_dim_contributing_factor`. TMDL: `collision_id` → hidden `factor_set_hash`. All 11 procs identical notebook vs item definition. Not run against Fabric — HASHBYTES / STRING_AGG WITHIN GROUP / CONVERT style 2 are first proven in 07.
- **For 06/07:** (1) `'Unspecified'` match is case-sensitive (BIN2 collation) — query the source for other casings before trusting acceptance 4; (2) each of the three procs rescans and rehashes every Lakehouse crash per run — watch load time; (3) if the hash CTE triplication bites, fold it into one `etl` view (review suggestion, not done: adds a Warehouse object outside this spec).
