# Landing-Zone Runbook — NYC_VehicleCrashes

> **Last reviewed:** 2026-09-08 · **Current phase:** 3 · **Owner:** Pat
>
> Live IDs live in `Context Docs/environment-reference.md`. The landing workspace is not
> recorded there yet; its ID is pinned under *Workspaces* below until it is.

**Work needed:** restructure NYC_VehicleCrashes into a landing-zone architecture. Inspect the repo
and Fabric state yourself. Anticipated work outline below in Phases.

We plan one phase at a time. Ask before deleting anything.

---

## Workspaces

Verified via MCP `list_workspaces` 2026-09-08; all on capacity `f1b1feea-3619-4c62-928e-69eb8d45b7a9`.

| Stage | Name | Workspace ID | Git |
|---|---|---|---|
| Landing | `1_NYC_VehicleCrashes_Landing` | `bae79a94-0103-45dc-9993-d9041fbd4e80` | bound to `/1_Landing` |
| Dev | `2_NYC_VehicleCrashes_dev` | `73d1612d-023e-40bb-914b-fcd796620223` | bound to `/2_dev` |
| Test | `3_NYC_VehicleCrashes_test` | `b67c8251-f019-4594-b779-bc2ee14d8307` | never — deployment pipeline only |
| Prod | `4_NYC_VehicleCrashes_prod` | `fd35c11f-9f8d-4bea-9959-8a7a53a2c390` | never — deployment pipeline only |

Test and Prod workspaces already exist and are empty; Phases 10–11 deploy into them rather than
creating them.

---

## Context you can't discover

1. **Landing zone exists for ownership, not data sharing.** Raw lives once, upstream of
   Dev/Test/Prod, owned by none. Each stage shortcuts to it and builds its own Delta tables.
   Test/Prod are never Git-bound — deployment pipeline only.
2. **Shortcut contract — fixed now, because Phases 7, 10 and 11 must all reuse it verbatim.**
   - Shortcut name: `raw_nyc_crashes`
   - Type: OneLake shortcut to `Files/` of the landing lakehouse (not `Tables/`) — raw CSV/JSON
     lands as files; each stage builds its own Delta from them.
   - Target: Fabric Lakehouse `NYC_VehicleCrashes_Landing_Lakehouse`, path `Files/raw/`
   - Mount point in each consuming stage: `Files/raw_nyc_crashes`
   - Shortcuts are **not** in Git and are **not** deployed. Recreate by hand per stage.
3. **Watermark seed: `1900-01-01`.** Fabric Pipeline `pl_cdc_NYC_Crashes` filters on the
   watermark, and no full-load pipeline exists, so the landing lakehouse watermark must be seeded
   at a date earlier than any source row or the first load is partial. Source data starts 2012;
   `1900-01-01` is deliberately far below it. Confirm the loaded row count matches the Socrata
   total before advancing the watermark.
4. **Trial workspaces must NOT be Template App type.** That type silently blocks Git: no Source
   control button, dead repo picker. Cost a full session. Check the type before Phases 10–11 if
   any further workspace is created.
5. **Use `Jpb_fabric_user7` only.** az CLI defaults to `user6`, which holds no workspace
   membership — every API call returns `InsufficientPrivileges`.
   - Verify: `az account show --query user.name -o tsv`
   - Fix: `az login --username Jpb_fabric_user7@<tenant> --tenant <tenant-id>`, then re-verify.
     If several subscriptions resolve, pin one with `az account set --subscription <id>`.

## Open items

- **`etl_watermark` moves to the landing lakehouse.** The SQL endpoint is read-only, so the
  writer becomes a PySpark notebook, not a Script activity.
  **This contradicts `CLAUDE.md`**, which names Fabric Warehouse `dbo.etl_watermark` the single
  authoritative store. Phase 5 is not done until that rule in `CLAUDE.md` is rewritten in the
  same commit as the notebook.
- **Variable Library vs deployment rules — undecided (Phase 8).** Decide on:
  1. *Scope* — do any non-connection values vary by stage (paths, dates, capacity settings)?
     Only connections/lakehouse bindings vary → Deployment Rules suffice.
  2. *Git visibility* — a Variable Library is a Git-managed item and reviewable in a PR;
     Deployment Rules are workspace-side config, invisible to the repo and to code review.
  3. *Cost of change* — Deployment Rules are re-entered per pipeline stage by hand and are the
     usual source of "worked in Test, broke in Prod".

  Default if undecided by the start of Phase 8: Variable Library, on Git visibility alone.
- **Open question — should Phase 8 precede Phase 7?** Phase 7 binds the Dev shortcut before the
  parameterization decision is made, so the binding may need rework. Resolve before starting
  Phase 7; if the shortcut mount point is stage-invariant (it is, by the contract above), the
  current order stands.
- Trial expires ~28 Sep 2026.

## Phases

One session each. A phase is finished only when its **Done when** line is satisfied — verify,
then move on.

1. ✅ **Repo restructure** — Dev bound to `/2_dev`. Done.

2. ✅ **Landing workspace** created and bound to `/1_Landing`. Done.

