# Backlog — NYC Motor Vehicle Collisions

> Working backlog for this Fabric build. Durable conventions belong in `CLAUDE.md`;
> live IDs belong in `environment-reference.md`. This file is only for work that is
> *not yet done*.
>
> Last reviewed: 2026-08-15.

Statuses: **OPEN** · **BLOCKED** · **DONE** (kept briefly for context, then deleted).

---

## 1. Lakehouse CDC and Warehouse star load are not connected — OPEN, decision needed

`pl_cdc_NYC_Crashes` lands data in the **Lakehouse Delta tables only**. The Warehouse
dimensional load (`etl.usp_load_*`) is not part of the pipeline and currently runs only by
executing the `3_Transform` notebooks by hand. So after every CDC run the star schema and
the semantic model are stale until someone remembers to run 12 notebooks in the right order.

For a portfolio build this is the most visible architectural gap after the missing measure
layer — the pipeline stops halfway through the medallion.

**Options:**

- Extend `pl_cdc_NYC_Crashes` with Script activities calling each `usp_load_*` in dependency
  order, gated on the watermark update. Keeps one pipeline.
- Build a second pipeline (`pl_load_warehouse`) and chain it via Invoke Pipeline. Cleaner
  separation, and lets the star load be rerun without re-ingesting.

Either way the order matters: dims → `dim_factor_group` → facts → bridge, with
`RefreshSemanticModel` last.

---

## 2. NYC Open Data app token is committed in cleartext — OPEN

`2_Ingest/pl_cdc_NYC_Crashes.DataPipeline/pipeline-content.json` embeds
`X-App-Token: W1wHO8uCRL6zDplGACRU0Vn5l` in all three Copy source `additionalHeaders`
blocks. It is in the repo and in git history.

Low severity — a NYC Open Data app token only raises an anonymous rate limit; it grants
no write access and no access to anything non-public. But it is a credential in version
control, which is the wrong shape for a portfolio repo that is meant to demonstrate good
practice.

**Options, cheapest first:**

- Drop the header entirely. The unauthenticated Socrata limit is generally adequate for
  this CDC volume. Costs nothing, removes the problem.
- Move it to a pipeline parameter with a default supplied at runtime.
- Move it to Azure Key Vault and reference it via a Web activity.

Rotating the token does not fix the committed history; only stopping its use does.

---

---

## Recently closed

Kept only as context for the items above. Delete once stale.

- **`03_ETL_dim_date` item description corrected** (2026-08-15) — now reads
  2012-01-01 to 2030-12-31 (6,940 rows), set-based, matching the proc as of `afe95db`.

  The old item claimed item descriptions are not git-managed and had to be fixed in the
  Fabric UI. That is wrong: the description lives in the `metadata` block of
  `3_Transform/03_ETL_dim_date.Notebook/.platform`, which Git Integration does sync.
  Edit it locally, push, then Source Control → Update All — same as any other item change.
  Editing it in the UI instead would put the workspace ahead of the repo.

- **`vehicle_occupants` zero-vs-blank ambiguity was a measure defect, not a data defect**
  (`aee8c37`, 2026-08-15) — the old item 4 asserted the ETL collapsed "reported zero" and
  "not reported" into one value. It does not. The Lakehouse column is already `int` and stores
  NULL and 0 as distinct values, so the Warehouse `TRY_CAST` is a pass-through and the
  distinction survives end to end. No ETL change was ever needed.

  The 49.2% coverage figure was manufactured by the measure that reported it:
  `Vehicles with Occupant Data` tested `vehicle_occupants > 0`, discarding 480,156 genuinely
  reported zeros along with the true blanks. Switching the predicate to `NOT ISBLANK` fixed it.

  | Bucket (Lakehouse `nyc_vehicles`, 4,551,002 rows) | Rows |
  |---|---:|
  | Populated 1–100 | 2,240,049 |
  | NULL — genuinely unreported | 1,830,645 |
  | 0 — genuinely unoccupied | 480,156 |
  | Over 100 — capped to NULL by ETL | 152 |

  The zeros are real, not a source placeholder. Parked vehicles carry a **75.1%** zero rate
  against a 2–5% baseline across every moving maneuver; 81.8% of all zeros are Parked, and 72%
  have no driver recorded. Two independent signals agreeing — a placeholder would scatter
  uniformly.

  Validated live: coverage 49.2% → **59.77%**, `Average Occupants per Vehicle` 1.39 → **1.1463**,
  `Total Occupants` unchanged at 3,118,066. Only the denominator moved, which is the whole point.

  Residual, not worth an item: ~87,200 non-parked zeros at a ~4% rate are probably under-reporting.
  That is 1.9% of the table, against the 480k the old predicate was discarding.

  Unrelated to the `44ea207` outlier cap, which is holding (max observed 100).

