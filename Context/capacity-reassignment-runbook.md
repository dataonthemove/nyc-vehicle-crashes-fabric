# Capacity reassignment runbook

Moves all four workspaces (Landing, Dev, Test, Prod) from an expiring trial **Capacity** to a new
one by **Capacity reassignment**, not a rebuild (`CONTEXT.md`). Workspace and item physical IDs,
OneLake data, TDS endpoints, Git bindings, the deployment pipeline and its rules, `vl_NYC_Crashes`
active value sets and connections all stay the same. Only the capacity ID changes.

Reuse it at every trial rotation: fill in the parameters, run the steps in order, then correct the
runbook with whatever differed. Rotation 1 was the original trial (started 2026-07-30); rotation 2
is the first move. Origin: `.scratch/05-New-Trial-and-capacity-reassignment/spec.md`.

## Parameters

Set these per rotation. The steps below refer to them by name only.

| Parameter | Meaning | Rotation 2 (2026-09-25) | Rotation 3 (due ~2026-11-24) |
|---|---|---|---|
| `OLD_CAPACITY_ID` | Expiring trial capacity | `f1b1feea-3619-4c62-928e-69eb8d45b7a9` | `e52c9636-f9c4-4f58-94c7-57568d827005` |
| `OLD_EXPIRY` | Date the old trial expires | 2026-09-28 | ~2026-11-24 (confirm in Admin portal) |
| `OLD_OWNER` | User who started the old trial | `Jpb_fabric_user7` | `Jpb_fabric_user8` |
| `NEW_CAPACITY_ID` | New trial capacity | `e52c9636-f9c4-4f58-94c7-57568d827005` | *set at 1.5* |
| `NEW_CAPACITY_NAME` | New trial's display name | `Trial-20260925T023943Z-aQK6FvSBUUWGWhfq5mTwIw` | *set at 1.5* |
| `NEW_EXPIRY` | Date the new trial expires (start + 60 days) | ~2026-11-24 | *set at 1.5* |
| `NEW_OWNER` | User who starts the new trial | `Jpb_fabric_user8` | *new account, set at 1.1* |
| `WORKSPACE_PRINCIPAL` | Admin in every workspace and the account all work runs as (`az`, MCP, Git, connections); unchanged by the move | `Jpb_fabric_user7` | `Jpb_fabric_user7` |
| `REGION` | Home region; must match on both capacities | UK South | UK South |
| `SKU` | Trial SKU | FTL64 | FTL64 |

`OLD_OWNER` and `WORKSPACE_PRINCIPAL` are independent. They happen to be the same user in
rotation 2. From rotation 3 on, `OLD_OWNER` is the previous `NEW_OWNER`.

Workspace names and IDs: `Context/environment-reference.md` → Workspaces.

## Rules

- **Don't cancel the old trial.** Let it expire on `OLD_EXPIRY`. Items that fail to migrate stay
  attached to `OLD_CAPACITY_ID`, and retrying them depends on it being alive. Finish the move and
  every validation check before `OLD_EXPIRY`.
- **One working account (Pat, 2026-09-29).** `WORKSPACE_PRINCIPAL` is the only principal with a
  role in any workspace, and the only identity for local Git/VSC, ADO, the Fabric UI, `az`, MCP and
  connections. Each trial owner (`NEW_OWNER`, `OLD_OWNER`) only hosts capacity: no workspace role,
  no development. Origin: `.scratch/Backlog/capacity-rotation-single-account/spec.md`.
- **Licence, not capacity, gates reports.** A trial capacity licenses the *workspace*; Power BI
  Pro/PPU licenses the *user*. `WORKSPACE_PRINCIPAL` is on a Free licence (its Power BI trial lapsed
  2026-09, no further trial allowed). On Free it can do everything on the semantic-model SDLC path
  (Update All, deployment-pipeline deploy, refresh), verified 2026-09-29. It can't create, save or
  delete reports in the four workspaces. Report practice happens in its My workspace, which isn't
  Git-tracked. Versioned reports wait for Pro. A blocked save can still leave an orphan report;
  delete it with Fabric REST `DELETE /v1/workspaces/{ws}/items/{id}` (`az rest`).
