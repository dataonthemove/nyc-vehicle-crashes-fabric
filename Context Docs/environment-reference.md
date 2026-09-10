# Environment Reference — NYC Motor Vehicle Collisions

> Generated 2026-07-31 via MCP, IDs re-verified 2026-08-01, full re-verification 2026-09-08. Refresh by re-running the MCP fetch session.
> Migrated from workspace `NYC_Motor_Vehicle_Collisions` on 2026-07-31.
>
> **All IDs below are physical Fabric item IDs** (`list_items` / `list_folders`). Do not source them
> from the repo's Fabric item files — those carry *logical* IDs, which are different values and are
> rehydrated to physical IDs at deploy time. The 2026-07-31 pass recorded logical IDs for every
> notebook and folder by mistake; all of them were wrong until the 2026-08-01 correction.

---

## Workspaces

Verified via `list_workspaces` 2026-09-08. All four sit on capacity `f1b1feea-3619-4c62-928e-69eb8d45b7a9`.

| Stage | Name | Workspace ID | Git |
|---|---|---|---|
| Landing | `1_NYC_VehicleCrashes_Landing` | `bae79a94-0103-45dc-9993-d9041fbd4e80` | bound to `/1_Landing` |
| Dev | `2_NYC_VehicleCrashes_dev` | `73d1612d-023e-40bb-914b-fcd796620223` | bound to `/2_dev` |
| Test | `3_NYC_VehicleCrashes_test` | `b67c8251-f019-4594-b779-bc2ee14d8307` | never — deployment pipeline only |
| Prod | `4_NYC_VehicleCrashes_prod` | `fd35c11f-9f8d-4bea-9959-8a7a53a2c390` | never — deployment pipeline only |

Dev Spark runtime: 1.3 — Spark 3.5.5, Python 3.11.8 (verified via Livy 2026-08-01).

Every artifact ID in *Core Artifacts* is **Dev-stage**. Test and Prod are empty as of 2026-09-08
(`list_items` returns 0 items for both).

### Landing-stage artifacts

| Type | Display Name | Artifact ID |
|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Lakehouse | `b7f1c383-0af0-4b21-bf6b-4ac398b84391` |
| SQLEndpoint | NYC_VehicleCrashes_Lakehouse | `ef5d1260-aa46-4bea-9fd5-2427f38adf0a` |

---

## Core Artifacts

| Type | Display Name | Artifact ID |
|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Lakehouse | `69699b13-5771-422f-874c-461430f81d9b` |
| SQLEndpoint | NYC_VehicleCrashes_Lakehouse | `63b7bc57-9351-4c56-a1cf-cda93ca7828c` |
| Warehouse | NYC_VehicleCrashes_Warehouse | `324e2ac0-5ebd-4f8a-9856-a5d7b56a25fe` |
| SemanticModel | NYC_VehicleCrashes_Semantic | `646ec529-eaaa-4d41-b3b0-a31c94355fdd` |

**Warehouse TDS endpoint:**
`ugzelu45irnefp3jx4vjlmb6u4-fvq5c4z6ak5ubekl7tlzmyqcem.datawarehouse.fabric.microsoft.com`

> Not exposed by the Fabric Items API — re-copy from Warehouse → Settings → SQL connection string if it changes.

---

## Predecessor Workspace — DECOMMISSIONED

`NYC_Motor_Vehicle_Collisions` (`6e56c48d-2491-4bbe-a283-0efd43bb7d19`) no longer appears in
`list_workspaces` as of 2026-09-08. Its Warehouse (`b0befa58-9752-441f-861d-bb04c9fed2c1`) and
Lakehouse (`dc3d09e0-fd82-4e11-8991-4bdeb44bafd5`) IDs are retained here for historical reference
only — they are not reachable.

---

## Connections

| Purpose | Connection ID |
|---|---|
| Warehouse (OAuth) | `1de56b14-e844-4550-bfe4-a679696728e6` |
| Lakehouse (OAuth) | `92d1dbb4-eab2-4f3b-ae0d-59145fd8c07f` |
| HTTP source — Crashes (anonymous) | `1a0d925e-7e80-4160-a28d-f1aa73b60cc2` |
| HTTP source — Persons (anonymous) | `d6be2434-1299-49f8-ae45-27fe4a15ad7c` |
| HTTP source — Vehicles (anonymous) | `cfec87c6-d50d-48a0-b9e3-4e6aee57b7bb` |