3. ⬜ **← NEXT · Housekeeping** — audit notebooks for hardcoded workspace/item references.
   - **Scope:** every notebook under `2_dev/`, plus
     `2_dev/4_Model/NYC_VehicleCrashes_Semantic.SemanticModel/definition/expressions.tmdl`.
     Known carriers of `abfss://` / `onelake.dfs` paths today: Fabric Notebook `nb_cdc_to_delta`
     and that `expressions.tmdl`. Also a stale workspace name in Fabric Notebook
     `RefreshSemanticModel` under `2_dev/Misc_Fabric_Items/` — name-based is not automatically
     portable.
   - **Steps:** locate every hardcoded path; classify each as name-based (survives deployment,
     resolves per-workspace) or GUID-based (pins Dev forever and breaks in Test/Prod); record the
     verdict per file.
   - **A finding triggers:** rewrite GUID-based paths to name-based, or to a relative
     `Files/...` reference where the notebook runs against its own attached lakehouse.
   - **Exception — the Direct Lake expression:** the source URL in `expressions.tmdl` must keep its
     `/{workspaceGuid}/{itemGuid}` form. A name-based URL is not a valid Direct Lake data source
     (`Dataset_Import_FailedToImportDataset`, verified 2026-09-08); the deployment pipeline rebinds
     that binding per stage instead.
   - **Done when:** no GUID-based OneLake path remains under `2_dev/` outside the Direct
     Lake expression, the rewrite is committed, and the affected notebooks run clean.
   - **Rollback:** revert the commit; nothing live is changed by this phase.


4. ⬜ **Landing lakehouse** — create `NYC_VehicleCrashes_Landing_Lakehouse`; lock workspace
   membership to Admin (Jpb_fabric_user7@DataOnTheMoveoutlook.onmicrosoft.com) / Viewer (all consuming stages).
   - **Done when:** lakehouse exists with `Files/raw/`, role assignments verified via MCP,
     and the item is committed to `/1_Landing`.
   - **Rollback:** delete the lakehouse — it holds no data at this point.


5. ⬜ **Watermark redesign** — PySpark notebook writing `etl_watermark` to the landing lakehouse;
   seed `1900-01-01` per Context 3.
   - **Done when:** the notebook writes and re-reads the watermark, the seed row is present,
     **and** the `CLAUDE.md` watermark rule is updated in the same commit.
   - **Rollback:** Warehouse `dbo.etl_watermark` remains untouched and authoritative until
     Phase 6 cuts over; revert the commit and delete the notebook.


6. ⬜ **Ingestion move** — rebuild `pl_cdc_NYC_Crashes` in the landing zone, repoint the watermark
   read at the lakehouse SQL endpoint, swap the Script activity for the notebook, run, verify row
   counts, commit. Only then delete it from Dev.
   - **Done when:** a full run succeeds end to end and landing row counts match the Dev Lakehouse
     Delta counts (crashes / persons / vehicles) before deletion.
   - **Rollback:** the Dev copy of the pipeline is the rollback — do not delete it until the
     landing run is verified. If the landing run fails, disable it and keep running Dev's.


7. ⬜ **Dev shortcut** — clear Dev's raw `Files/`, create shortcut `raw_nyc_crashes` per the
   Context 2 contract, rerun transformations.
   - **Done when:** Dev transformations produce unchanged Warehouse row counts reading through
     the shortcut instead of local files.
   - **Rollback (destructive step — this clears live raw files):** take a OneLake copy of Dev's
     raw `Files/` before clearing, or confirm landing holds the same files. Recovery otherwise
     means a full re-ingest from Socrata.


8. ⬜ **Variable Library (or deployment rules)** — decide per the criteria in Open items, then
   build. Do this before any deployment, not after.
   - **Done when:** the decision and its rationale are written into this runbook, and the chosen
     mechanism holds every stage-varying value.


9. ⬜ **Deployment pipeline** — three stages: Dev → Test → Prod. The landing workspace is **not**
   a stage in the pipeline; Fabric pairs whole workspaces, so exclusion means simply never
   assigning it. Landing items are therefore never promoted, and each stage reaches raw data
   through its own manually recreated shortcut.
   - **Done when:** the pipeline exists with exactly the three workspaces above assigned.


10. ⬜ **Deploy to Test** — deploy, recreate shortcut `raw_nyc_crashes`, rebind sources, run,
    validate.
    - **Done when:** Test Warehouse row counts match Dev and a Direct Lake DAX query returns
      the expected fact counts.
    - **Rollback:** redeploy the previous commit from Dev; Test holds no authored content.


11. ⬜ **Deploy to Prod** — same as Phase 10, plus RBAC, RLS and semantic model endorsement
    (endorsement is manual and is never deployed).
    - **Done when:** validation matches Test, RLS roles tested against a non-admin principal,
      and the Prod semantic model is re-endorsed.
    - **Rollback:** redeploy the last tagged commit on `main`.
    

12. ⬜ **Ongoing** — ingestion cadence, capacity monitoring, continuous commits.
    Not a phase with an end state; move these to `Context Docs/BACKLOG.md` once Phase 11 lands.
