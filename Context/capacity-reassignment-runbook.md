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

| Parameter | Meaning | Rotation 2 (2026-09-25) |
|---|---|---|
| `OLD_CAPACITY_ID` | Expiring trial capacity | `f1b1feea-3619-4c62-928e-69eb8d45b7a9` |
| `OLD_EXPIRY` | Date the old trial expires | 2026-09-28 |
| `OLD_OWNER` | User who started the old trial | `Jpb_fabric_user7` |
| `NEW_CAPACITY_ID` | New trial capacity | `e52c9636-f9c4-4f58-94c7-57568d827005` |
| `NEW_CAPACITY_NAME` | New trial's display name | `Trial-20260925T023943Z-aQK6FvSBUUWGWhfq5mTwIw` |
| `NEW_EXPIRY` | Date the new trial expires (start + 60 days) | ~2026-11-24 |
| `NEW_OWNER` | User who starts the new trial | `Jpb_fabric_user8` |
| `WORKSPACE_PRINCIPAL` | Only member of every workspace; unchanged by the move | `Jpb_fabric_user7` |
| `REGION` | Home region; must match on both capacities | UK South |
| `SKU` | Trial SKU | FTL64 |

`OLD_OWNER` and `WORKSPACE_PRINCIPAL` are independent. They happen to be the same user in
rotation 2. From rotation 3 on, `OLD_OWNER` is the previous `NEW_OWNER`.

Workspace names and IDs: `Context/environment-reference.md` → Workspaces.

## Rules

- **Don't cancel the old trial.** Let it expire on `OLD_EXPIRY`. Items that fail to migrate stay
  attached to `OLD_CAPACITY_ID`, and retrying them depends on it being alive. Finish the move and
  every validation check before `OLD_EXPIRY`.
- **`NEW_OWNER` never joins a workspace.** It is capacity and Fabric admin only.
  `WORKSPACE_PRINCIPAL` stays the only member, so `az`, MCP, Git and OAuth connections don't change.
- **No rebuild from ADO.** It would mean new physical IDs everywhere, a new deployment pipeline and
  rules, re-consented connections and a full re-CDC. Don't switch to a rebuild without an explicit
  decision from Pat.
- Out of scope: a CDC run. It tests Socrata, not the capacity.

## 1. Prerequisites for `NEW_OWNER`

| # | Step | Who | Where |
|---|---|---|---|
| 1.1 | Create `NEW_OWNER` in the tenant, or reuse an existing account that holds no workspace membership. | Pat | Entra admin center |
| 1.2 | Assign `NEW_OWNER` the Entra **Fabric Administrator** role. | Pat | Entra admin center → Roles |
| 1.3 | Assign `NEW_OWNER` a **Fabric (Free)** license. | Pat | Microsoft 365 admin center → Licenses |
| 1.4 | Sign in as `NEW_OWNER` and start a Fabric trial (Account manager → Free trial). | Pat | Fabric portal |
| 1.5 | Confirm the trial's region is `REGION` and its SKU is `SKU`. A different region blocks reassignment. Record `NEW_CAPACITY_ID`, `NEW_CAPACITY_NAME` and `NEW_EXPIRY`. | Pat | Admin portal → Capacity settings → Trial |

## 2. Pre-move checks

