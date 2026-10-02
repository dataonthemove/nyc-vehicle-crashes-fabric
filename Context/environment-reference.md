# Environment Reference — NYC Motor Vehicle Collisions

> Generated 2026-07-31 via MCP; full re-verification 2026-09-08; **all four workspaces re-verified
> 2026-09-21** (MCP `list_items` / `list_folders`, Power BI `/datasources` API). Refresh by re-running
> the MCP fetch session. Capacity reassigned and all four workspaces re-validated **2026-09-25**.
> Dev, Test and Prod item inventories re-verified **2026-09-28** (`list_items` / `list_folders`) after
> the header/line remodel (`.scratch/header-line-remodel/`, ADR-0005).
> Migrated from workspace `NYC_Motor_Vehicle_Collisions` on 2026-07-31.
>
> **All IDs below are physical Fabric item IDs** (`list_items` / `list_folders`). Do not source them
> from the repo's Fabric item files — those carry *logical* IDs, which are different values and are
> rehydrated to physical IDs on Source Control Update (see `CONTEXT.md`: rehydrate vs autobind). The 2026-07-31 pass recorded logical IDs for every
> notebook and folder by mistake; all of them were wrong until the 2026-08-01 correction.
>
> The landing-zone build (2026-09-08 → 2026-09-21) is closed. Its architecture decisions are in
> `docs/adr/0002`–`0004`; this file holds only live identifiers and environment behaviour.

---

## Workspaces

Tenant ID: `d345b2a1-449d-425a-bf69-bf2a95b03ea7` (`DataOnTheMoveoutlook.onmicrosoft.com`), verified
2026-09-25 via `az account show` and by decoding the TDS endpoint host prefix. 

Verified via `list_workspaces` 2026-09-25 (re-verify by **2026-11-17**, a week before expiry). All
four sit on trial capacity `e52c9636-f9c4-4f58-94c7-57568d827005`
(`Trial-20260925T023943Z-aQK6FvSBUUWGWhfq5mTwIw`) · **FTL64** · UK South · owner `Jpb_fabric_user8`
· **expires ~2026-11-24**. Moved there 2026-09-25 by capacity reassignment from `f1b1feea-3619-4c62-928e-69eb8d45b7a9`
(owner `user7`, expires 2026-09-28, left to lapse). Next rotation: `Context/capacity-reassignment-runbook.md`.
All are type `Workspace`; none is Template App (that type silently blocks Git).

`Jpb_fabric_user8` holds the Entra **Fabric Administrator** role and a Fabric (Free) license, plus
a combined Fabric and Power BI trial. It only hosts the trial capacity: **no workspace role** (its
2026-09-28 Contributor role in Dev was removed on 2026-09-29). Never use it for development, `az`,
MCP or connections. Single-account rule: `Context/capacity-reassignment-runbook.md` → Rules.

| Stage | Name | Physical workspace ID | Git |
|---|---|---|---|
| Landing | `1_NYC_VehicleCrashes_Landing` | `bae79a94-0103-45dc-9993-d9041fbd4e80` | bound to `/1_Landing` |
| Dev | `2_NYC_VehicleCrashes_dev` | `73d1612d-023e-40bb-914b-fcd796620223` | bound to `/2_dev` |
| Test | `3_NYC_VehicleCrashes_test` | `b67c8251-f019-4594-b779-bc2ee14d8307` | never — deployment pipeline only |
| Prod | `4_NYC_VehicleCrashes_prod` | `fd35c11f-9f8d-4bea-9959-8a7a53a2c390` | never — deployment pipeline only |

`Jpb_fabric_user7` · User · **Admin** is the **only** principal in every workspace (`roleAssignments`,
verified 2026-09-29; `user6`, Admin in Dev on 2026-09-25, is gone). `user7` is on a **Free** Power BI
licence: semantic-model SDLC works, but report create/save/delete in these workspaces doesn't.
Use `user7` only. az CLI was logged in as `user7` on 2026-09-29, but has defaulted to `user6`
before, so verify with `az account show --query user.name -o tsv`.

