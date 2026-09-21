# 05: Dev daily schedule

**What to build:** The Stage load runs unattended in Dev every day at 04:00, two hours after the assumed 02:00 CDC run.

**Blocked by:** 04

**Status:** ready-for-human

Schedules are workspace-side and not in Git, so this is set in the Fabric UI.

- [ ] Dev pipeline schedule set to daily 04:00 in the correct time zone
- [ ] The first scheduled run is observed Succeeded in the Monitor hub
- [ ] Note recorded that the landing CDC run still has no schedule of its own
