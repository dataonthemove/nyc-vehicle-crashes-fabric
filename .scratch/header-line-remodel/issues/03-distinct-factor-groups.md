# 03: Factor groups become distinct factor sets

**What to build:** Crashes with the same set of contributing factors share one **factor group**, so `dim_factor_group` and the bridge shrink from millions of rows to the number of distinct sets (D3).

**Blocked by:** 02

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [ ] `dim_factor_group` holds one row per distinct factor set, identified by `factor_set_hash` over the sorted distinct `factor_desc` values (not `factor_key`); its `collision_key` is gone
- [ ] Crashes with no specified factor (null or `Unspecified`) all point at **one** empty-set group with no bridge rows
- [ ] Incremental: a new crash resolves to an existing group by hash; only new groups are added, and the bridge inserts rows only for new groups
- [ ] `fact_crashes` resolves `factor_group_key` by hash; the factor-group load reads the Lakehouse crashes, not `dim_collision`
- [ ] Pipeline: factor group waits on ingest and `dim_contributing_factor`; bridge and `fact_crashes` wait on factor group
- [ ] Semantic model: `factor_set_hash` hidden; bridge cross-filter still `bothDirections`
- [ ] Notebook and item-definition procedures identical, same commit

## Comments
