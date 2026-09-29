# Capacity reassignment runbook

Every Fabric trial lasts 60 days. Before it runs out, this runbook moves all four workspaces
(Landing, Dev, Test, Prod) onto a new trial **capacity**, the compute that the workspaces run on.
The move is a **reassignment**, not a rebuild (`CONTEXT.md`). The workspaces keep everything:
item IDs, data, SQL connection strings, Git connections, the deployment pipeline and its rules,
the `vl_NYC_Crashes` variable library, and data connections. Only the capacity ID changes.

Use it at every rotation. Fill in the new column under **Values for each rotation**, run the steps
in order, then fix anything in this runbook that turned out different on the day. Rotation 1 was
the original trial (started 2026-07-30); rotation 2 was the first move. History:
`.scratch/Archive/New-Trial-and-capacity-reassignment/spec.md`.

## Who is who

- **`user7`: the working account.** It is the only account with a role in any workspace (Admin in
  all four). All Fabric work runs as `user7`: the Fabric web UI, Source Control commits made in
  Fabric, `az`, MCP and data connections. It never changes between rotations.
- **Trial accounts (`user8`, then `user9`, …).** Each is a fresh account that exists only to start
  a trial and host the capacity. It has no workspace role and is never used for development.
  Anything committed from Fabric while signed in as a trial account shows up under that account's
  name in ADO history, which happened with `user8` on 2026-09-28/29.
- **Your local Git/VSC.** Commits and pushes from your machine use your own ADO identity. No rotation
  touches it.

Decision record: `.scratch/Archive/capacity-rotation-single-account/spec.md` (Pat, 2026-09-29).

## Values for each rotation

The steps below refer to these names.

| Name | What it is | Rotation 2 (2026-09-25) | Rotation 3 (due ~2026-11-24) |
|---|---|---|---|
| `OLD_CAPACITY_ID` | Capacity that is about to expire | `f1b1feea-3619-4c62-928e-69eb8d45b7a9` | `e52c9636-f9c4-4f58-94c7-57568d827005` |
| `OLD_EXPIRY` | Date it expires | 2026-09-28 | ~2026-11-24 (confirm in Admin portal) |
| `OLD_OWNER` | Trial account that owns it | `Jpb_fabric_user7` | `Jpb_fabric_user8` |
| `NEW_CAPACITY_ID` | New trial capacity | `e52c9636-f9c4-4f58-94c7-57568d827005` | *fill in at 1.5* |
| `NEW_CAPACITY_NAME` | Its display name | `Trial-20260925T023943Z-aQK6FvSBUUWGWhfq5mTwIw` | *fill in at 1.5* |
| `NEW_EXPIRY` | Its expiry (start + 60 days) | ~2026-11-24 | *fill in at 1.5* |
| `NEW_OWNER` | Trial account that starts it | `Jpb_fabric_user8` | *fill in at 1.1* |
| Region | Must be the same on both capacities | UK South | UK South |
| SKU | Trial size | FTL64 | FTL64 |

Rotation 2 is the odd one out: the old owner was `user7` itself. From rotation 3 on, the old owner
is always the previous trial account.

Workspace names and IDs: `Context/environment-reference.md` → Workspaces.

## Rules

- **Start at least 7 days early.** Begin section 1 no later than 7 days before `OLD_EXPIRY`
  (rotation 3: by ~2026-11-17). That leaves time to retry anything that fails, or to pay for
  capacity if Microsoft refuses a new trial.
- **Never cancel the old trial.** Let it expire on its own. If some items fail to move, they stay
  on the old capacity, and retrying them only works while it is still alive. Finish the move and
  all of section 4 before `OLD_EXPIRY`.
- **Only `user7` works in the workspaces.** Never give a trial account a workspace role, not even
  as a quick fix.
- **Reports need a paid licence, not a bigger capacity.** The capacity pays for the *workspace*.
  Power BI Pro or PPU pays for the *person*. `user7` is on a free licence: its Power BI trial ran out
  in 2026-09 and Microsoft won't give it another. On the free licence `user7` can do all
  semantic-model work (Update All, deployment-pipeline deploys, refreshes; tested 2026-09-29). It
  can't create, save or delete reports in the four workspaces. Practise reports in `user7`'s My
  workspace, which isn't in Git. Reports that belong in Git wait until `user7` has Pro. If a blocked
  save still leaves a stray report behind, CC deletes it with the Fabric REST API
  (`DELETE /v1/workspaces/{ws}/items/{id}` via `az rest`).