---

## Workspace Folders

| Folder | ID |
|---|---|
| 1_DDL | `cd9c010d-de8c-4c73-98ef-92d340c73376` |
| 3_Transform | `e88dbad8-087f-4676-82ad-e46646a164a8` |
| 4_Model | `3601518e-ee50-4bc3-8d36-e72254912921` |
| 5_Reports | `2d197305-e28f-457b-b3dc-abe35b0dc1a4` |
| Misc_Fabric_Items | `05968e69-1632-4bdc-a169-2c5898cd8097` |

---

## Notebooks

16 notebooks — nb_cdc_to_delta deleted 2026-09-10; count last re-confirmed 2026-09-08.

### 1_DDL

| Notebook | ID |
|---|---|
| 000_DDL_ETL_Watermark_Seed | `8a869970-6158-4b29-ad99-cf66279f0e91` |
| 01_DDL_Dimensions | `88230b3b-b754-4dac-a6e1-7850d98b91c7` |
| 02_DDL_Facts_Bridges | `8b3ed125-413c-47ce-bfa8-00c5e5683434` |


### 3_Transform

| Notebook | ID |
|---|---|
| 03_ETL_dim_date | `48394d16-a615-433d-b5ad-6e1b43b7f6b5` |
| 04_ETL_dim_collision | `668544bb-9590-4fcb-a385-cac2bc435aa6` |
| 05_ETL_dim_location | `c04d0676-4e7e-4d36-a2d3-e64f06c2c753` |
| 06_ETL_dim_contributing_factor | `0987cf73-a3b0-4634-80ce-93ab32d90d1a` |
| 07_ETL_dim_vehicle | `ec2a4b2e-3b7a-4fe7-86b6-5e1eb21b4093` |
| 08_ETL_dim_damage | `06cf8361-91af-4a90-89fc-8d8e36a51006` |
| 09_ETL_dim_person | `cec6b9ba-8eab-4914-a7d1-2596a0e302a0` |
| 09b_ETL_dim_factor_group | `f6aa92ab-a522-4f65-9c88-4de665fe6f8c` |
| 10_ETL_fact_crashes | `b93e6bc5-0c6e-4d4d-b1e2-0d6409891440` |
| 11_ETL_fact_persons | `2942a177-2871-4691-a37c-3726912b68a2` |
| 12_ETL_fact_crash_vehicle | `514c0005-0fb9-499e-bbeb-acce477a5bd0` |
| 13_ETL_bridge_crash_factor | `0a5ff01a-9501-4720-873a-768c29943f49` |

`10_ETL_fact_crashes_old` was deleted 2026-08-01 (commit `f01f79d`) and is no longer in the workspace.

### Misc_Fabric_Items

| Notebook | ID |
|---|---|
| RefreshSemanticModel | `890dfd06-78fa-4781-9340-21efdfc967ba` |

---

## Reports

| Report | ID | Folder |
|---|---|---|
| `Test_ReportCreatedWeb. ` (trailing space in name) | `453c8292-b50c-404c-a4c2-a52b23c34ed5` | 5_Reports |

---

## Pipeline Topology — pl_cdc_NYC_Crashes (RETIRED 2026-09-10)

Fabric Pipeline `pl_cdc_NYC_Crashes` and Fabric Notebook `nb_cdc_to_delta` were deleted from
workspace `2_NYC_VehicleCrashes_dev` along with workspace folder `2_Ingest`, superseded by
Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` (item `483fda7f-6fc2-4034-9cda-9f28f506515c`) in
workspace `1_NYC_VehicleCrashes_Landing`. Its topology and per-stream parameters are recorded in
`landing_zone_runbook_results.md` (Phase 6). The `2_Ingest` numbering gap in repo folder `2_dev/`
is deliberate — renaming the sibling folders would read to Fabric Git Integration as delete+create
and re-issue every item's physical ID.
