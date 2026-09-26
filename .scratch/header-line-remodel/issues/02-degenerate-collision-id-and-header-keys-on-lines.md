# 02: Degenerate collision_id and header keys on the line facts

**What to build:** Person and vehicle lines are filtered by every crash-side dimension, because each line carries its crash's header keys (D1, D2). `dim_collision` disappears; `collision_id` is a degenerate dimension on all three facts.

**Blocked by:** 01

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] `dim_collision` and `collision_key` are removed everywhere: DDL, Warehouse item definition, its load notebook and procedure, every join and every incremental `NOT EXISTS` guard (re-keyed to `collision_id`)
- [x] `fact_crashes`, `fact_persons`, `fact_crash_vehicle` each carry `collision_id`
- [x] Line facts take `date_key`, `location_key` and `factor_group_key` from `fact_crashes` by `collision_id`; lines with no crash are dropped, as today
- [x] Stage load pipeline: `Load_dim_collision` removed and the dependency graph rebuilt — line facts wait on `fact_crashes` and their own dims; edited in git, not MCP
- [x] Semantic model: `dim_collision` table and its 3 relationships gone; `fact_persons` and `fact_crash_vehicle` → `dim_location` and `dim_factor_group` added; `collision_id` SummarizeBy `None`
- [x] Notebook and item-definition procedures identical, same commit

## Comments
- 2026-09-26 (CC): implemented, unsynced (Update All held until 07). `dim_collision`, `usp_load_dim_collision`, `04_ETL_dim_collision` and the model table + 3 relationships deleted; `collision_id INT` on all three facts; line procs take `date_key`/`location_key`/`factor_group_key` from `fact_crashes` by `collision_id`. `dim_factor_group` temporarily carries `collision_id` in place of `collision_key` (ticket 03 replaces it) and 09b now reads Lakehouse crashes. Pipeline: `Load_dim_collision` removed; factor group waits on `Ingest_Crashes` only (03 adds `dim_contributing_factor`); line facts wait on `Load_fact_crashes` + own dims. 4 of the 5 new relationships added (`dim_driver` is 05). `01_DDL` keeps a legacy `DROP dim_collision` for the Risks step-2 fallback. All 11 procs verified identical notebook vs item definition.
- **For 06/07 — row-count risks (acceptance 1):** (1) line procs no longer filter on the line's own `crash_date` (date comes from the crash), so lines with an unparseable own date now load; (2) "lines with no crash" now means no row in `fact_crashes`, which also excludes crashes with a bad `crash_date` — before, any crash in `dim_collision` sufficed. Net delta not measured. (3) Line procs join `fact_crashes` by `collision_id`, which is not enforced unique (old target `dim_collision` was `DISTINCT`); a duplicate multiplies lines. Add a `COUNT(*) = COUNT(DISTINCT collision_id)` check on `fact_crashes` to 06. (4) Acceptance 3 can't pass before 04: line facts now inherit `location_key = -1`.
- Still referencing `dim_collision`, deferred to 10: `2_dev/4_Model/SEMANTIC_MODEL.md`, `Context/environment-reference.md`, drawio; `Other/sql_scripts/TableChecks_Warehouse.sql` is Pat's.