| # | Step | Who | Where |
|---|---|---|---|
| 2.1 | No pipeline or notebook runs in progress in any workspace. | Pat | Fabric portal → Monitor |
| 2.2 | No active Livy sessions. | Pat | Fabric portal → Monitor |
| 2.3 | Source Control is clean in Landing and Dev (Test and Prod aren't git-bound; cosmetic drift is committed per `CLAUDE.md`). | Pat | Fabric portal → Source Control |
| 2.4 | Record the baseline: Landing `etl_watermark` rows, the row counts below, and the file count and total size of each `Files/raw` folder. Refresh the baseline if any load ran since it was last taken. | Pat | Fabric portal (SQL endpoint, Lakehouse explorer) |
| 2.5 | Confirm all four workspaces report `capacityId` = `OLD_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

## 3. Reassign the workspaces

**Primary route: bulk reassignment by `NEW_OWNER`.**

| # | Step | Who | Where |
|---|---|---|---|
| 3.1 | Sign in as `NEW_OWNER`. | Pat | Fabric portal |
| 3.2 | Admin portal → Capacity settings → **Trial** tab → `NEW_CAPACITY_NAME` → *Workspaces assigned to this capacity* → Assign workspaces. | Pat | Admin portal |
| 3.3 | Select Landing, Dev, Test and Prod, then apply. | Pat | Admin portal |
| 3.4 | Wait for the move to finish, then confirm each workspace reports `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

**Fallback route: per workspace by `WORKSPACE_PRINCIPAL`.** Use it only if the bulk route fails.

| # | Step | Who | Where |
|---|---|---|---|
| 3.5 | Sign in as `WORKSPACE_PRINCIPAL`. Confirm `NEW_CAPACITY_NAME` appears under Workspace settings → Workspace type → Trial. If it doesn't, sign in as `NEW_OWNER` and turn on the trial's default contributor rights, or add `WORKSPACE_PRINCIPAL` as a contributor. | Pat | Fabric portal / Admin portal → Capacity settings → Trial |
| 3.6 | For each workspace: Workspace settings → Workspace type → Trial → select `NEW_CAPACITY_NAME` → Apply. | Pat | Fabric portal |
| 3.7 | Repeat 3.4. | CC | MCP (`list_workspaces`) |

**Items not migrated.** For each workspace, open Workspace settings → Workspace type (Pat, Fabric
portal). If a banner says some items were not migrated, retry the reassignment for that workspace
while `OLD_CAPACITY_ID` is still alive. Don't start validation on a workspace that shows the banner.

## 4. Post-move validation

Row counts are read by OneLake path from Livy (`/livy-notebook-ops`), **before** any load, so a load
can't hide data lost in the move.

**Landing**

| # | Check | Who | Where |
|---|---|---|---|
| 4.1 | `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.2 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.3 | `Files/raw/{crashes,persons,vehicles}` listing is intact, and file counts and sizes equal the 2.4 baseline where one was recorded. | CC | MCP (`list_lakehouse_files`) |
| 4.4 | `etl_watermark` holds the three baseline rows, unchanged. | CC | MCP (Livy) |
| 4.5 | One `nb_etl_watermark` job run with `mode=read` succeeds and returns the same map. | CC | MCP (`run_on_demand_job`) |

**Dev, Test, Prod** (each)

| # | Check | Who | Where |
|---|---|---|---|
| 4.6 | `capacityId` = `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.7 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.8 | Lakehouse and Warehouse row counts equal the baseline. | CC | MCP (Livy) |
| 4.9 | `refresh_semantic_model`, then `/dax-smoke-test` passes. | CC | MCP |
| 4.10 | Effective Direct Lake binding (`/datasources`) matches the stage: Dev's own Warehouse; Test and Prod per their deployment rules in `environment-reference.md`. | CC | Power BI REST (`api.powerbi.com`) |
| 4.11 | **Dev only:** one full `pl_stage_load_NYC_Crashes` run succeeds, and the counts still equal the baseline afterwards. Proves Spark, the Stored Procedure activities and `vl_NYC_Crashes` work on the new capacity. | CC | MCP (`run_on_demand_job`) |

## 5. Close out

| # | Step | Who | Where |
|---|---|---|---|
| 5.1 | Correct this runbook with whatever differed on move day. Add the next rotation's column to Parameters. | CC | Local (repo) |
| 5.2 | Update `environment-reference.md`: capacity ID, SKU, expiry, `NEW_OWNER` role note, re-verification date. | CC | Local (repo) |
| 5.3 | Update the memory index with the new capacity, its expiry and any move-day lessons. | CC | Local (CC memory) |
| 5.4 | Tick the rotation spec's acceptance criteria and set its status to done. | CC | Local (repo) |
| 5.5 | Commit `CC Commit: envref_capacity_reassignment_trial<N>`. | CC | Local (repo) |
| 5.6 | Let `OLD_CAPACITY_ID` expire on `OLD_EXPIRY`. Don't cancel it (only `OLD_OWNER` could). | Pat | Admin portal (no action) |

## Baseline (rotation 2, taken 2026-09-25)

Refresh it at step 2.4 of the next rotation. Every stage should match. The `Files/raw` file counts
and sizes weren't recorded this rotation.

Landing `etl_watermark`: crashes `2026-09-10 13:04:16`, persons `2026-09-10 13:05:12`,
vehicles `2026-09-10 13:06:06`.

| Object | Rows |
|---|---|
| Lakehouse `nyc_crashes` / `nyc_persons` / `nyc_vehicles` | 2,269,187 / 5,984,110 / 4,551,002 |
| `fact_crashes` / `fact_persons` / `fact_crash_vehicle` | 2,269,187 / 5,984,110 / 4,551,002 |
| `bridge_crash_factor` | 1,648,599 |
| `dim_collision` / `dim_factor_group` | 2,269,187 / 2,269,187 |
| `dim_contributing_factor` / `dim_damage` / `dim_date` | 66 / 4,602 / 6,940 |
| `dim_location` / `dim_person` / `dim_vehicle` | 381,068 / 25,990 / 596,157 |

Background: Microsoft Learn `fabric/fundamentals/fabric-trial`, `fabric/admin/portal-workspaces`,
`fabric/admin/portal-workspace-capacity-reassignment` (read 2026-09-25).
