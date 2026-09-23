# 06: Promote to Test

**What to build:** The Stage load, deployed to Test by the deployment pipeline, runs manually against Test's own Lakehouse, Warehouse and model, never Dev's.

**Blocked by:** 05

**Status:** ready-for-human

- [ ] Pipeline deployed Dev → Test
- [ ] Stored Procedure activities point at the Test Warehouse after deployment. Watch `endpoint`: it is a literal Dev TDS host in Git (see ticket 01 Outcome); `artifactId` is a logical ID and rehydrates. If not, add a Deployment Rule or Variable Library item reference and record the outcome in the spec's Further Notes (possible ADR).
- [ ] Ingest and Refresh notebooks bound to Test items (autobind)
- [ ] `vl_NYC_Crashes` active value set = Test (ADR-0003)
- [ ] A manual Test run succeeds; the Test model's last-refresh time moved and Dev's did not (spec Test 4)
- [ ] Test has no schedule

## Evidence from ticket 04 (2026-09-23)

Fabric branch-out rehydrated each SP activity's Warehouse `artifactId` but **left `endpoint` as the Dev TDS host**. Every SP activity then failed with "database was not found". Treat the endpoint as not rebinding on deployment either until a Test run proves otherwise.
Branch-out also left `nb_cdc_to_delta`'s default lakehouse pointing at Dev. The environment reference says deployment autobinds notebooks, but verify it here anyway, because a missed rebind makes Test's Ingest write into Dev silently.