- **Chaining trials may stop working.** Creating a new account for each trial may break Microsoft's
  trial terms or hit a per-tenant limit. If a new trial is refused at 1.4, stop. The fallback is a
  paid capacity (F-SKU) or Pro for `user7`, and that's Pat's decision.
- **Never rebuild from ADO instead.** A rebuild changes every item ID and means recreating the
  deployment pipeline and its rules, re-authorising connections, and reloading all data from the
  source (a full CDC). Only switch to a rebuild if Pat explicitly decides to.
- **Not part of this runbook:** a CDC run. It tests the Socrata source, not the capacity.

## Terms used below

- **Livy:** the Spark session CC uses to read tables directly from OneLake.
- **Baseline:** row counts, file sizes and watermark values recorded before the move, compared
  after it.
- **`etl_watermark`:** the Landing table that records how far each data load got.
- **`/dax-smoke-test`:** CC's check that the semantic model answers queries with the right counts.
- **"Failed to resolve name":** a DAX error that just means the model needs refreshing after a
  deploy (Direct Lake hasn't loaded the newly deployed version yet). It isn't broken.

## 1. Set up the new trial account

| # | Step | Who | Where |
|---|---|---|---|
| 1.1 | Create `NEW_OWNER` in the tenant, or reuse an account that has no workspace role. | Pat | Entra admin center |
| 1.2 | Give `NEW_OWNER` the Entra **Fabric Administrator** role. The bulk move in 3.2, of workspaces this account isn't a member of, worked with this role in rotation 2. Whether it's strictly required hasn't been tested, so keep it. | Pat | Entra admin center → Roles |
| 1.3 | Give `NEW_OWNER` a **Fabric (Free)** licence. | Pat | Microsoft 365 admin center → Licenses |
| 1.4 | Sign in as `NEW_OWNER` and start a Fabric trial (profile → Account manager → start trial). | Pat | Fabric portal |
| 1.5 | Check the trial's region and SKU match the table. A different region blocks the move. Fill in `NEW_CAPACITY_ID`, `NEW_CAPACITY_NAME` and `NEW_EXPIRY`. | Pat | Admin portal → Capacity settings → Trial |
| 1.6 | Check that `user7` is the only account with a role in the four workspaces. If a trial account has one, Pat removes it (Manage access). | CC (`az rest` → `roleAssignments`); Pat (removal) | Fabric REST / Fabric portal |

## 2. Before the move

| # | Step | Who | Where |
|---|---|---|---|
| 2.1 | Nothing is running: no pipeline or notebook runs. | Pat | Fabric portal → Monitor |
| 2.2 | No Livy sessions are open. | Pat | Fabric portal → Monitor |
| 2.3 | Source Control shows nothing pending in Landing or Dev. Test and Prod aren't connected to Git. Harmless Fabric reformatting is committed as described in `CLAUDE.md`. | Pat | Fabric portal → Source Control |
| 2.4 | Take the baseline: the three `etl_watermark` rows, the row counts in the Baseline section, and the file count and size of each `Files/raw` folder. Use Livy for the counts, the same method as 4.8, so before and after are compared like for like. Close the Livy sessions before section 3, so 2.2 still holds during the move. | CC | MCP (Livy, `list_lakehouse_files`) |
| 2.5 | All four workspaces are on `OLD_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

## 3. Move the workspaces

**Normal route: move all four at once, as the new trial account.** This worked first time in
rotation 2.

| # | Step | Who | Where |
|---|---|---|---|
| 3.1 | Sign in as `NEW_OWNER`. | Pat | Fabric portal |
| 3.2 | Admin portal → Capacity settings → **Trial** tab → `NEW_CAPACITY_NAME` → *Workspaces assigned to this capacity* → Assign workspaces. | Pat | Admin portal |
| 3.3 | Select Landing, Dev, Test and Prod, then apply. | Pat | Admin portal |
| 3.4 | Once the move finishes, check that all four are on `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |

**Backup route: move them one at a time, as `user7`.** Only if the normal route fails. Not needed
so far.

| # | Step | Who | Where |
|---|---|---|---|
| 3.5 | Sign in as `user7`, open Workspace settings → Workspace type → Trial, and check that `NEW_CAPACITY_NAME` is listed. If it isn't, sign in as `NEW_OWNER` and either turn on the trial's default contributor rights, or add `user7` as a contributor **on the capacity**. That's a capacity permission, not a workspace role. | Pat | Fabric portal / Admin portal → Capacity settings → Trial |
| 3.6 | In each workspace: Workspace settings → Workspace type → Trial → `NEW_CAPACITY_NAME` → Apply. | Pat | Fabric portal |
| 3.7 | Repeat 3.4. | CC | MCP (`list_workspaces`) |

**Check for items that didn't move.** Signed in as `user7`, open Workspace settings → Workspace type
in each workspace. The trial account can't do this, because it isn't a member. If a banner says
some items weren't migrated, redo the move for that workspace while the old capacity is still
alive. Don't start section 4 on a workspace that still shows the banner.

## 4. Check everything after the move

Take all row counts **before** running any load, so a load can't cover up data lost in the move.
CC reads tables through Livy using these OneLake paths:

- Stage Lakehouse (uses schemas): `abfss://<ws-id>@onelake.dfs.fabric.microsoft.com/<lakehouse-id>/Tables/dbo/<table>`. Note the `dbo/`.
- Warehouse: `abfss://<ws-id>@onelake.dfs.fabric.microsoft.com/<warehouse-id>/Tables/dbo/<table>`.

Open one Livy session per workspace and close it when done.

**Landing**

| # | Check | Who | Where |
|---|---|---|---|
| 4.1 | Workspace is on `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.2 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.3 | `Files/raw` crashes, persons and vehicles folders match the baseline: same file counts and sizes, and nothing newer than the last load. | CC | MCP (`list_lakehouse_files`) |
| 4.4 | `etl_watermark` still holds the three baseline rows, and its history shows no change since the last load. | CC | MCP (Livy) |
| 4.5 | The `nb_etl_watermark` notebook runs successfully in read mode (`mode=read`) on the new capacity. MCP can't show the notebook's return value; if you want to see it, open the run in the Fabric UI. 4.4 already proves the data it reads. | CC | MCP (`run_on_demand_job`, `get_notebook_run_details`) |

**Dev, Test and Prod** (each one)

| # | Check | Who | Where |
|---|---|---|---|
| 4.6 | Workspace is on `NEW_CAPACITY_ID`. | CC | MCP (`list_workspaces`) |
| 4.7 | No "items not migrated" banner. | Pat | Fabric portal → Workspace settings → Workspace type |
| 4.8 | Lakehouse and Warehouse row counts match the baseline (15 tables). | CC | MCP (Livy) |
| 4.9 | Refresh the semantic model, then `/dax-smoke-test` passes. | CC | MCP |
| 4.10 | The semantic model still reads from the right Warehouse: Dev from its own; Test and Prod as set by their deployment rules in `environment-reference.md`. | CC | Power BI REST (`/datasources`) |
| 4.11 | **Dev only:** one full run of `pl_stage_load_NYC_Crashes` succeeds, and counts still match afterwards. Proves Spark, the stored-procedure steps and the variable library work on the new capacity. | CC | MCP (`run_on_demand_job`) |

**Once, Dev → Test: prove the semantic-model workflow as `user7`**

| # | Check | Who | Where |
|---|---|---|---|
| 4.12 | First, check the deployment pipeline's Dev → Test comparison: the semantic model must show **no other differences**. A deploy promotes *everything* pending, so if other model changes are waiting, stop and treat promoting them as a separate decision. Then CC adds a harmless hidden measure (`_licence_test = 1`) to the model's TMDL and commits. Pat pushes, runs Update All in Dev, then deploys **only the semantic model** Dev → Test (leave the Warehouse unticked). CC checks the measure returns 1 in both; on "Failed to resolve name", refresh first. Then remove the measure the same way. Proves Git, ADO, Source Control and the deployment pipeline all work for `user7` on a free licence. First run 2026-09-29 (`9cd1bce` / `0fc434e`). | CC (edit, commit, DAX); Pat (push, Update All, deploy) | Local (repo) + Fabric portal + MCP |

## 5. Wrap up

| # | Step | Who | Where |
|---|---|---|---|
| 5.1 | Fix anything in this runbook that turned out different, and add the next rotation's column to the values table. | CC | Local (repo) |
| 5.2 | Update `environment-reference.md`: capacity ID, SKU, expiry, the new trial account (capacity only, no workspace role), and the next re-check date. | CC | Local (repo) |
| 5.3 | Update CC's memory with the new capacity, its expiry and anything learned on the day. | CC | Local (CC memory) |
| 5.4 | Add a row to the Move log. If a spec was raised for this rotation, tick it off and archive it. | CC | Local (repo) |
| 5.5 | Commit as `CC Commit: envref_capacity_reassignment_trial<N>`. | CC | Local (repo) |
| 5.6 | Leave the old trial to expire (see Rules). | Pat | No action |

## 6. After the old trial has expired

Do this on or after the day after `OLD_EXPIRY`. It confirms `user7` still works once the old
capacity is gone.

| # | Check | Who | Where |
|---|---|---|---|
| 6.1 | As `user7`, open all four workspaces. In each, open one item (Lakehouse, Warehouse, notebook), make an edit and discard it. No licence or "upgrade" prompt should appear. **Expected exception:** creating, saving or deleting a *report* shows "Upgrade to a paid Power BI license". That's the licence rule, not a failure. | Pat | Fabric portal |
| 6.2 | All four workspaces are still on `NEW_CAPACITY_ID`, and `nb_etl_watermark` still runs in read mode. | CC | MCP |
| 6.3 | Repeat 4.12. | Pat + CC | Local (repo) + Fabric portal + MCP |
| 6.4 | If 6.1 fails on anything other than a report, give `user7` a Fabric (Free) licence and try again. Never fix it by giving a trial account a workspace role. Note the outcome in the Move log. | Pat | Microsoft 365 admin center |

## Baseline (rotation 2: taken 2026-09-25, Warehouse counts re-taken 2026-09-27)

Re-take it at step 2.4 every rotation. Every stage should match these numbers. The Landing data
hasn't changed since the last CDC load (2026-09-10). The Warehouse counts were re-taken on
2026-09-27 after the header/line remodel rebuilt Dev, Test and Prod
(`.scratch/Archive/header-line-remodel/`, tickets 07–09). Fact tables kept the same row counts; the
dimension tables changed.

Landing `etl_watermark`: crashes `2026-09-10 13:04:16`, persons `2026-09-10 13:05:12`,
vehicles `2026-09-10 13:06:06`.

Landing `Files/raw` (listed after the move, 2026-09-25; a `.keep` placeholder file sits at the
root). Each folder holds one full extract, plus header-only files from runs that found no new rows:

| Folder | Files | Total bytes (incl. header-only files) |
|---|---|---|
| `crashes` | 3 | 600,455,102 |
| `persons` | 2 | 1,245,634,764 |
| `vehicles` | 2 | 1,046,196,729 |

| Table | Rows |
|---|---|
| Lakehouse `nyc_crashes` / `nyc_persons` / `nyc_vehicles` | 2,269,187 / 5,984,110 / 4,551,002 |
| `fact_crashes` / `fact_persons` / `fact_crash_vehicle` | 2,269,187 / 5,984,110 / 4,551,002 |
| `bridge_crash_factor` / `dim_factor_group` | 3,610 / 1,581 |
| `dim_contributing_factor` / `dim_vehicle_circumstance` / `dim_date` | 66 / 21,430 / 6,940 |
| `dim_location` / `dim_person` / `dim_vehicle` / `dim_driver` | 246 / 25,990 / 155,594 / 670 |

## Move log

| Rotation | Date | Route | Outcome |
|---|---|---|---|
| 2 | 2026-09-25 | Normal (3.1–3.4) | All four moved, no "not migrated" banners. Checks 4.1–4.11 passed the same day (4.5's return value not viewed). Dev stage load took 4 m 35 s. Follow-up: `.scratch/Archive/New-Trial-and-capacity-reassignment/issues/07-post-expiry-check.md`. |
| 2 (after expiry) | 2026-09-29 | Section 6 | `user7` is on a free licence; its Power BI trial has ended and no new one is allowed. Semantic-model workflow passed (Update All, model-only Dev → Test deploy, refresh; first run of 4.12). Reports are blocked by the licence. `user8`'s Contributor role in Dev was removed, so `user7` is now the only account in all four workspaces; `user6` is gone. |

Background reading: Microsoft Learn `fabric/fundamentals/fabric-trial`, `fabric/admin/portal-workspaces`,
`fabric/admin/portal-workspace-capacity-reassignment` (read 2026-09-25).
