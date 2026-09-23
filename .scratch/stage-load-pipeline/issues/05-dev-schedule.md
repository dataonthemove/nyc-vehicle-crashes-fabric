# 05: Dev daily schedule

**What to build:** The Stage load runs unattended in Dev every day at 04:00, two hours after the assumed 02:00 CDC run.

**Blocked by:** 04

**Status:** ready-for-human

Schedules are workspace-side and not in Git, so this is set in the Fabric UI.

- [ ] Dev pipeline schedule set to daily 04:00 in the correct time zone
- [ ] The first scheduled run is observed Succeeded in the Monitor hub
- [x] Note recorded that the landing CDC run still has no schedule of its own

## Notes (2026-09-23)

- **The landing CDC run is still unscheduled.** `pl_cdc_NYC_Crashes_Landing` in `1_NYC_VehicleCrashes_Landing` has no schedule, so the "02:00 CDC run" is an assumption only. Until one is set, the 04:00 Stage load finds no new landed files and changes nothing (the idempotent rerun from Test 2 in ticket 04). Scheduling it is out of scope here (spec: Out of scope).
- Target: `pl_stage_load_NYC_Crashes` in `2_NYC_VehicleCrashes_dev` (physical ID `977d85cd-f0d8-4628-aca1-6bdfaa79ee6b`).
- Time zone: `(UTC+00:00) Dublin, Edinburgh, Lisbon, London`, the operator's zone. It follows BST, so 04:00 stays 04:00 local all year and stays two hours after a landing schedule set in the same zone.
- **Capacity risk:** the trial capacity expires around 28 Sep 2026. After that, scheduled runs will fail or be skipped until the workspaces move to a paid or new capacity.
- First scheduled trigger: run `6fe0f8e6-f0a5-483d-b928-af7b92ab23a9` (invoke type `Scheduled`) Succeeded 11:37:00 → ~11:41 UTC. All 16 activities succeeded, with Refresh last (11:40:09 → 11:41:01). The schedule that fired it was misconfigured, though: `Cron` with `interval: 60` (hourly) from 12:37 local, not daily at 04:00. So it does not tick the first-run box.
