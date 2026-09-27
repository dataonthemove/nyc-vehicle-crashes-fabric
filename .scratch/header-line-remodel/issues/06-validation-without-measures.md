# 06: Validation without measures

**What to build:** A reusable validation proves a stage's rebuild worked, using only `COUNTROWS`/key queries and Spark counts — no measures exist any more (D11).

**Blocked by:** 05

**Status:** done

> Spec: `.scratch/header-line-remodel/spec.md` · ADR-0005. Work on main. **Do not run Source Control Update All in Dev** until ticket 07 — tickets 02–06 land on main unsynced; the whole remodel is proven only in 07.

- [x] `/dax-smoke-test` drops its measure spot-check and runs the spec's six acceptance checks: fact counts vs pre-drop, line keys equal their crash's, zero orphaned keys, one empty-set group and unique hashes, every bridged factor filters all three facts, relationships match the spec
- [x] It includes a capture-pre-drop-counts step recording each fact's row count before any drop
- [x] Each check reports pass/fail with the offending count

## Comments
- 2026-09-27 (CC): Rewrote `~/.claude/skills/dax-smoke-test/SKILL.md` (claude-config repo, not this repo). Step 0 captures pre-drop fact counts by Spark; checks 1–4 are one Livy/Spark script (key anti-joins stay out of DAX — DirectQuery 1M-row cap); check 1 also compares DAX `COUNTROWS`; checks 5–6 are DAX. Also covers ticket 05's asks (`dim_driver` duplicate attribute sets, `driver_key`/`vehicle_circumstance_key` orphans) and the D15 Unknown member. Verified against the still-old Dev: Step 0 returns 2,269,187 / 5,984,110 / 4,551,002; check 5 fails 63 of 63 factors (the pre-remodel line-fact leak — correct red); check 6 flags `dim_collision`; Spark checks 1 and 3 (old-schema subset) pass, check 4 fails with 764,845 key-less groups (the pre-D3 one-group-per-crash design — correct red); check 2 and the new-column parts of 3–4 can only run after 07's rebuild. `execute_dax_query` allows one `EVALUATE` per call.
- 2026-09-27 (CC): Two-axis review (standards + spec) found no missing requirements. Fixed: check 3 double-counted NULL keys; checks 5–6 now self-score PASS/FAIL (check 6 compares against an expected-relationship table — on old Dev it reports exactly 6 missing, 4 extra, `dim_collision` present); check 4 finds the empty-set group by hash; stage IDs now referenced from `Context/environment-reference.md` rather than copied. The reworked Spark lines for checks 3–4 were not re-run (Livy session closed); first full run is 07.
