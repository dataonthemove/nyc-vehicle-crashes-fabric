# 04: Location slim-down and Unknown location member

**What to build:** `dim_location` becomes a small borough/ZIP dimension with a real **Unknown member**, and crash coordinates live on the crash, so heat maps still work (D8, D15, D14).

**Blocked by:** 03

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] First, measure and record in Comments how many crashes carry today's `location_key = -1`
- [x] `latitude` and `longitude` move from `dim_location` to `fact_crashes`; `dim_location` keeps `borough`, `zip_code`
- [x] The location load inserts an Unknown row (sentinel attributes) if absent; `fact_crashes` resolves unmatched locations to it **by lookup**, never a literal key; no `-1` remains in any load
- [x] Semantic model: `latitude`/`longitude` SummarizeBy `None` with Latitude/Longitude data category
- [x] `CLAUDE.md` SummarizeBy rules gain the latitude/longitude rule
- [x] Notebook and item-definition procedures identical, same commit

## Comments
- 2026-09-27 (CC): **measured in Dev before the change** (Spark, OneLake path): 0 of 2,269,187 crashes carry `location_key = -1`, and 0 orphaned location keys — the old 4-column match always hit. But 691,375 source crashes (30%) have neither borough nor ZIP; under the new load they get no row of their own and resolve to **Unknown**. `dim_location` has 246 distinct borough/ZIP pairs today, so after 07 expect ~246 rows (245 real + Unknown) against 381,068.
- Implemented, unsynced (Update All held until 07). Unknown row = `borough` `UNKNOWN`, `zip_code` `UNKNOWN`, inserted by `usp_load_dim_location` if absent. `usp_load_fact_crashes` looks its key up into `@unknown_location_key` and `THROW`s 50001 if it is missing, so a skipped dim load fails loudly instead of inserting NULL keys; unmatched rows take it via `ISNULL(dl.location_key, @unknown_location_key)`. Line facts inherit it from `fact_crashes` (D1). `latitude`/`longitude` are `FLOAT` on `fact_crashes` (TRY_CAST from source, unchanged semantics). TMDL: columns moved without lineage tags (Fabric injects), `summarizeBy: none`, `dataCategory` Latitude/Longitude. Procs identical notebook vs item definition.
- **For 06/07:** add to validation — exactly one `UNKNOWN`/`UNKNOWN` row; `fact_crashes` rows on it = 691,375 (± CDC drift); no `location_key = -1` anywhere; no `NULL`/`NULL` row in `dim_location` (it would capture the no-location crashes via the NULL-safe join — guaranteed absent only because Risks step 1 drops the old table). Rows with just one of borough/ZIP keep a real row with a blank in the other: slicers show both blank and `UNKNOWN` — explain in 10. Coordinates are carried as-is: if the source holds `0.0` placeholders (not checked), heat maps will plot them off the coast — out of scope here.
