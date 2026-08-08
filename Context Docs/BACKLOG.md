# Backlog — NYC Motor Vehicle Collisions

> Working backlog for this Fabric build. Durable conventions belong in `CLAUDE.md`;
> live IDs belong in `environment-reference.md`. This file is only for work that is
> *not yet done*.
>
> Last reviewed: 2026-08-01.

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

## 3. `03_ETL_dim_date` Fabric item description is stale — OPEN

The workspace item description still reads "Generates date dimension rows from
2012-01-01 to 2026-12-31". As of `afe95db` the proc is set-based and runs to
**2030-12-31** (6,940 rows).

Item descriptions are not part of the git-managed definition, so this must be edited in
the Fabric UI (or via `update_notebook_definition`). Cosmetic, but it is the first thing
a reviewer reads.

---

## 4. Semantic model has no measures — OPEN, decision needed

`NYC_VehicleCrashes_Semantic` currently exposes tables and relationships but no explicit
DAX measures; visuals rely on implicit aggregation. For a portfolio-grade Kimball build
this is the most visible gap — a reviewer expects a measure layer.

Minimum credible set: total crashes, total persons involved, injuries, fatalities,
injury rate, crashes YoY / MoM, and an occupancy measure over `vehicle_occupants`.

Note the dependency: any occupancy measure is only trustworthy because of the cap
applied in `44ea207` — see the `vehicle-occupants-outliers` memory before writing one.

Measures are TMDL edits under `4_Model/`, so they follow the standard
local-edit → commit/push → Source Control Update All flow. Not MCP.

**This item is also the first real test of the `/tmdl-model-edit` skill**
(`.claude/skills/tmdl-model-edit/SKILL.md`, added 2026-08-08). The skill exists to stop the
plugin `semantic-model-authoring` skills from routing semantic model authoring through
`powerbi-modeling-mcp`. Writing the measure layer will show whether it is complete or still
needs the workflow restated by hand — update the skill with anything it turns out to be
missing.

---

## 5. `usp_load_dim_date` range extends past the fact data — OPEN, informational

`dim_date` now runs to 2030-12-31 while facts stop at the current CDC watermark. Future
dates with no facts are correct Kimball practice, but any date-axis visual will show a
long empty tail unless the report filters to dates that have data. Decide at report
authoring time; no code change implied.

---

## Recently closed

Kept only as context for the items above. Delete once stale.

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
