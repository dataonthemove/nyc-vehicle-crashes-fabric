# 03: Full Transform graph

**What to build:** All twelve Transform procedures run as Stored Procedure activities in the spec's three waves. Wave 1: the seven independent dimensions, in parallel. Wave 2: the factor group dimension, after collision. Wave 3: the three facts and the bridge, in parallel, each after every dimension it references. Refresh depends on all of Wave 3. A Stage load now produces a complete star.

**Blocked by:** 02

**Status:** in-progress — authored, awaiting Fabric Update + run

- [x] Every edge is a Succeeded dependency; no On failure or On completion branches
- [x] If adding dependencies times out, collapsing a wave into a barrier is acceptable. Note it in the ticket.
- [ ] A manual run ends Succeeded (spec Test 1)
- [ ] Warehouse fact and bridge counts are non-zero with no duplicate business keys, checked via Spark on OneLake paths
- [ ] `/dax-smoke-test` passes against the Dev model

## Authoring notes (2026-09-23)

The graph was authored as local JSON, not via `add_activity_dependency`. There was no timeout, so no wave was collapsed into a barrier.
Upstream sets were taken from each procedure's joins:

- `fact_crashes` ← collision, factor_group, location, date
- `fact_persons` ← collision, person, date
- `fact_crash_vehicle` ← collision, vehicle, damage, date
- `bridge_crash_factor` ← collision, factor_group, contributing_factor
- `dim_factor_group` ← collision only (reads `dim_collision` alone)

No fact joins `dim_date` (each derives `date_key` from `crash_date`). `Load_dim_date` is still an upstream of every fact, so the truncate-and-reload finishes before any fact that carries a `date_key`.
Every Wave 1 dimension feeds at least one Wave 3 activity, so Refresh transitively waits on all twelve.
