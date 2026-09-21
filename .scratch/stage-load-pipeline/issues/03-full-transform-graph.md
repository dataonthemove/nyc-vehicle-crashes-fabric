# 03: Full Transform graph

**What to build:** All twelve Transform procedures run as Stored Procedure activities in the spec's three waves. Wave 1: the seven independent dimensions, in parallel. Wave 2: the factor group dimension, after collision. Wave 3: the three facts and the bridge, in parallel, each after every dimension it references. Refresh depends on all of Wave 3. A Stage load now produces a complete star.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Every edge is a Succeeded dependency; no On failure or On completion branches
- [ ] If adding dependencies times out, collapsing a wave into a barrier is acceptable. Note it in the ticket.
- [ ] A manual run ends Succeeded (spec Test 1)
- [ ] Warehouse fact and bridge counts are non-zero with no duplicate business keys, checked via Spark on OneLake paths
- [ ] `/dax-smoke-test` passes against the Dev model