- **Semantic model measure layer built and validated** (`721344c`, `6e79e08`, 2026-08-12) —
  29 measures as local TMDL, synced via Source Control Update All and verified live.

  | Table | Measures |
  |---|---|
  | `fact_crashes` | Total Crashes; Persons / Pedestrians / Cyclists / Motorists Injured & Killed; Crashes with Injury / Fatality; Injury Rate; Fatality Rate; Injuries per Crash; Crashes PY; Crashes YoY %; Crashes PM; Crashes MoM % |
  | `fact_persons` | Total Persons Involved; Injured Persons; Killed Persons; Person Injury Rate; Average Person Age |
  | `fact_crash_vehicle` | Total Vehicles Involved; Total Occupants; Vehicles with Occupant Data; Occupant Data Coverage %; Average Occupants per Vehicle; Vehicles per Crash |

  Validated: `Total Crashes` = 2,269,187 (matches fact row count); `Crashes PY` chain ties
  exactly year over year (2023 PY = 103,887 = 2022 actual); `Average Occupants per Vehicle`
  = 1.39 with 49.2% coverage.

  Three things a future reader needs:

  - **`dim_date` is marked as a date table** — `dataCategory: Time` on the table, `isKey` on
    `full_date`. Required for `SAMEPERIODLASTYEAR` / `DATEADD`, and confirmed to survive the
    Fabric Git import. `isKey` is the date-table designation, **not** a relationship key; the
    fact→dim relationships still join on the integer `date_key` and were not changed. Only one
    table per model can hold this marking.
  - **Two injury measures exist at different grains by design** — `Persons Injured` (crash-level
    roll-up on `fact_crashes`) and `Injured Persons` (person grain on `fact_persons`). They will
    not tie. `Injury Rate` is crash-level (share of crashes with ≥1 injury), *not* injuries per
    crash — `Injuries per Crash` is the separate measure.
  - Partial-period YoY/MoM looks alarming and is not a defect: 2026 shows −57% YoY and June
    −69% MoM purely because the CDC watermark sits mid-year. Report date axes should filter to
    complete periods.

  First real exercise of `/tmdl-model-edit`; the skill held up with no workflow restatement
  needed, and was updated with the date-table prerequisite it had been missing.

- **All 5 connections verified under the new account** (2026-08-02) — `pl_cdc_NYC_Crashes`
  run `80d7cab7-48d7-429a-a557-c4447b551d92` completed with all 10 activities succeeded
  (~14 min end to end). The Lookups and the watermark Script exercised the Warehouse
  connection, the three Copies exercised the three anonymous HTTP sources and the Lakehouse
  sink. The `LakehouseWriteSettings` sink correction also ran clean in a real execution.
  Note: each Lookup reported ~300,000 ms, which is capacity queue wait, not query time.

- **Account migration for the 5 connections completed** (2026-08-01) — the new workspace
  was linked to the *existing* connections, the new account was made owner, and the old
  account was removed. The connections were reused rather than recreated, so all five IDs
  in `environment-reference.md` remain correct. Verified: connection IDs in the live
  pipeline unchanged, and a Direct Lake DAX query returns fact_crashes 2,269,187 /
  fact_persons 5,984,110 / bridge_crash_factor 1,648,599 / dim_date 6,940, which confirms
  the Warehouse OAuth binding survived. Residual verification is item 1 above.

- **Warehouse stored procedure definitions resynced** (`afe95db`, `9c71fe1`) — 10 of 12
  git-managed item definitions were pre-rename and would have shipped broken SQL through
  a Dev→Test promotion. See the `warehouse-procs-duplicated-in-git` memory; the
  same-commit rule is now in `CLAUDE.md`.
- **`10_ETL_fact_crashes_old` deleted** (`f01f79d`) — removed from repo and workspace.
- **`dim_date` rewritten set-based** (`afe95db`) — 29-minute `WHILE` loop replaced;
  range extended to 2030.
- **`vehicle_occupants` outliers capped** (`44ea207`) — with backfill.
- **Copy sink `storeSettings` normalized** — `Copy_Crashes_CDC` and `Copy_Persons_CDC`
  were `AzureBlobStorageWriteSettings` while writing to a `LakehouseLocation`;
  `Copy_Vehicles_CDC` was already correct.
- **`environment-reference.md` notebook/folder IDs corrected** — the original pass had
  recorded *logical* IDs from the repo's item files rather than physical Fabric IDs.
  Every notebook ID in the doc was wrong.
