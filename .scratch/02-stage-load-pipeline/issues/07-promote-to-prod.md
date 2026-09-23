# 07: Promote to Prod

**What to build:** The Stage load, deployed to Prod by the deployment pipeline, runs manually against Prod's own Lakehouse, Warehouse and model, never Dev's or Test's.

**Blocked by:** 06

**Status:** ready-for-human

- [ ] Pipeline deployed Test → Prod, together with `vl_NYC_Crashes` (never the pipeline first)
- [ ] Before running: the Prod `warehouse_endpoint` resolves to the Prod TDS host (`…d7atl7mn…`), and every SP `artifactId` = the Prod Warehouse (`a72a40c8-…`)
- [ ] `vl_NYC_Crashes` active value set = Prod
- [ ] Prod has no schedule after the deploy (deployment copies the source workspace's schedule; there should be none to copy)
- [ ] One manual Prod run succeeds; Prod's model last-refresh time moved, and Dev's and Test's did not

## Scope decisions (Pat, 2026-09-23)

- **No scheduling anywhere in this solution.** Not in Dev, Test or Prod, and not the landing CDC run. Every Stage load is a manual run. The original "daily 04:00" boxes were removed.
- **No release tag.** This is a practice project, not a real production, so the old SDLC "tag the commit deployed to Test" rule doesn't apply.

## Pre-deploy state (MCP, 2026-09-23)

The Prod workspace `4_NYC_VehicleCrashes_prod` has no `pl_stage_load_NYC_Crashes` yet. `vl_NYC_Crashes` is present (`b37ae4dd-…`), but its active value set hasn't been checked.