- **Trial chaining is a risk.** New accounts per rotation may breach Microsoft's trial terms or
  hit per-tenant limits. If a new trial is refused at 1.4, stop: the fallback is a paid F-SKU or Pro
  for `WORKSPACE_PRINCIPAL`, which is Pat's decision.
- **No rebuild from ADO.** It would mean new physical IDs everywhere, a new deployment pipeline and
  rules, re-consented connections and a full re-CDC. Don't switch to a rebuild without an explicit
  decision from Pat.
- Out of scope: a CDC run. It tests Socrata, not the capacity.

## 1. Prerequisites for `NEW_OWNER`

| # | Step | Who | Where |
|---|---|---|---|
| 1.1 | Create `NEW_OWNER` in the tenant, or reuse an existing account (preferably one with no workspace membership). | Pat | Entra admin center |
| 1.2 | Assign `NEW_OWNER` the Entra **Fabric Administrator** role. | Pat | Entra admin center → Roles |
| 1.3 | Assign `NEW_OWNER` a **Fabric (Free)** license. | Pat | Microsoft 365 admin center → Licenses |
| 1.4 | Sign in as `NEW_OWNER` and start a Fabric trial (Account manager → Free trial). | Pat | Fabric portal |
| 1.5 | Confirm the trial's region is `REGION` and its SKU is `SKU`. A different region blocks reassignment. Record `NEW_CAPACITY_ID`, `NEW_CAPACITY_NAME` and `NEW_EXPIRY`. | Pat | Admin portal → Capacity settings → Trial |
| 1.6 | Confirm `WORKSPACE_PRINCIPAL` is the only principal with a role in the four workspaces; `NEW_OWNER` and `OLD_OWNER` have none (`GET /v1/workspaces/{ws}/roleAssignments`, run as `WORKSPACE_PRINCIPAL`). Pat removes any extra role via Manage access. | CC | Fabric REST (`az rest`) |

## 2. Pre-move checks

