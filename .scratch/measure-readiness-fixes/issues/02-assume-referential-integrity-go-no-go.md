# 02: Assume referential integrity on all 15 relationships: go/no-go (Dev)

**What to build:** Slicers in the Dev model no longer offer a "(Blank)" item on any of the eight one-side dimensions (`Dim Date`, `Dim Location`, `Dim Person`, `Dim Vehicle`, `Dim Vehicle Circumstance`, `Dim Driver`, `Dim Contributing Factor`, `dim_factor_group`), because every relationship assumes referential integrity. A "(Blank)" item then means a genuine orphan, and `/dax-smoke-test` asserts the flag so a rebuilt model can't lose it unnoticed. The fix rests on community reports, not Microsoft documentation, so the Dev result is the decision point: if the blank member survives, revert the flag and record the finding. Spec issue 2.

**Blocked by:** None (can start immediately)

**Status:** closed

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Baseline DAX on Dev: `ALL` vs `ALLNOBLANKROW` key counts on all eight dimensions; measure-less `SUMMARIZECOLUMNS` over Borough; each fact's grand total | CC | Baseline recorded in Comments (expect +1 per dimension, 7 Borough rows) | done |
| 2 | Run `/dax-smoke-test` check 3 (orphans) on Dev as the precondition | CC | Zero NULL and zero orphaned many-side keys on all 15 relationships | done |
| 3 | Local TMDL edit (`/tmdl-model-edit`): set `relyOnReferentialIntegrity` on all 15 relationships, bridge relationships included. No `///` descriptions on relationships | CC | The TMDL diff shows the flag on exactly 15 relationships and nothing else | done |
| 4 | Extend `/dax-smoke-test` check 6 to assert `RelyOnReferentialIntegrity = true` from `INFO.VIEW.RELATIONSHIPS`, keeping the relationship list consistent wherever the skill keeps it | CC | The skill's check 6 includes the flag assertion | done |
| 5 | Update the model documentation's Relationships section: the flag, the accepted risk (orphans drop out of filtered totals instead of showing "(Blank)"), and check 3 as the standing guard | CC | The doc section covers all three points | done |
| 6 | Commit the TMDL and doc changes (`CC Commit: model_relationships_relyonri`); commit the skill change separately in the config repo | CC | Both commits exist | done |
| 7 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows the semantic model in sync | done |
| 8 | Run `refresh_semantic_model` on Dev | CC | Refresh completes | done |
| 9 | Go/no-go DAX: `INFO.VIEW.RELATIONSHIPS` flag on all 15; `ALL` = `ALLNOBLANKROW` on all eight dimensions; Borough returns 6 rows; each fact's grand total equals the sum across every dimension's members | CC | All four hold (go), or any fails (no-go) | done |
| 10 | On no-go only: revert the flag, the doc change and the check 6 extension; commit; Pat pushes and runs Update All; CC refreshes. On go: skip | CC | Model back to `RelyOnReferentialIntegrity = false` on all 15, or step skipped on go | skipped (go) |
| 11 | Record the go/no-go result and its evidence in the parent spec's Comments | CC | Spec Comments has a dated entry with the result | done |

## Comments

- 2026-10-10 (CC): Step 1 baseline on Dev, before the flag. `INFO.VIEW.RELATIONSHIPS`: `RelyOnReferentialIntegrity = false` on all 15. `ALL` vs `ALLNOBLANKROW` key counts, +1 on all eight: Dim Date 6,941/6,940; Dim Location 247/246; Dim Person 25,991/25,990; Dim Vehicle 155,595/155,594; Dim Vehicle Circumstance 21,431/21,430; Dim Driver 671/670; Dim Contributing Factor 67/66; `dim_factor_group` 1,582/1,581. Measure-less `SUMMARIZECOLUMNS` over Borough: 7 rows. Grand totals: Fact Crashes 2,269,187; Fact Crash Persons 5,984,110; Fact Crash Vehicles 4,551,002; `bridge_crash_factor` 3,610. Each equals the sum across every related dimension's members, on all 15 relationships. Extended check 6 run against the unchanged model: FAIL, `missing_or_wrong` 15 (expected red).
- 2026-10-10 (CC): Step 2 precondition met. `/dax-smoke-test` check 3 on Dev (Spark, OneLake paths): 0 NULL and 0 unmatched keys on all 15 relationships; no duplicate keys on any of the eight dimensions. 23 of 23 PASS. Steps 3–5 done: `relyOnReferentialIntegrity` on all 15 relationships in `relationships.tmdl`, model doc Relationships section updated, check 6 now requires the flag. Code review applied (doc wording; check 6 also reports `ri_off`). Step 6 committed. Next: Pat pushes and runs Update All in Dev (step 7).
- 2026-10-10 (CC): Steps 7–11 done. **GO.** Pat pushed and ran Update All in Dev; `refresh_semantic_model` completed. `INFO.VIEW.RELATIONSHIPS`: `RelyOnReferentialIntegrity = true` on 15 of 15. `ALL` = `ALLNOBLANKROW` on all eight dimensions (Dim Date 6,940; Dim Location 246; Dim Person 25,990; Dim Vehicle 155,594; Dim Vehicle Circumstance 21,430; Dim Driver 670; Dim Contributing Factor 66; `dim_factor_group` 1,581). Measure-less Borough: 6 rows; Month: 12. Grand totals unchanged (2,269,187 / 5,984,110 / 4,551,002; bridge 3,610) and equal the sum across members on all 15 relationships (0 mismatches). Extended check 6: PASS, `ri_off` 0. Step 10 skipped. Closed.
