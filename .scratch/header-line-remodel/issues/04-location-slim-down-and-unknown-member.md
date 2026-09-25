# 04: Location slim-down and Unknown location member

**What to build:** `dim_location` becomes a small borough/ZIP dimension with a real **Unknown member**, and crash coordinates live on the crash, so heat maps still work (D8, D15, D14).

**Blocked by:** 03

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [ ] First, measure and record in Comments how many crashes carry today's `location_key = -1`
- [ ] `latitude` and `longitude` move from `dim_location` to `fact_crashes`; `dim_location` keeps `borough`, `zip_code`
- [ ] The location load inserts an Unknown row (sentinel attributes) if absent; `fact_crashes` resolves unmatched locations to it **by lookup**, never a literal key; no `-1` remains in any load
- [ ] Semantic model: `latitude`/`longitude` SummarizeBy `None` with Latitude/Longitude data category
- [ ] `CLAUDE.md` SummarizeBy rules gain the latitude/longitude rule
- [ ] Notebook and item-definition procedures identical, same commit

## Comments
