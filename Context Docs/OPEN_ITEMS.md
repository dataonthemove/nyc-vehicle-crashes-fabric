# Open Items — NYC Motor Vehicle Collisions

> Working backlog for this Fabric build. Durable conventions belong in `CLAUDE.md`;
> live IDs belong in `environment-reference.md`. This file is only for work that is
> *not yet done*.
>
> Last reviewed: 2026-08-01.

Statuses: **OPEN** · **BLOCKED** · **DONE** (kept briefly for context, then deleted).

---

## 1. Recreate the 5 Fabric connections under the new account — OPEN, deadline-bound

**Owner: Pat only.** Requires interactive Fabric auth; cannot be done via MCP or from
Claude Code.

The 5 connections in `environment-reference.md` (2 OAuth — Warehouse and Lakehouse;
3 anonymous HTTP — Crashes, Persons, Vehicles) are owned by the account being
deprovisioned. When that account goes away, `pl_cdc_NYC_Crashes` stops running and the
Direct Lake model loses its Warehouse binding.

**Do before deprovisioning:**

1. Sign in as the new account, recreate all 5 connections.
2. Repoint the pipeline's three Copy sources, three sinks, and the Script activity.
3. Repoint the semantic model's Warehouse connection.
4. Run the pipeline end-to-end, then `/dax-smoke-test`.
5. Update the connection IDs in `environment-reference.md`.

This is the only item on this list with an external deadline. Everything else can wait.

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

---

## 5. `usp_load_dim_date` range extends past the fact data — OPEN, informational

`dim_date` now runs to 2030-12-31 while facts stop at the current CDC watermark. Future
dates with no facts are correct Kimball practice, but any date-axis visual will show a
long empty tail unless the report filters to dates that have data. Decide at report
authoring time; no code change implied.

---

## Recently closed

Kept only as context for the items above. Delete once stale.

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
