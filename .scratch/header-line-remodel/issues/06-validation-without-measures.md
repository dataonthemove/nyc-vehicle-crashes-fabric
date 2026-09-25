# 06: Validation without measures

**What to build:** A reusable validation proves a stage's rebuild worked, using only `COUNTROWS`/key queries and Spark counts — no measures exist any more (D11).

**Blocked by:** 05

**Status:** ready-for-agent

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [ ] `/dax-smoke-test` drops its measure spot-check and runs the spec's six acceptance checks: fact counts vs pre-drop, line keys equal their crash's, zero orphaned keys, one empty-set group and unique hashes, every bridged factor filters all three facts, relationships match the spec
- [ ] It includes a capture-pre-drop-counts step recording each fact's row count before any drop
- [ ] Each check reports pass/fail with the offending count

## Comments