Dev Spark runtime: 1.3 — Spark 3.5.5, Python 3.11.8 (verified via Livy 2026-08-01). `sempy` is
preinstalled; `sempy_labs` is **not**.

### Deployment pipeline

Created 2026-09-11 via Fabric REST; no MCP tool covers deployment pipelines. The landing
workspace is deliberately unassigned, so landing items are never promoted.

| Object | Name | Physical ID | Assigned workspace |
|---|---|---|---|
| Deployment pipeline | `dp_NYC_VehicleCrashes` | `df1e3e42-ea3a-4c74-9567-a63a7bc1898f` | — |
| Stage 0 | Development | `e7887720-b6d2-4955-8184-b2916ba9710a` | `2_NYC_VehicleCrashes_dev` |
| Stage 1 | Test | `a0ab3671-2d5f-44d1-8e05-dc7c13a2f99a` | `3_NYC_VehicleCrashes_test` |
| Stage 2 | Production | `314d8788-f3de-4348-8b03-52b34bd9b62e` | `4_NYC_VehicleCrashes_prod` |

All stages `isPublic: false`. Last deploys, 2026-09-27 (header/line remodel): Dev → Test, then
Test → Prod (operation `7bc133aa-…`, after two failed attempts). **No release tags, by design:** this
is a practice project with no real production (Pat, 2026-09-23). Endorsement, RBAC and security roles
are deferred to a later spec.

**Deploy behaviour learned 2026-09-27:** the Warehouse import validates `ALTER PROCEDURE` against the
*live* tables, so drop changed star tables before deploying, not after. A deploy renames items in
place when their logical ID is kept, but never deletes items removed from the source stage — delete
those in the target by hand. It may also leave the star tables uncreated (Prod): check `sys.tables`
and run DDL `01`/`02` if they are missing.

**Deployment rules (workspace-side config — not in Git; re-enter if the pipeline is rebuilt).**
Autobind never rebinds a Direct Lake on SQL model, so each downstream stage needs a data source
rule on `NYC_VehicleCrashes_Semantic` (ADR-0004):

| Stage | Server (warehouse TDS endpoint) | Database (warehouse physical ID) |
|---|---|---|
| Test | `ugzelu45irnefp3jx4vjlmb6u4-kgbhznqz6ckeln3zxqxoctmda4.datawarehouse.fabric.microsoft.com` | `c2ce6eed-e8d2-46dc-93f6-7bd3bb12edff` |
| Production | `ugzelu45irnefp3jx4vjlmb6u4-d7atl7mnt7vexgkzrj5fhiwdsa.datawarehouse.fabric.microsoft.com` | `a72a40c8-7dba-497e-9c92-0847e39c0ebd` |

Verify the *effective* binding, not the TMDL, with
`GET https://api.powerbi.com/v1.0/myorg/groups/{ws}/datasets/{model}/datasources`.

**Not carried by deployment — set per stage by hand:** Variable Library `vl_NYC_Crashes` active value
set (`Test` / `Prod`, right after each first deploy, before any run); endorsement; RBAC/RLS
membership. **Carried by deployment:** OneLake shortcut `raw_nyc_crashes` (verified Test 2026-09-20,
Prod 2026-09-21); notebook default lakehouse/warehouse bindings (autobind works for notebooks).

---

## Landing-stage artifacts

| Type | Display Name | Physical ID |
|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Landing_Lakehouse | `b7f1c383-0af0-4b21-bf6b-4ac398b84391` |
| SQLEndpoint | NYC_VehicleCrashes_Landing_Lakehouse | `ef5d1260-aa46-4bea-9fd5-2427f38adf0a` |
| Notebook | nb_etl_watermark | `f475e1ca-b96e-4bb6-bc82-759f435e46fb` |
| DataPipeline | pl_cdc_NYC_Crashes_Landing | `483fda7f-6fc2-4034-9cda-9f28f506515c` |

