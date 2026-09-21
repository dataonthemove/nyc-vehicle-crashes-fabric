# 07: Promote to Prod and schedule

**What to build:** The Stage load runs daily at 04:00 in Prod against Prod's own items, keeping Prod reports fresh every morning.

**Blocked by:** 06

**Status:** ready-for-human

- [ ] Pipeline deployed Test → Prod; the tested commit is tagged per CLAUDE.md SDLC rule 7
- [ ] Any binding fix proven in 06 is applied for Prod
- [ ] `vl_NYC_Crashes` active value set = Prod
- [ ] One manual Prod run succeeds, then the daily 04:00 schedule is set
- [ ] The first scheduled Prod run is observed Succeeded, and Prod's model refreshed, not Dev's or Test's
