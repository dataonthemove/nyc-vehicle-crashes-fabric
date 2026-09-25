# ADR-0005: Header/line fact design — header keys on lines, degenerate collision_id, distinct factor groups

- **Status:** Accepted
- **Date:** 2026-09-25
- **Context:** header/line grilling session; spec `.scratch/header-line-remodel/spec.md`

## Context

The crash is the **header fact** (`fact_crashes`); persons and crash–vehicles are its **line facts**.
Only the header carried `location_key` and `factor_group_key`, so no attribute of `dim_location` or
`dim_contributing_factor` could filter `fact_persons` or `fact_crash_vehicle`. The shared
`dim_collision` looked like the link but held only an id, and `fact_crashes → dim_collision` is
single-direction, so no filter ever crossed it. `dim_factor_group` was 1:1 with the crash, so no two
crashes shared a group and the "group" added a hop without consolidating anything.

## Decision

Follow Kimball's header/line technique physically, in the Warehouse:

- **Line facts carry every header dimension key** (`date_key`, `location_key`, `factor_group_key`),
  looked up from `fact_crashes` by `collision_id` so a line can never disagree with its crash.
  Header-grain measures stay on the header only.
- **`collision_id` is a degenerate dimension** on all three facts. `dim_collision` and `collision_key`
  are dropped.
- **`dim_factor_group` holds one row per distinct set of contributing factors**, not one per crash,
  so the bridge becomes group × factor.

## Options rejected

- **Bidirectional `fact_crashes → dim_collision` in the semantic model.** It creates ambiguous paths
  alongside `dim_date`, silently imposes "any matching crash" semantics, and pushes large semi-joins
  towards the DirectQuery fallback.
- **Per-measure `TREATAS`/`CROSSFILTER`.** Every measure and every role would need hand-written lookups.
- **Keep `dim_collision` as a surrogate-key holder.** A dimension with no attributes earns no surrogate
  key; it only adds a join and implies a filter path that doesn't exist.

## Consequences

- Filtering **line → header** (e.g. crashes involving a pedestrian) is still unsupported by design.
  It needs business definitions first; see `.scratch/Backlog/line-to-header-filtering/`.
- Line-fact loads now depend on `fact_crashes` loading first.
- The change needs a full reload of all three facts; incremental loads alone can't backfill the new keys.