- `Files/raw/{crashes,persons,vehicles}` — raw CSV from Socrata (~2.9 GB). Also holds a `.keep`
  sentinel and header-only files from zero-row runs; readers must tolerate both.
- `Tables/etl_watermark` — authoritative watermark (`source_name`, `last_loaded_value`,
  `last_run_utc`), written **only** by `nb_etl_watermark` (`mode` = `seed` | `advance` | `read`).
  Seed `1900-01-01`. The SQL endpoint is read-only and cannot be a pipeline dependency in Git.
- Warehouse `dbo.etl_watermark` in each stage is legacy and holds 0 rows.

---

## Stage artifacts

Dev holds 21 items plus the auto-created lakehouse SQL endpoint: Lakehouse, Warehouse,
SemanticModel, VariableLibrary, DataPipeline and 16 notebooks. Test and Prod hold 20 because
**`07b_ETL_dim_driver` was never deployed to them** (2026-09-28). Nothing breaks: the pipeline
calls `etl.usp_load_dim_driver`, which the Warehouse item carries. Still, the stages differ until
Pat deploys the notebook. No reports in any stage (all deleted 2026-09-25, spec D13).

| Type | Display Name | Dev physical ID | Test physical ID | Prod physical ID |
|---|---|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Lakehouse | `69699b13-5771-422f-874c-461430f81d9b` | `620d0b45-d190-44a2-83d1-22cdcdce02ec` | `ebf4cc6f-f282-4cb7-98c0-3924af774ad7` |
| SQLEndpoint | NYC_VehicleCrashes_Lakehouse | `63b7bc57-9351-4c56-a1cf-cda93ca7828c` | `0b6d46d4-d947-4553-99bd-741890e6400f` | `c64195a8-5a7f-43fe-a503-07bd429658ab` |
| Warehouse | NYC_VehicleCrashes_Warehouse | `324e2ac0-5ebd-4f8a-9856-a5d7b56a25fe` | `c2ce6eed-e8d2-46dc-93f6-7bd3bb12edff` | `a72a40c8-7dba-497e-9c92-0847e39c0ebd` |
| SemanticModel | NYC_VehicleCrashes_Semantic | `646ec529-eaaa-4d41-b3b0-a31c94355fdd` | `d93844d0-1416-4722-9c86-20492a9ded63` | `3415a5b0-11ac-47cd-8636-f38d5417ce94` |
| VariableLibrary | vl_NYC_Crashes | `41f320eb-5d71-4643-8f46-dacc72fc6ee4` | `62a1fe03-0229-4811-8857-f241c5b20e4e` | `b37ae4dd-7ff3-43c3-8557-ef8d49ace0fd` |
| Notebook | nb_cdc_to_delta | `0b138bcd-d73b-425a-b198-7e78a643e33b` | `7fa44195-cde5-4980-b533-eea4ece748d2` | `63deb6d9-c293-4f98-b4da-87c2169d18c7` |
| Notebook | RefreshSemanticModel | `890dfd06-78fa-4781-9340-21efdfc967ba` | `3caf0c97-2707-4ed0-91be-deba608114f6` | `58ae15a5-7752-4f76-800d-f409303e4d23` |

**Warehouse TDS endpoints** — read from `GET /v1/workspaces/{ws}/warehouses/{id}` →
`properties.connectionString`, or Warehouse → Settings → SQL connection string:

| Stage | Endpoint |
|---|---|
| Dev | `ugzelu45irnefp3jx4vjlmb6u4-fvq5c4z6ak5ubekl7tlzmyqcem.datawarehouse.fabric.microsoft.com` |
| Test | `ugzelu45irnefp3jx4vjlmb6u4-kgbhznqz6ckeln3zxqxoctmda4.datawarehouse.fabric.microsoft.com` |
| Prod | `ugzelu45irnefp3jx4vjlmb6u4-d7atl7mnt7vexgkzrj5fhiwdsa.datawarehouse.fabric.microsoft.com` |