| # | Step | Who | Where |
|---|---|---|---|
| 2.1 | No pipeline or notebook runs in progress in any workspace. | Pat | Fabric portal → Monitor |
| 2.2 | No active Livy sessions. | Pat | Fabric portal → Monitor |
| 2.3 | Source Control is clean in Landing and Dev (Test and Prod aren't git-bound; cosmetic drift is committed per `CLAUDE.md`). | Pat | Fabric portal → Source Control |
| 2.4 | Record the baseline: Landing `etl_watermark` rows, the row counts below, and the file count and total size of each `Files/raw` folder. Refresh the baseline if any load ran since it was last taken. | Pat (watermark, row counts); CC (`Files/raw`) | Fabric portal (SQL endpoint); MCP (`list_lakehouse_files`) |
| 2.5 | Confirm all four workspaces report `capacityId` = `OLD_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

## 3. Reassign the workspaces

**Primary route: bulk reassignment by `NEW_OWNER`.** Worked first time in rotation 2.

| # | Step | Who | Where |
|---|---|---|---|
| 3.1 | Sign in as `NEW_OWNER`. | Pat | Fabric portal |
| 3.2 | Admin portal → Capacity settings → **Trial** tab → `NEW_CAPACITY_NAME` → *Workspaces assigned to this capacity* → Assign workspaces. | Pat | Admin portal |
| 3.3 | Select Landing, Dev, Test and Prod, then apply. | Pat | Admin portal |
| 3.4 | Wait for the move to finish, then confirm each workspace reports `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

**Fallback route: per workspace by `WORKSPACE_PRINCIPAL`.** Use it only if the bulk route fails.
Not needed in rotation 2.

| # | Step | Who | Where |
|---|---|---|---|
| 3.5 | Sign in as `WORKSPACE_PRINCIPAL`. Confirm `NEW_CAPACITY_NAME` appears under Workspace settings → Workspace type → Trial. If it doesn't, sign in as `NEW_OWNER` and turn on the trial's default contributor rights, or add `WORKSPACE_PRINCIPAL` as a contributor. | Pat | Fabric portal / Admin portal → Capacity settings → Trial |
| 3.6 | For each workspace: Workspace settings → Workspace type → Trial → select `NEW_CAPACITY_NAME` → Apply. | Pat | Fabric portal |
| 3.7 | Repeat 3.4. | CC | MCP (`list_workspaces`) |

**Items not migrated.** Sign in as `WORKSPACE_PRINCIPAL` (`NEW_OWNER` isn't a member, so it can't
open workspace settings). For each workspace, open Workspace settings → Workspace type (Pat, Fabric
portal). If a banner says some items were not migrated, retry the reassignment for that workspace
while `OLD_CAPACITY_ID` is still alive. Don't start validation on a workspace that shows the banner.
If `OLD_OWNER` = `WORKSPACE_PRINCIPAL`, that account also sees a "trial expiring in N days" banner:
that is the old trial itself, expected, and needs no action.

## 4. Post-move validation

Row counts are read by OneLake path from Livy (`/livy-notebook-ops`), **before** any load, so a load
can't hide data lost in the move. Paths, all GUID-based:

- Stage Lakehouse (schema-enabled): `abfss://<ws-id>@onelake.dfs.fabric.microsoft.com/<lakehouse-id>/Tables/dbo/<table>` — not `Tables/<table>`.
- Warehouse: `abfss://<ws-id>@onelake.dfs.fabric.microsoft.com/<warehouse-id>/Tables/dbo/<table>`.

Open one Livy session per workspace and close it when the counts are read.

**Landing**

| # | Check | Who | Where |
|---|---|---|---|
| 4.1 | `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.2 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.3 | `Files/raw/{crashes,persons,vehicles}` listing is intact: file counts and sizes equal the 2.4 baseline, and no timestamp is later than the last load. | CC | MCP (`list_lakehouse_files`) |
| 4.4 | `etl_watermark` holds the three baseline rows, unchanged. `DESCRIBE HISTORY` shows no commit since the last load. | CC | MCP (Livy) |
| 4.5 | One `nb_etl_watermark` job run with `mode=read` succeeds, and `get_notebook_run_details` reports `capacityId` = `NEW_CAPACITY_ID`. MCP doesn't expose the notebook `exitValue`; to read the returned map, open the run snapshot in the Fabric UI (Pat) or read it from a pipeline activity output. 4.4 already proves the map's source. | CC | MCP (`run_on_demand_job`, `get_notebook_run_details`) |

**Dev, Test, Prod** (each)

| # | Check | Who | Where |
|---|---|---|---|
| 4.6 | `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.7 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.8 | Lakehouse and Warehouse row counts equal the baseline (15 objects). | CC | MCP (Livy) |
| 4.9 | `refresh_semantic_model`, then `/dax-smoke-test` passes. | CC | MCP |
| 4.10 | Effective Direct Lake binding (`/datasources`) matches the stage: Dev's own Warehouse; Test and Prod per their deployment rules in `environment-reference.md`. | CC | Power BI REST (`api.powerbi.com`) |
| 4.11 | **Dev only:** one full `pl_stage_load_NYC_Crashes` run succeeds, and the counts still equal the baseline afterwards. Proves Spark, the Stored Procedure activities and `vl_NYC_Crashes` work on the new capacity. | CC | MCP (`run_on_demand_job`) |
| 4.12 | **Semantic-model SDLC path as `WORKSPACE_PRINCIPAL`:** push a harmless TMDL change (e.g. hidden measure `_licence_test = 1`), Update All in Dev, deploy the semantic model only (Warehouse unticked) Dev → Test, and CC confirms the measure in both via DAX. Then revert the same way. Proves Git, ADO, Source Control and the deployment pipeline on a Free licence (first run 2026-09-29: `9cd1bce` / `0fc434e`). | Pat (push, Update All, deploy); CC (edit, commit, DAX) | Local (repo) + Fabric portal + MCP |

## 5. Close out

| # | Step | Who | Where |
|---|---|---|---|
| 5.1 | Correct this runbook with whatever differed on move day. Add the next rotation's column to Parameters. | CC | Local (repo) |
| 5.2 | Update `environment-reference.md`: capacity ID, SKU, expiry, `NEW_OWNER` (capacity host only, no workspace role), re-verification date. | CC | Local (repo) |
| 5.3 | Update the memory index with the new capacity, its expiry and any move-day lessons. | CC | Local (CC memory) |
| 5.4 | Tick the rotation spec's acceptance criteria and set its status to done. | CC | Local (repo) |
| 5.5 | Commit `CC Commit: envref_capacity_reassignment_trial<N>`. | CC | Local (repo) |
| 5.6 | Let `OLD_CAPACITY_ID` expire on `OLD_EXPIRY`. Don't cancel it (only `OLD_OWNER` could). | Pat | Admin portal (no action) |

## 6. After the old trial expires

Run on or after the day after `OLD_EXPIRY`. Proves `WORKSPACE_PRINCIPAL` keeps working once the old
trial, and anything it licensed, is gone.

| # | Check | Who | Where |
|---|---|---|---|
| 6.1 | Sign in as `WORKSPACE_PRINCIPAL`. Open all four workspaces, open one Fabric item in each (Lakehouse, Warehouse, notebook) and make and discard an edit. No licence or "upgrade" prompt appears. **Expected exception:** creating, saving or deleting a report shows the "Upgrade to a paid Power BI license" prompt. That is a licence limit, not a failure (see Rules). | Pat | Fabric portal |
| 6.2 | `list_workspaces` still shows all four on `NEW_CAPACITY_ID`, and one `nb_etl_watermark` `mode=read` job succeeds. | CC | MCP |
| 6.3 | Repeat 4.12 (semantic-model SDLC path). | Pat + CC | Local (repo) + Fabric portal + MCP |
| 6.4 | If 6.1 fails on a non-report item: assign `WORKSPACE_PRINCIPAL` a Fabric (Free) licence and repeat 6.1. Never grant a trial owner a workspace role as a workaround. Record the outcome in the Move log. | Pat | Microsoft 365 admin center |

## Baseline (rotation 2, taken 2026-09-25; star counts refreshed 2026-09-27)

Refresh it at step 2.4 of the next rotation. Every stage should match. The landing data has not
changed since the last CDC load (2026-09-10). The Warehouse star counts were re-taken on 2026-09-27,
after the header/line remodel rebuilt Dev, Test and Prod (`.scratch/header-line-remodel/`, tickets
07–09). Fact counts are unchanged; the dimensions changed shape.

Landing `etl_watermark`: crashes `2026-09-10 13:04:16`, persons `2026-09-10 13:05:12`,
vehicles `2026-09-10 13:06:06`.

Landing `Files/raw` (post-move listing, 2026-09-25; a `.keep` sentinel sits at the root). Each
folder holds one full extract plus header-only files from zero-row runs:

| Folder | Files | Total bytes (incl. header-only files) |
|---|---|---|
| `crashes` | 3 | 600,455,102 |
| `persons` | 2 | 1,245,634,764 |
| `vehicles` | 2 | 1,046,196,729 |

| Object | Rows |
|---|---|
| Lakehouse `nyc_crashes` / `nyc_persons` / `nyc_vehicles` | 2,269,187 / 5,984,110 / 4,551,002 |
| `fact_crashes` / `fact_persons` / `fact_crash_vehicle` | 2,269,187 / 5,984,110 / 4,551,002 |
| `bridge_crash_factor` / `dim_factor_group` | 3,610 / 1,581 |
| `dim_contributing_factor` / `dim_vehicle_circumstance` / `dim_date` | 66 / 21,430 / 6,940 |
| `dim_location` / `dim_person` / `dim_vehicle` / `dim_driver` | 246 / 25,990 / 155,594 / 670 |

## Move log

| Rotation | Date | Route | Outcome |
|---|---|---|---|
| 2 | 2026-09-25 | Bulk (3.1–3.4) | All four moved; no not-migrated banners; validation (4.1–4.11) passed same day (4.5 exit map not read; see 4.5). Dev stage load 4 m 35 s. Post-expiry check (6) due 2026-09-29: `.scratch/05-New-Trial-and-capacity-reassignment/issues/07-post-expiry-check.md`. |
| 2 (post-expiry) | 2026-09-29 | Section 6 | `user7` is Free, its Power BI trial expired, and no further trial is allowed. Semantic-model SDLC path passed (Update All, model-only Dev → Test deploy, refresh; 4.12 first run). Report create/save/delete is blocked (licence). The `user8` Contributor exception in Dev was removed, so `user7` is the sole principal in all four workspaces, and `user6` is no longer present. |

Background: Microsoft Learn `fabric/fundamentals/fabric-trial`, `fabric/admin/portal-workspaces`,
`fabric/admin/portal-workspace-capacity-reassignment` (read 2026-09-25).
