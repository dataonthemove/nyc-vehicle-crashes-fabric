# 04: Promote to Test and Prod

**What to build:** Test and Prod serve the renamed model and pass the same lightweight binding check as Dev. No table reload is involved in either stage.

**Blocked by:** 03 (Rename in TMDL, update docs, verify in Dev).

**Status:** ready-for-human

**Who:** Pat deploys through the deployment pipeline; Claude verifies each stage.

- [ ] Pat: deploy the semantic model Dev → Test
- [ ] `refresh_semantic_model` succeeds in Test
- [ ] The per-table DAX query (same as ticket 03) passes in Test
- [ ] Pat: deploy the semantic model Test → Prod
- [ ] `refresh_semantic_model` succeeds in Prod
- [ ] The per-table DAX query passes in Prod
- [ ] Deployment Rules (Direct Lake on SQL data source, ADR-0004) are still in place and unchanged in both stages
