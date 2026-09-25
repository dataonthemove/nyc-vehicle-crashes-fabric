# 02: Degenerate collision_id and header keys on the line facts

**What to build:** Person and vehicle lines are filtered by every crash-side dimension, because each line carries its crash's header keys (D1, D2). `dim_collision` disappears; `collision_id` is a degenerate dimension on all three facts.

**Blocked by:** 01

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [ ] `dim_collision` and `collision_key` are removed everywhere: DDL, Warehouse item definition, its load notebook and procedure, every join and every incremental `NOT EXISTS` guard (re-keyed to `collision_id`)
- [ ] `fact_crashes`, `fact_persons`, `fact_crash_vehicle` each carry `collision_id`
- [ ] Line facts take `date_key`, `location_key` and `factor_group_key` from `fact_crashes` by `collision_id`; lines with no crash are dropped, as today
- [ ] Stage load pipeline: `Load_dim_collision` removed and the dependency graph rebuilt — line facts wait on `fact_crashes` and their own dims; edited in git, not MCP
- [ ] Semantic model: `dim_collision` table and its 3 relationships gone; `fact_persons` and `fact_crash_vehicle` → `dim_location` and `dim_factor_group` added; `collision_id` SummarizeBy `None`
- [ ] Notebook and item-definition procedures identical, same commit

## Comments
