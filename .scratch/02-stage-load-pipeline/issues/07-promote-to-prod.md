# 07: Promote to Prod and schedule

**What to build:** The Stage load runs daily at 04:00 in Prod against Prod's own items, keeping Prod reports fresh every morning.

**Blocked by:** 06

**Status:** ready-for-human

- [ ] Pipeline deployed Test → Prod; the tested commit is tagged per CLAUDE.md SDLC rule 7
- [ ] Any binding fix proven in 06 is applied for Prod: deploy `vl_NYC_Crashes` together with the pipeline (never the pipeline first). Before running, confirm that the Prod `warehouse_endpoint` resolves to the Prod TDS host (`…d7atl7mn…`) and that every SP `artifactId` = the Prod Warehouse.
- Scheduling was deferred by Pat on 2026-09-23 (ticket 06). `.schedules` is in Git and deployment carries it, so re-plan the schedule boxes below before starting.
- [ ] `vl_NYC_Crashes` active value set = Prod
- [ ] One manual Prod run succeeds, then the daily 04:00 schedule is set
- [ ] The first scheduled Prod run is observed Succeeded, and Prod's model refreshed, not Dev's or Test's