**Semantic model:** Direct Lake **on SQL** since 2026-09-21 (`expression DatabaseQuery =
Sql.Database(<Dev TDS endpoint>, "324e2ac0-…")`). Since the 2026-09-27 remodel it has **no measures
and no roles**: every measure was removed (spec D5) and RLS role `Borough_Reader`, which leaked into the
line facts, was deleted (D10). Table and relationship detail: `2_dev/4_Model/SEMANTIC_MODEL.md`. If
roles return, Fabric *Test as role* is unsupported on this model (SSO). Test them with XMLA
impersonation instead (`powerbi-modeling-mcp` `dax_query_operations` → `impersonation.roles`).

**Lakehouse `Files/`:** holds only OneLake shortcut `raw_nyc_crashes` → landing
`NYC_VehicleCrashes_Landing_Lakehouse` `Files/raw/`; serialized in repo file
`shortcuts.metadata.json` and carried by deployment. Fabric names a new shortcut after its target
folder (`raw`) by default — rename it if ever recreated by hand.

**Orchestration:** `pl_stage_load_NYC_Crashes` (Ingest ×3 → 12 SP activities → Refresh), in Dev `977d85cd-f0d8-4628-aca1-6bdfaa79ee6b`, Test `57d48e48-f7fa-4df7-ba55-f35428ce8bcf` and Prod `8d6d62a6-2bee-4b4f-b29b-03c70a01bdcb`. There are no schedules anywhere, by design (Pat, 2026-09-23). All runs are manual. SP activity `endpoint` = `vl_NYC_Crashes.warehouse_endpoint`, because deployment doesn't rebind it. The steps it replaces: Delta build (`nb_cdc_to_delta` ×3) → DDL `01`–`02` (fresh
stage only) → ETL `03`–`13` (`09b` before `10` and `13`; `10` before `11` and `12`, which take their
header keys from `fact_crashes`) → `RefreshSemanticModel`, all manual job runs.
`nb_cdc_to_delta` parameters: `source_name`, `file_subfolder` (`raw_nyc_crashes/<source>`),
`file_pattern` (`*`), `natural_key` (`collision_id` for crashes, `unique_id` for persons/vehicles);
job `execution_data` overrides work.

---

## Predecessor Workspace — DECOMMISSIONED

`NYC_Motor_Vehicle_Collisions` (`6e56c48d-2491-4bbe-a283-0efd43bb7d19`) no longer appears in
`list_workspaces` as of 2026-09-08. Its Warehouse (`b0befa58-9752-441f-861d-bb04c9fed2c1`) and
Lakehouse (`dc3d09e0-fd82-4e11-8991-4bdeb44bafd5`) IDs are retained here for historical reference
only — they are not reachable.

---

## Connections

| Purpose | Name | Connection ID |
|---|---|---|
| Warehouse (OAuth) | `DataWarehouseConnection` | `1de56b14-e844-4550-bfe4-a679696728e6` |
| Lakehouse (OAuth) | `Lakehouseconnection` | `92d1dbb4-eab2-4f3b-ae0d-59145fd8c07f` |
| HTTP source — Crashes (anonymous) | — | `1a0d925e-7e80-4160-a28d-f1aa73b60cc2` |
| HTTP source — Persons (anonymous) | — | `d6be2434-1299-49f8-ae45-27fe4a15ad7c` |
| HTTP source — Vehicles (anonymous) | — | `cfec87c6-d50d-48a0-b9e3-4e6aee57b7bb` |

OAuth connections are owned by `Jpb_fabric_user7` and carry their own consent, scoped at creation.
A Copy write failing `LakehouseForbiddenError` despite Admin RBAC is fixed by re-consenting the
credentials in Manage connections and gateways — expect it on every newly targeted workspace.
Socrata is called unauthenticated (app token retired; ADR-0001).

---

## Workspace Folders (Dev)

