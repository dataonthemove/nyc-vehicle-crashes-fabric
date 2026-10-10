# 02: Assume referential integrity on all 15 relationships: go/no-go (Dev)

**What to build:** Slicers in the Dev model no longer offer a "(Blank)" item on any of the eight one-side dimensions (`Dim Date`, `Dim Location`, `Dim Person`, `Dim Vehicle`, `Dim Vehicle Circumstance`, `Dim Driver`, `Dim Contributing Factor`, `dim_factor_group`), because every relationship assumes referential integrity. A "(Blank)" item then means a genuine orphan, and `/dax-smoke-test` asserts the flag so a rebuilt model can't lose it unnoticed. The fix rests on community reports, not Microsoft documentation, so the Dev result is the decision point: if the blank member survives, revert the flag and record the finding. Spec issue 2.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Baseline DAX on Dev: `ALL` vs `ALLNOBLANKROW` key counts on all eight dimensions; measure-less `SUMMARIZECOLUMNS` over Borough; each fact's grand total | CC | Baseline recorded in Comments (expect +1 per dimension, 7 Borough rows) | todo |
| 2 | Run `/dax-smoke-test` check 3 (orphans) on Dev as the precondition | CC | Zero NULL and zero orphaned many-side keys on all 15 relationships | todo |
| 3 | Local TMDL edit (`/tmdl-model-edit`): set `relyOnReferentialIntegrity` on all 15 relationships, bridge relationships included. No `///` descriptions on relationships | CC | The TMDL diff shows the flag on exactly 15 relationships and nothing else | todo |
| 4 | Extend `/dax-smoke-test` check 6 to assert `RelyOnReferentialIntegrity = true` from `INFO.VIEW.RELATIONSHIPS`, keeping the relationship list consistent wherever the skill keeps it | CC | The skill's check 6 includes the flag assertion | todo |
| 5 | Update the model documentation's Relationships section: the flag, the accepted risk (orphans drop out of filtered totals instead of showing "(Blank)"), and check 3 as the standing guard | CC | The doc section covers all three points | todo |
| 6 | Commit the TMDL and doc changes (`CC Commit: model_relationships_relyonri`); commit the skill change separately in the config repo | CC | Both commits exist | todo |
| 7 | Push to ADO, then run Source Control → Update All in Dev | Pat | Source Control pane shows the semantic model in sync | todo |
| 8 | Run `refresh_semantic_model` on Dev | CC | Refresh completes | todo |
| 9 | Go/no-go DAX: `INFO.VIEW.RELATIONSHIPS` flag on all 15; `ALL` = `ALLNOBLANKROW` on all eight dimensions; Borough returns 6 rows; each fact's grand total equals the sum across every dimension's members | CC | All four hold (go), or any fails (no-go) | todo |
| 10 | On no-go only: revert the flag, the doc change and the check 6 extension; commit; Pat pushes and runs Update All; CC refreshes. On go: skip | CC | Model back to `RelyOnReferentialIntegrity = false` on all 15, or step skipped on go | todo |
| 11 | Record the go/no-go result and its evidence in the parent spec's Comments | CC | Spec Comments has a dated entry with the result | todo |
