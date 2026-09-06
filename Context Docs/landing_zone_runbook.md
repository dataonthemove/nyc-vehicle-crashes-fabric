# Landing-Zone Runbook — NYC_VehicleCrashes

**Work needed:** restructure NYC_VehicleCrashes into a landing-zone architecture. Inspect the repo and Fabric state yourself. Anticipated work outline below in Phases.

We will plan one phase at a time. Ask before deleting anything. **We will start with Phase 3.**

---

## Context you can't discover

1. **Landing zone exists for ownership, not data sharing.** Raw lives once, upstream of Dev/Test/Prod, owned by none. Each stage shortcuts to it and builds its own Delta tables. Test/Prod are never Git-bound — deployment pipeline only.
2. **Trial workspaces must NOT be Template App type.** That type silently blocks Git: no Source control button, dead repo picker. Cost a full session.
3. **Use `Jpb_fabric_user7` only.** az CLI defaults to `user6`, which holds no workspace membership — every API call returns `InsufficientPrivileges`. Verify with `az account show --query user.name -o tsv`.
4. **No full-load pipeline exists.** `pl_cdc_NYC_Crashes` filters on a watermark, so the landing lakehouse needs a deliberately early seed value or the first load is partial.

## Open items

- `etl_watermark` must move to the landing lakehouse; the SQL endpoint is read-only, so the writer becomes a notebook, not a Script activity
- Variable Library vs deployment rules undecided
- Trial expires ~28 Sep 2026

## Phases

One session each; verify before moving on.

1. ✅ **Repo restructure** — Dev bound to `/2_dev`. Done.
2. ✅ **Landing workspace** created and bound to `/1_Landing`. Done.
3. ⬜ **Housekeeping** — notebooks audited for name-based OneLake paths.
4. ⬜ **Landing lakehouse** + lock membership to Admin/Viewer.
5. ⬜ **Watermark redesign** — PySpark notebook writing `etl_watermark` to the landing lakehouse; seed it early enough for a full first load.
6. ⬜ **Ingestion move** — rebuild `pl_cdc_NYC_Crashes` in the landing zone, repoint the watermark read at the lakehouse SQL endpoint, swap the Script activity for the notebook, run, verify row counts, commit. Only then delete it from Dev.
7. ⬜ **Dev shortcut** — clear Dev's raw `Files/`, create the shortcut, rerun transformations. Record the shortcut name; Test and Prod must reuse it verbatim.
8. ⬜ **Variable Library (or deployment rules)** — decide, then build. Do this before any deployment, not after.
9. ⬜ **Deployment pipeline** — three stages, landing zone excluded.
10. ⬜ **Deploy to Test** — recreate shortcut, rebind sources, run, validate.
11. ⬜ **Deploy to Prod** — same, plus RBAC, RLS and endorsement.
12. ⬜ **Ongoing** — ingestion cadence, capacity monitoring, continuous commits.