| Folder | Physical ID |
|---|---|
| 1_DDL | `cd9c010d-de8c-4c73-98ef-92d340c73376` |
| 2_Ingest | `1bc40e35-fb48-497f-8fde-d2be1ced2efe` |
| 3_Transform | `e88dbad8-087f-4676-82ad-e46646a164a8` |
| 4_Model | `3601518e-ee50-4bc3-8d36-e72254912921` |
| 5_Reports | `2d197305-e28f-457b-b3dc-abe35b0dc1a4` |
| 6_Orchestration | `d77abec1-4f47-4e0e-b318-4b098e3eafbe` |
| 99_Config | `0e873041-9b3e-4001-85a0-da5e7a0b1a50` |

`5_Reports` has been empty since the reports were deleted (2026-09-25). `Misc_Fabric_Items` is deleted
(gone from `list_folders` 2026-09-28).

Test and Prod folders mirror these names with their own physical IDs.

---

## Notebooks (Dev)

16 notebooks, re-confirmed 2026-09-28. The remodel deleted `04_ETL_dim_collision` (Dev
`668544bb-…`), added `07b_ETL_dim_driver`, and renamed `08_ETL_dim_damage` in place to
`08_ETL_dim_vehicle_circumstance` (same ID), so the count is unchanged. `000_DDL_ETL_Watermark_Seed` was deleted 2026-09-10
(workspace commit `293f3e1`); `nb_cdc_to_delta` was deleted in the same commit and restored
2026-09-10 under a new ID.

### 1_DDL

| Notebook | Physical ID |
|---|---|
| 01_DDL_Dimensions | `88230b3b-b754-4dac-a6e1-7850d98b91c7` |
| 02_DDL_Facts_Bridges | `8b3ed125-413c-47ce-bfa8-00c5e5683434` |

### 2_Ingest

| Notebook | Physical ID |
|---|---|
| nb_cdc_to_delta | `0b138bcd-d73b-425a-b198-7e78a643e33b` |

### 3_Transform

| Notebook | Physical ID |
|---|---|
| 03_ETL_dim_date | `48394d16-a615-433d-b5ad-6e1b43b7f6b5` |
| 05_ETL_dim_location | `c04d0676-4e7e-4d36-a2d3-e64f06c2c753` |
| 06_ETL_dim_contributing_factor | `0987cf73-a3b0-4634-80ce-93ab32d90d1a` |
| 07_ETL_dim_vehicle | `ec2a4b2e-3b7a-4fe7-86b6-5e1eb21b4093` |
| 07b_ETL_dim_driver | `1e560818-cf85-4688-b189-a6b50938e695` |
| 08_ETL_dim_vehicle_circumstance | `06cf8361-91af-4a90-89fc-8d8e36a51006` |
| 09_ETL_dim_person | `cec6b9ba-8eab-4914-a7d1-2596a0e302a0` |
| 09b_ETL_dim_factor_group | `f6aa92ab-a522-4f65-9c88-4de665fe6f8c` |
| 10_ETL_fact_crashes | `b93e6bc5-0c6e-4d4d-b1e2-0d6409891440` |
| 11_ETL_fact_persons | `2942a177-2871-4691-a37c-3726912b68a2` |
| 12_ETL_fact_crash_vehicle | `514c0005-0fb9-499e-bbeb-acce477a5bd0` |
| 13_ETL_bridge_crash_factor | `0a5ff01a-9501-4720-873a-768c29943f49` |

`10_ETL_fact_crashes_old` was deleted 2026-08-01 (commit `f01f79d`) and is no longer in the workspace.

**Remodel notebooks, per stage** (2026-09-28). `04_ETL_dim_collision` is gone from all three stages.
Pat deleted the copies the deploys left behind in Test and Prod.

