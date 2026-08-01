# Environment Reference — NYC Motor Vehicle Collisions

> Generated 2026-07-31 via MCP, IDs re-verified 2026-08-01. Refresh by re-running the MCP fetch session.
> Migrated from workspace `NYC_Motor_Vehicle_Collisions` on 2026-07-31.
>
> **All IDs below are physical Fabric item IDs** (`list_items` / `list_folders`). Do not source them
> from the repo's Fabric item files — those carry *logical* IDs, which are different values and are
> rehydrated to physical IDs at deploy time. The 2026-07-31 pass recorded logical IDs for every
> notebook and folder by mistake; all of them were wrong until the 2026-08-01 correction.

---

## Workspace

| Field | Value |
|---|---|
| Name | NYC_VehicleCrashes |
| Workspace ID | `73d1612d-023e-40bb-914b-fcd796620223` |
| Capacity ID | `f1b1feea-3619-4c62-928e-69eb8d45b7a9` |
| Spark runtime | 1.3 — Spark 3.5.5, Python 3.11.8 (verified via Livy 2026-08-01) |

---

## Core Artifacts

| Type | Display Name | Artifact ID |
|---|---|---|
| Lakehouse | NYC_VehicleCrashes_Lakehouse | `69699b13-5771-422f-874c-461430f81d9b` |
| SQLEndpoint | NYC_VehicleCrashes_Lakehouse | `63b7bc57-9351-4c56-a1cf-cda93ca7828c` |
| Warehouse | NYC_VehicleCrashes_Warehouse | `324e2ac0-5ebd-4f8a-9856-a5d7b56a25fe` |
| SemanticModel | NYC_VehicleCrashes_Semantic | `646ec529-eaaa-4d41-b3b0-a31c94355fdd` |
| DataPipeline | pl_cdc_NYC_Crashes | `95ca0fbd-e13c-4743-8d28-d3fa4da33df1` |

**Warehouse TDS endpoint:**
`ugzelu45irnefp3jx4vjlmb6u4-fvq5c4z6ak5ubekl7tlzmyqcem.datawarehouse.fabric.microsoft.com`

> Not exposed by the Fabric Items API — re-copy from Warehouse → Settings → SQL connection string if it changes.

---

## Predecessor Workspace (retained for validation until decommissioned)

| Field | Value |
|---|---|
| Name | NYC_Motor_Vehicle_Collisions |
| Workspace ID | `6e56c48d-2491-4bbe-a283-0efd43bb7d19` |
| Warehouse | `b0befa58-9752-441f-861d-bb04c9fed2c1` |
| Lakehouse | `dc3d09e0-fd82-4e11-8991-4bdeb44bafd5` |

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
| 2_Ingest | `409f3130-016f-4a92-bea3-79fda1520d5d` |
| 3_Transform | `e88dbad8-087f-4676-82ad-e46646a164a8` |
| 4_Model | `3601518e-ee50-4bc3-8d36-e72254912921` |
| 5_Reports | `2d197305-e28f-457b-b3dc-abe35b0dc1a4` |
| Misc_Stuff | `92930838-8f02-4ac4-b239-95bb947a9017` |

---

## Notebooks

17 notebooks as of 2026-08-01.

### 1_DDL

| Notebook | ID |
|---|---|
| 000_DDL_ETL_Watermark_Seed | `8a869970-6158-4b29-ad99-cf66279f0e91` |
| 01_DDL_Dimensions | `88230b3b-b754-4dac-a6e1-7850d98b91c7` |
| 02_DDL_Facts_Bridges | `8b3ed125-413c-47ce-bfa8-00c5e5683434` |

### 2_Ingest

| Notebook | ID |
|---|---|
| nb_cdc_to_delta | `11b1ce02-22b5-487a-a1ef-f71ef9872908` |

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

### Misc_Stuff

| Notebook | ID |
|---|---|
| RefreshSemanticModel | `890dfd06-78fa-4781-9340-21efdfc967ba` |

---

## Pipeline Topology — pl_cdc_NYC_Crashes

Three parallel streams, each: Lookup Watermark → Copy CDC → Delta merge. All three delta merges must succeed before watermark update.

```
Lookup_Crashes_Watermark ──► Copy_Crashes_CDC ──► nb_delta_Crashes ──┐
Lookup_Persons_Watermark ──► Copy_Persons_CDC ──► nb_delta_Persons ──┼──► Update_Watermark_crashes_vehicles_persons
Lookup_Vehicles_Watermark ─► Copy_Vehicles_CDC ─► nb_delta_Vehicles ─┘
```

| Activity | Type | Depends On |
|---|---|---|
| Lookup_Crashes_Watermark | Lookup | — |
| Lookup_Persons_Watermark | Lookup | — |
| Lookup_Vehicles_Watermark | Lookup | — |
| Copy_Crashes_CDC | Copy | Lookup_Crashes_Watermark |
| Copy_Persons_CDC | Copy | Lookup_Persons_Watermark |
| Copy_Vehicles_CDC | Copy | Lookup_Vehicles_Watermark |
| nb_delta_Crashes | TridentNotebook (nb_cdc_to_delta) | Copy_Crashes_CDC |
| nb_delta_Persons | TridentNotebook (nb_cdc_to_delta) | Copy_Persons_CDC |
| nb_delta_Vehicles | TridentNotebook (nb_cdc_to_delta) | Copy_Vehicles_CDC |
| Update_Watermark_crashes_vehicles_persons | Script | nb_delta_Crashes + nb_delta_Persons + nb_delta_Vehicles |

**nb_cdc_to_delta parameters by stream:**

| Stream | file_subfolder | natural_key | source_name |
|---|---|---|---|
| Crashes | NYC_CrashData/crashes | collision_id | crashes |
| Persons | NYC_CrashData/persons | unique_id | persons |
| Vehicles | NYC_CrashData/vehicles | unique_id | vehicles |