| Notebook | Dev | Test | Prod |
|---|---|---|---|
| 07b_ETL_dim_driver | `1e560818-cf85-4688-b189-a6b50938e695` | not deployed | not deployed |
| 08_ETL_dim_vehicle_circumstance | `06cf8361-91af-4a90-89fc-8d8e36a51006` | `2e725019-acae-4ff8-8754-79e9e4cc0956` | `c8461d0b-f0f7-4fb1-829a-c2b6e772c151` |

`dim_driver` is a Warehouse table (`dbo.dim_driver`), not a Fabric item, so it has no item ID. It is
loaded by `etl.usp_load_dim_driver` through pipeline activity `Load_dim_driver`.

### 4_Model

| Notebook | Physical ID |
|---|---|
| RefreshSemanticModel | `890dfd06-78fa-4781-9340-21efdfc967ba` |

Reads `vl_NYC_Crashes` via `notebookutils.variableLibrary`; refreshes with `sempy.fabric.refresh_dataset`.
Library reads fail from a Livy session — test through a notebook job.

---

## Reports

None in any stage. Pat deleted both reports in Dev, Test and Prod on 2026-09-25 (spec D13). They will
be rebuilt after the measures spec.

---

## Pipeline Topology — pl_cdc_NYC_Crashes_Landing (landing workspace)

Replaced Dev's `pl_cdc_NYC_Crashes`, deleted 2026-09-10 with the old `2_Ingest` contents (the folder
was since recreated for `nb_cdc_to_delta`). Seven activities:

`Read_Watermarks` (`nb_etl_watermark`, `mode=read`, exits a JSON map) → three parallel
`Copy_{Crashes,Persons,Vehicles}_CDC` (Socrata HTTP, `$where crash_date > watermark`, sink
`Files/raw/<source>/<runId>.csv`) → three **chained** `Advance_Watermark_*` (`mode=advance`,
`loaded_file` = that source's `raw/<source>/<runId>.csv`, `Completed` dependency, retry 2 @ 60s —
parallel MERGEs on the single-file Delta table raise `ConcurrentAppendException`).

- Copies read the watermark as `@{json(activity('Read_Watermarks').output.result.exitValue).<source>}`.
- Notebook-activity parameter shape that works:
  `"loaded_file": {"value": {"value": "@…", "type": "Expression"}, "type": "string"}`. Fabric's UI emits
  an outer `"type": "Expression"`, which fails at submission — fix it in the JSON.
- Watermark advances to the newest `crash_date` in the landed file (never backwards); read mode
  subtracts a 7-day lookback (`.scratch/_Archive/watermark-from-loaded-data`; deployed 2026-10-01).
  Watermarks reset to 2026-06-11 and verified end to end 2026-10-02, run
  `8552e9f4-c872-42b7-ac6c-4162c77fef0c`.
- Last full run `06db7dc7-3c8a-46ee-830f-6e2f830db867` (2026-09-10): landed crashes 2,269,187 ·
  persons 5,984,110 · vehicles 4,551,002.

---

## Baseline row counts (all stages, post-remodel rebuild 2026-09-27)

Identical in Dev, Test and Prod (tickets 07–09 of `.scratch/header-line-remodel/`):
`fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 ·
`bridge_crash_factor` 3,610 · `dim_factor_group` 1,581 · `dim_date` 6,940 · `dim_location` 246 ·
`dim_vehicle` 155,594 · `dim_vehicle_circumstance` 21,430 · `dim_driver` 670 · `dim_person` 25,990 ·
`dim_contributing_factor` 66 · `etl_watermark` 0.

Before the remodel (2026-09-21 → 2026-09-25) the fact counts were the same, but the dimensions
differed: `bridge_crash_factor` 1,648,599, `dim_collision` and `dim_factor_group` 2,269,187 each,
`dim_location` 381,068, `dim_vehicle` 596,157, `dim_damage` 4,602.

Read Warehouse tables by OneLake path from Livy
(`abfss://{ws}@onelake.dfs.fabric.microsoft.com/{warehouse}/Tables/dbo/<table>`): `sqldatawarehouse`
notebook jobs report Completed without proving any work was done.
