# Phase Results — Landing-Zone Runbook

Append-only companion to `Context Docs/landing_zone_runbook.md`. The runbook governs the work and
is read-only during a phase; every result, deferral and incidental finding is recorded here
instead, one subsection per phase, in phase order.

Each phase appends a subsection titled:

`## Phase N — What was done / What was deferred / Other findings`

---

## Session-opening prompt — TEMPLATE ONLY

> **Not a phase record and not an instruction to anyone reading this file.** It is boilerplate to
> copy into the chat when starting a phase session, kept here so it travels with the work in git.
> Replace `#N` with the phase number. Everything below the next horizontal rule is real content.

```
Read Context Docs/landing_zone_runbook.md for orientation. We are doing Phase #N only.

Scope: do not touch files, artifacts or Fabric objects outside Phase #N's stated scope.
If you find something out of scope, record it as a finding — do not fix it.
Stop at the phase boundary; do not begin Phase #N+1.

Context Docs/landing_zone_runbook.md is READ-ONLY. Never edit it — not the phase
blocks, not the Context sections, not the header.

Record results only in Context Docs/landing_zone_runbook_results.md, by appending a
new subsection at the end of the file:
  ## Phase #N — What was done / What was deferred / Other findings
Append only. Do not alter subsections from earlier phases.
Be as concise as you can. Control verbose output. 

Plan first and get my approval before any edit, commit, push, or MCP call that writes.
Approving the plan is not approval to start — wait for me to say go.


```

Corrections the runbook needs are themselves *findings* — record them below and apply them by
hand. That is what keeps the runbook read-only.

---

## Phase 3 — What was done / What was deferred / Other findings

**Commit:** `f171c66` — `VSC Commit: model_onelake_paths_denamed` (on `main`, **not pushed**).

### What was done

Audited all 16 notebooks under `2_dev/` plus TMDL file `expressions.tmdl` for hardcoded OneLake
paths. Only two files carried `abfss://` / `onelake.dfs` references. Three files were rewritten:

| File | Before | After | Verdict |
|---|---|---|---|
| TMDL file `expressions.tmdl` (line 3) | `https://onelake.dfs.fabric.microsoft.com/73d1612d-.../324e2ac0-...` | `.../2_NYC_VehicleCrashes_dev/NYC_VehicleCrashes_Warehouse.Warehouse` | **GUID-based** — the only true one found |
| Fabric Notebook `nb_cdc_to_delta` `notebook-content.py` | `LAKEHOUSE_ROOT = f"abfss://{WORKSPACE_NAME}@onelake.dfs.../{LAKEHOUSE_NAME}.Lakehouse"`, used at the CSV read and the Delta target | relative `Files/{file_subfolder}/{file_pattern}` and `Tables/dbo/nyc_{source_name}` against the attached default lakehouse | name-based, but **stale and broken** |
| Fabric Notebook `RefreshSemanticModel` `notebook-content.py` (line 34) | `workspace="NYC_Motor_Vehicle_Collisions"` | `workspace="2_NYC_VehicleCrashes_dev"` | name-based, but **stale and broken** |

The two GUIDs in TMDL file `expressions.tmdl` were confirmed against
`Context Docs/environment-reference.md` as the Dev workspace and Dev Warehouse **physical** IDs —
not logical IDs.

### What was deferred

- **Push, Fabric sync and live validation.** Pat elected commit-only. Still outstanding, in order:
  `git push` → Fabric Source Control → Update tab → Update All → `refresh_semantic_model` on
  semantic model `NYC_VehicleCrashes_Semantic` (Direct Lake must reframe after the source
  expression changes) → CC skill `/dax-smoke-test` → one run of Fabric Notebook `nb_cdc_to_delta`
  to prove the relative paths resolve at runtime.
- The phase's **Done when** is therefore only partly satisfied: no GUID-based path remains and the
  rewrite is committed, but "the affected notebooks run clean" is unverified.

### Other findings (recorded, not fixed)

1. **Both stale names are a consequence of the workspace rename.** The Dev workspace is
   `2_NYC_VehicleCrashes_dev` (MCP `list_workspaces`, 2026-09-08); the old names
   `NYC_VehicleCrashes` and `NYC_Motor_Vehicle_Collisions` no longer resolve. Fabric Notebook
   `nb_cdc_to_delta` and Fabric Notebook `RefreshSemanticModel` were both broken at HEAD before
   this commit — a name-based path is not automatically a portable path.
2. **Every notebook META block pins Dev by GUID.** `default_warehouse`
   `da2b14e1-b933-a3f7-47de-f697ddedf601` appears in all 15 T-SQL/Jupyter notebooks and
   `default_lakehouse` `69699b13-...` in Fabric Notebook `nb_cdc_to_delta`. These are Fabric item
   bindings, not code paths; the deployment pipeline remaps them per stage. Left alone
   deliberately — editing them would fight Fabric's own serialization.
3. **Fabric may re-serialize the TMDL expression back to GUID form** after Update All. If the
   Source Control pane flags semantic model `NYC_VehicleCrashes_Semantic` as Modified with the URL
   reverted to GUIDs, that is service-side canonicalization, not drift to fight — classify per
   `CLAUDE.md` and expect the name-based form to be unstable.
4. **Fabric Pipeline `pipeline-content.json` is already portable** — its warehouse and lakehouse
   references carry `"workspaceId": "00000000-0000-0000-0000-000000000000"` (resolve-in-current-
   workspace) with logical artifact IDs. Out of Phase 3 scope; no action needed, and Phase 6
   rebuilds it anyway.
5. **Runbook correction (apply by hand).** Phase 3's *Scope* line names Fabric Notebook
   `nb_cdc_to_delta` and TMDL file `expressions.tmdl` as the known carriers. It should also name
   Fabric Notebook `RefreshSemanticModel` under repo folder `2_dev/Misc_Fabric_Items/`, and the
   phase's framing should read "hardcoded workspace/item references", not "OneLake paths" alone —
   the stale `workspace=` argument is neither `abfss://` nor GUID-based, yet it is exactly the
   deployment-portability defect this phase exists to catch.
6. **`sed -i` rewrites CRLF to LF on Windows.** All three files were restored to CRLF before
   staging; `core.autocrlf` kept the index clean either way. Relevant to any future scripted edit
   of Fabric-exported files.

### Phase 3 — addendum: the TMDL rewrite was reverted

Pushing `f171c66` and running Update All failed on semantic model `NYC_VehicleCrashes_Semantic`:

```
Dataset_Import_FailedToImportDataset
Direct Lake mode requires a Direct Lake data source. Tables in Direct Lake mode must be the
SQL or OneLake datasource kind. Please verify and fix the data source definitions of the
following Direct Lake tables: dim_damage, dim_person, dim_location, ...
(dataset id 646ec529-eaaa-4d41-b3b0-a31c94355fdd)
```

**Finding — a name-based OneLake URL is not a valid Direct Lake data source.** The Analysis
Services engine classifies the datasource kind by URL shape: only the
`.../{workspaceGuid}/{itemGuid}` form registers as OneLake. Rewriting it to
`.../2_NYC_VehicleCrashes_dev/NYC_VehicleCrashes_Warehouse.Warehouse` demoted every Direct Lake
table to an unsupported kind and the import was rejected wholesale. The URL is valid for OneLake
filesystem access — it is not valid *here*.

**Action taken:** TMDL file `expressions.tmdl` reverted to the original GUID URL, byte-identical
to `79f9d73`. The two notebook fixes in `f171c66` stand — those were genuine defects.

**Runbook correction (apply by hand).** Phase 3's *A finding triggers* line — "rewrite GUID-based
paths to name-based" — must carve out the semantic model's Direct Lake expression. That GUID pair
is not portability debt and must not be de-GUID'd. Test and Prod reach their own warehouse because
the deployment pipeline rewrites the Direct Lake binding at deploy time; that is the supported
mechanism, and Phase 10/11 depend on it rather than on the URL being stage-neutral. Phase 3's
**Done when** ("no GUID-based OneLake path remains under `2_dev/`") is unsatisfiable as written and
should read "no GUID-based OneLake path remains outside the Direct Lake expression".

**Net Phase 3 outcome:** two notebooks de-named and fixed; the semantic model deliberately
unchanged; one runbook rule proven wrong by execution.

### Phase 3 — addendum 2: validation complete

After the revert was pushed and Update All succeeded:

| Check | Result |
|---|---|
| `refresh_semantic_model` (full) on semantic model `NYC_VehicleCrashes_Semantic` | Completed, refresh id 445777540, no exception |
| Fact row counts | fact_crashes 2,269,187 · fact_persons 5,984,110 · fact_crash_vehicle 4,551,002 · bridge_crash_factor 1,648,599 · dim_collision 2,269,187 · dim_date 6,940 |
| Bridge cross-filter | Live — per-factor crash counts differ (Driver Inattention/Distraction 489,682; Failure to Yield 147,190), not the full fact count |
| Fabric Notebook `nb_cdc_to_delta`, `source_name=crashes` | Job `dc0e1fee-a04d-409c-b497-baebbfa94c1d` Completed in 70s, no failure reason — the relative `Files/` read resolved against the attached default lakehouse |

Phase 3 **Done when** is now satisfied as amended (see addendum 1): no GUID-based OneLake path
remains under `2_dev/` outside the Direct Lake expression, the rewrite is committed, and the
affected notebook runs clean.

Minor finding: the bridge has no `crash_key` column — its columns are `bridge_id`,
`factor_group_key`, `factor_key`. A smoke-test query written against `crash_key` fails with
"cannot be found or may not be used in this expression". Worth correcting in CC skill
`/dax-smoke-test` if that name appears there.

---

## Phase 4 — What was done / What was deferred / Other findings

### What was done

| Check | Result |
|---|---|
| Fabric Lakehouse item | `NYC_VehicleCrashes_Landing_Lakehouse` (`b7f1c383-0af0-4b21-bf6b-4ac398b84391`) in workspace `1_NYC_VehicleCrashes_Landing`; SQLEndpoint `ef5d1260-…` carries the same name |
| `Files/raw/` | Created — holds a zero-byte `.keep` sentinel (MCP `upload_lakehouse_file`) |
| Role assignments (Fabric REST GET) | `Jpb_fabric_user7` · User · **Admin** — sole principal |
| Git | Item present at repo folder `1_Landing/NYC_VehicleCrashes_Landing_Lakehouse.Lakehouse/` (`.platform`, `alm.settings.json`, `lakehouse.metadata.json`, `shortcuts.metadata.json`) on `origin/main` at `bd3894d`; pulled locally by rebase |

The lakehouse **pre-existed** in the landing workspace as `NYC_VehicleCrashes_Lakehouse` (empty,
uncommitted). Pat renamed it in the Fabric UI rather than creating a second item — MCP `rename_item`
is deny-listed in repo file `.claude/settings.json`, and a `create_lakehouse` call would have left a
stray. No item was created or deleted in this phase.

Phase 4 **Done when** is satisfied.

### What was deferred

- **Viewer (all consuming stages) — not assigned, and not assignable as written.** Fabric workspace
  role assignments take principals (user / group / service principal), never another workspace, and
  this trial tenant has exactly one principal. Dev/Test/Prod reach landing under the same `user7`
  identity, which is already Admin, so shortcut reads in Phases 7/10/11 are unblocked. Revisit only
  if a second principal or an Entra security group is introduced.

### Other findings (recorded, not fixed)

1. **Runbook correction (apply by hand).** Phase 4's membership line ("Viewer (all consuming
   stages)") should name a principal or group, or be struck. As written it describes an object Fabric
   RBAC cannot express.
2. **Nothing pending in the Source Control pane is the correct state.** Fabric had already committed
   the renamed item (`bd3894d`, 2026-09-09 21:14:56 UTC); Fabric REST `GET git/status` returned
   `changes: []` with `workspaceHead == remoteCommitHash`. Also note OneLake `Files/` content is
   **never** Git-tracked, so creating `Files/raw/` can never surface as a pending change — only item
   metadata does.
3. **`Files/raw/` cannot exist empty in OneLake.** The `.keep` sentinel holds the path until Phase 6
   lands data; it is harmless to the shortcut contract (Context 2 targets `Files/raw/`) but should be
   ignored by any future file-pattern read.
4. **Repo file `1_Landing/placeholder` is now redundant** — it seeded the folder before the item
   existed. Left in place: deleting it is out of Phase 4 scope.
5. **Local `main` was 1 ahead / 3 behind `origin/main`** on entry; the three remote commits were
   Fabric's own workspace commits. Rebased, not merged. `main` remains unpushed by 1 commit at the
   end of this phase.

---

## Phase 5 — What was done / What was deferred / Other findings

### What was done

| Item | Result |
|---|---|
| Fabric Notebook `nb_etl_watermark` (PySpark) | Authored at repo folder `1_Landing/nb_etl_watermark.Notebook/`; synced to workspace `1_NYC_VehicleCrashes_Landing` as item `f475e1ca-b96e-4bb6-bc82-759f435e46fb`. Modes: `seed` \| `advance` \| `read`, plus `source_name`/`new_value`/`seed_value` in a parameters cell |
| Delta table `etl_watermark` | Created in Fabric Lakehouse `NYC_VehicleCrashes_Landing_Lakehouse` (`Tables/etl_watermark`), schema `source_name STRING`, `last_loaded_value TIMESTAMP`, `last_run_utc TIMESTAMP` — mirrors Warehouse table `dbo.etl_watermark` |
| Run 1 (`90f1b7dc-…`) | Completed, 48s |
| Run 2 (`b7bacb88-…`) | Completed, 71s — idempotence check |
| Livy read-back | 3 rows; `crashes`/`persons`/`vehicles` all `last_loaded_value = 1900-01-01 00:00:00`; all three `last_run_utc = 2026-09-09 22:31:28`, i.e. run 1 only. `DESCRIBE HISTORY` = 2 versions (create + one merge): run 2 wrote nothing |
| Repo file `CLAUDE.md` | Watermark rule rewritten in the same commit as the notebook (`131e9a7`): landing lakehouse Delta is authoritative, PySpark is the only writer, Warehouse copy stays legacy until the Phase 6 cutover |

Seeding is a Delta `MERGE … whenNotMatchedInsertAll`, so a re-run can never reset an advanced
watermark. Phase 5 **Done when** is satisfied.

### What was deferred

- **Nothing reads the new table yet.** Fabric Pipeline `pl_cdc_NYC_Crashes` still reads and writes
  Warehouse `dbo.etl_watermark`; the cutover, including swapping the Script activity for this
  notebook, is Phase 6 by design.
- **The `advance` mode is untested against a real load.** It is exercised only by construction;
  Phase 6's first landing run is its real test.
- **Parameters cell is not tagged.** Fabric requires a manual UI toggle (… > Toggle parameter cell)
  before a pipeline Notebook activity can override `mode`/`source_name`/`new_value`. Do it at the
  start of Phase 6 or the pipeline will silently run with defaults (`mode="seed"`).

### Other findings (recorded, not fixed)

1. **A new git-authored Fabric item needs an explicit `logicalId`.** Omitting it from `.platform` —
   on the documented reading that Fabric generates one for new items — made Update All fail with
   "missing or corrupted files", `DirectoryNames [/1_Landing/nb_etl_watermark.Notebook]`
   (Request ID `2d53db6e-7436-49a9-8503-22369163241b`). Adding a generated GUID (`f6d417c0-…`,
   commit `95c9f34`) fixed it. Worth carrying into any future hand-authored item folder.
2. **`Bash(git push:*)` is deny-listed in global `~/.claude/settings.json`**, so CC cannot push;
   every phase needs Pat to run `git push origin main` by hand between the commit and the Fabric
   Update. Not a defect — noting it because it silently makes CC's "committed" ≠ "visible to Fabric".
3. **Out of scope, left alone (Phase 6):** Fabric Notebook `000_DDL_ETL_Watermark_Seed` under repo
   folder `2_dev/1_DDL/` still creates and seeds the Warehouse table and will contradict the new
   rule once the cutover lands; Warehouse table definition `2_dev/0_NYC_VehicleCrashes_Warehouse.Warehouse/dbo/Tables/etl_watermark.sql`
   likewise. Both are retirement candidates, not edits for this phase.
4. **Repo file `1_Landing/placeholder` is still redundant** (carried over from Phase 4).

---

## Phase 6 — What was done / What was deferred / Other findings

**Commits (all on `main`, pushed):** `ec8a1d9` · `3651428` · `9333045` · `a13bb5f` · `1c39af6` ·
`291d280`. Fabric Pipeline `pl_cdc_NYC_Crashes` in Dev was **not** touched.

### What was done

Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` authored at repo folder
`1_Landing/pl_cdc_NYC_Crashes_Landing.DataPipeline/` and synced to workspace
`1_NYC_VehicleCrashes_Landing` (item `483fda7f-6fc2-4034-9cda-9f28f506515c`). Seven activities:
`Read_Watermarks` → three parallel `Copy_*_CDC` (Socrata HTTP → `Files/raw/{crashes,persons,vehicles}`)
→ three chained `Advance_Watermark_*`. Delta building was deliberately **not** copied into landing —
Context 2 makes it a per-stage concern (Phase 7).

| Check | Result |
|---|---|
| Full run `06db7dc7-3c8a-46ee-830f-6e2f830db867` | **All 7 activities Succeeded**, no retries, 13:02–13:07 UTC |
| Landing row counts (Livy, `Files/raw/*`) | crashes 2,269,187 · persons 5,984,110 · vehicles 4,551,002 |
| Dev Delta counts (Phase 3 addendum 2) | 2,269,187 · 5,984,110 · 4,551,002 — **exact match** |
| Landed volume | 2.9 GB, one data file per source |
| Watermark | Seed `1900-01-01` consumed by the first loading run `51aa9a9e`; advanced to run time thereafter |

Phase 6 **Done when** is satisfied: a full run succeeded end to end and landing row counts match the
Dev Lakehouse Delta counts.

### What was deferred

- **Deleting Fabric Pipeline `pl_cdc_NYC_Crashes` from Dev — Pat's call, not done.** It remains the
  rollback per the runbook, MCP `delete_item` is deny-listed, and the repo folder
  `2_dev/2_Ingest/pl_cdc_NYC_Crashes.DataPipeline/` is likewise untouched. Delete the workspace item
  and the repo folder together when satisfied.
- **Warehouse `dbo.etl_watermark` retirement.** The landing Delta table is now the live store for
  landing ingestion, but the Dev pipeline still reads and writes the Warehouse copy. Retire both it
  and Fabric Notebook `000_DDL_ETL_Watermark_Seed` when the Dev pipeline goes (carried from Phase 5).
- **Positive incremental (CDC delta) test.** Verified only in the negative: with the watermark at
  2026-09-10T12:45:14 the reruns fetched zero rows (header-only sink files, ~25s per Copy), proving
  the `$where crash_date > watermark` filter narrows. No source rows exist newer than that watermark,
  so a load of *some but not all* rows was never observed. Prove it by rolling one source's watermark
  back a few days (Fabric Notebook `nb_etl_watermark`, `mode=advance`) and rerunning, or by waiting
  for the next Socrata publish.
- **Service-principal connection auth.** The sink authenticates as `Jpb_fabric_user7` through a
  user-owned OAuth connection. Production-correct is an SP, which needs a tenant setting, an Entra
  app and role assignments on four workspaces — out of scope with the trial expiring ~28 Sep.

### Other findings (recorded, not fixed)

1. **A Lookup on the lakehouse SQL analytics endpoint cannot be authored from Git.** The endpoint is
   not a Git item, so Update All rejected the pipeline: `MissingDependencies [ArtifactType:
   'Warehouse' DependencyId: 'ef5d1260-…']`. **Runbook correction (apply by hand):** Phase 6's
   "repoint the watermark read at the lakehouse SQL endpoint" is unsatisfiable under code-first
   authoring. The watermark is instead read by running Fabric Notebook `nb_etl_watermark` in
   `mode="read"`, which now exits a JSON map; the Copies consume it via
   `@{json(activity('Read_Watermarks').output.result.exitValue).<source>}`. The SQL endpoint remains
   valid for interactive/downstream reads — just not as a pipeline dependency in Git.
2. **The Lakehouse connection's stored OAuth consent, not workspace RBAC, gates Copy writes.**
   Connection `Lakehouseconnection` (`92d1dbb4-…`, created 2026-06-13) is owned by `Jpb_fabric_user7`,
   who is workspace Admin on landing — yet every Copy failed `LakehouseForbiddenError` on
   `b7f1c383-…/Files/raw/…` across three runs. Re-consenting the connection's credentials in Manage
   connections and gateways fixed it outright, with no JSON change. A Fabric connection carries its
   own consent, scoped at creation time; RBAC cannot rescue it. Expect this on every new workspace.
3. **Notebook-activity parameter shape is unforgiving, and Fabric's own UI emits an invalid one.**
   The working form is `"new_value": {"value": {"value": "@…", "type": "Expression"}, "type": "string"}`.
   Fabric's UI commit produced outer `"type": "Expression"`, which the runtime rejects at submission —
   the whole pipeline fails in ~2s with `RequestExecutionFailed / BadRequest` and no activity runs.
   Flattening to a bare expression fails differently: the value resolves to `9/10/2026 11:57:04 AM`
   and the activity fails converting it to `RunNotebookParameter`.
4. **Parallel watermark advances race on Delta.** Three concurrent MERGEs against the single-file
   `etl_watermark` table produced `ConcurrentAppendException` on two of three. Fixed by chaining the
   three `Advance_Watermark_*` activities on a `Completed` dependency plus retry 2 @ 60s. Any future
   fan-out writing this table needs the same treatment.
5. **Zero-row Copy runs still write header-only files.** `Files/raw/crashes` now holds two 649-byte
   header-only files alongside the 600 MB data file (persons and vehicles one each), from runs where
   the watermark was already current. Harmless to the Spark reader (headers match, 0 rows) but the
   folder accumulates one such file per no-op run. Worth a cleanup rule before Phase 7's shortcut
   goes live. `Files/raw/.keep` from Phase 4 is likewise still present.
6. **The watermark advances to run time, not to the maximum `crash_date` loaded.** Inherited verbatim
   from the Dev pipeline's Script activity (`SYSUTCDATETIME()`). Any row whose `crash_date` falls
   between the last loaded row and the run timestamp is skipped permanently. Not introduced by this
   phase; it is now reproduced in the landing zone and should be fixed before the cadence work in
   Phase 12.
7. **`.txt` vs `.csv` sink extension.** The Fabric destination dialog defaults to `.txt` (and showed
   File format `Avro` on reopen — do not re-save that dialog blind). All three sinks were set back to
   `.csv` in Git to match the Dev pipeline and keep `Files/raw/` honest for Phase 7 readers.
8. **Pipeline naming.** The landing pipeline is `pl_cdc_NYC_Crashes_Landing`, not a same-named twin of
   the Dev item — the landing workspace is never a deployment-pipeline stage, so the suffix costs
   nothing and removes ambiguity in logs and prose.

---

## Phase 7 — What was done / What was deferred / Other findings

**Commits:** `29c653d` (on `main`, pushed by Pat). Runbook not edited.

### What was done

| Step | Result |
|---|---|
| Shortcut `raw_nyc_crashes` | Created by Pat in the Fabric UI at Dev Lakehouse `NYC_VehicleCrashes_Lakehouse` `Files/`, targeting landing `NYC_VehicleCrashes_Landing_Lakehouse` `Files/raw/` (Context 2 contract) |
| Shortcut read check (Livy) | CSV rows 2,269,187 / 5,984,110 / 4,551,002 — equal to Dev Lakehouse Delta and Phase 6 landing counts |
| Fabric Notebook `nb_cdc_to_delta` | Restored from `293f3e1^` to repo folder `2_dev/2_Ingest/`; default `file_subfolder` → `raw_nyc_crashes/crashes`; synced to Dev (item `0b138bcd-…`) |
| Delta rebuild | crashes: notebook job `7ce3885c-…` Completed. persons/vehicles: same logic via Livy (see Deferred). 100% of rows in all three `dbo.nyc_*` tables now carry a `_source_file` under `Files/raw_nyc_crashes/`; totals unchanged |
| Dev raw files cleared | `Files/NYC_CrashData/` deleted (9 files, 2.9 GB). Landing held byte-identical data files, so no OneLake copy was taken. Dev `Files/` now holds only the shortcut |
| Transformations | Fabric Notebooks `04`–`13` (incl. `09b`) run in three dependency waves; all 11 jobs Completed |
| Warehouse counts (Livy, OneLake path) | All 13 `dbo` tables equal the pre-phase baseline, e.g. `fact_crashes` 2,269,187 · `fact_persons` 5,984,110 · `fact_crash_vehicle` 4,551,002 · `bridge_crash_factor` 1,648,599 |

Phase 7 **Done when** is satisfied.

### What was deferred

- **Parameters cell in Fabric Notebook `nb_cdc_to_delta` is still untagged.** Job parameter overrides are ignored,
  so only the default (`crashes`) could run as a job; persons/vehicles ran through Livy. Toggle the
  parameters cell in the UI (then commit that change) before any pipeline or Phase 10 run depends on it.
- **Nothing orchestrates Dev any more.** Fabric Pipeline `pl_cdc_NYC_Crashes` is gone (below), so Delta build and
  transforms are manual runs. A Dev orchestration pipeline is out of Phase 7 scope.

### Other findings (recorded, not fixed)

1. **Workspace commit `293f3e1` (2026-09-10) deleted the Dev copies** of Fabric Pipeline `pl_cdc_NYC_Crashes`,
   Fabric Notebook `nb_cdc_to_delta` and Fabric Notebook `000_DDL_ETL_Watermark_Seed`. That closes the Phase 6 deferral for
   the pipeline, but it also removed the only Delta builder. Phase 7 restored the notebook only.
2. **Shortcuts *are* Git-serialized.** Repo file `2_dev/0_NYC_VehicleCrashes_Lakehouse.Lakehouse/shortcuts.metadata.json`
   captures the shortcut, contradicting Context 2 ("not in Git"). Left uncommitted per Pat's call, so the
   Lakehouse stays flagged Modified in Source Control. Unverified risk: a future Git change to that file
   might remove the live shortcut on Update All. Since every stage targets the same landing lakehouse,
   committing it could let the deployment pipeline carry the shortcut — decide in Phase 8/9.
3. **Fabric names a new shortcut after its target folder (`raw`)** by default; it had to be renamed to
   `raw_nyc_crashes`. Expect the same in Phases 10–11.
4. **Transform reruns leave no Delta evidence.** Every `usp_load_*` inserts with `NOT EXISTS`; unchanged
   input means zero-row inserts and no new Delta commit (last commits are dated 2026-08-01). Unchanged counts
   are the expected result, but they cannot on their own prove a proc executed.
5. **`DESCRIBE HISTORY` on Warehouse `dim_date` hangs** — presumably from its thousands of `WHILE`-loop commits.
   Use plain counts on that table.
6. **Header-only files now flow into Dev Delta reads** (three in landing `Files/raw/`). Harmless (0 rows);
   the Phase 6 cleanup-rule finding still stands.

---

## Phase 8 — What was done / What was deferred / Other findings

**Commits:** `f9461bb` · `caed793` (on `main`, pushed by Pat). Runbook not edited.

**Decision: Variable Library.** Criterion 1 alone would have justified Deployment Rules. The only
non-binding stage-varying value was one literal, and every other difference is an item binding the
deployment pipeline remaps. Pat chose a Variable Library on Git visibility (criterion 2), matching the
runbook default and the emerging Fabric standard. Split of responsibility:

| Value | Handling |
|---|---|
| Stage workspace name, semantic model name, refresh type, landing lakehouse reference | Variable Library `vl_NYC_Crashes` |
| Default warehouse of the 15 notebooks, `nb_cdc_to_delta` default lakehouse, Direct Lake expression, report → model | Deployment autobind; Deployment Rules as fallback |
| Stored-procedure lakehouse names, shortcut target, capacity | Stage-invariant; nothing needed |

### What was done

| Step | Result |
|---|---|
| Variable Library `vl_NYC_Crashes` | Authored at repo folder `2_dev/vl_NYC_Crashes.VariableLibrary/`; synced to Dev (item `41f320eb-…`). Default value set = Dev; `Test` and `Prod` override `stage_workspace_name` and `refresh_type` (`full`, to reframe Direct Lake after a deploy). `landing_lakehouse` is an ItemReference to landing `b7f1c383-…` |
| Consumer | Fabric Notebook `RefreshSemanticModel` reads all three values via `notebookutils.variableLibrary.getLibrary`; no literals remain |
| Validation | Job `04ecba97` Failed (see finding 1). After the fix, job `60698402` **Completed**. The notebook raises unless the refresh returns `Completed`, so success proves both the library read and the refresh |

Phase 8 **Done when** is met for the mechanism: it holds every stage-varying value that isn't a
binding. The "written into this runbook" half is not done, because the runbook is read-only for CC.

### What was deferred

- **Copy the decision above into the runbook** (Pat, by hand).
- **Wiring shortcut `raw_nyc_crashes` to `landing_lakehouse`.** The variable exists but nothing consumes it.
  Variable-library-backed shortcuts are a preview feature, and wiring one means committing repo file
  `shortcuts.metadata.json` (Phase 7 finding 2). Decide in Phase 9.
- **Active value set per stage.** Deployment never carries it; after the first deploy, set `Test` and
  `Prod` by hand in Phases 10 and 11, or those stages silently run with Dev's workspace name.
- **Autobinding is unproven.** The notebook bindings and the Direct Lake expression can only be tested
  by the Phase 10 deploy; add Deployment Rules only for whichever fails.

### Other findings (recorded, not fixed)

1. **`sempy_labs` is not preinstalled.** Fabric Notebook `RefreshSemanticModel` had never run (0 prior runs);
   job `04ecba97` failed after 19s with `System_Cancelled_Session_Statements_Failed`. Livy confirmed
   `sempy_labs` is absent from the Spark runtime and `sempy` is present. Fixed in `caed793` by switching to
   the built-in `sempy.fabric.refresh_dataset` plus a status poll (in scope: the notebook is the
   library's only consumer).
2. **Python-notebook job failures leave no driver log reachable through MCP.** `get_notebook_driver_logs`
   returns 404 (`unknown app`). Diagnose through Livy instead.
3. **`notebookutils.variableLibrary` fails from a Livy session** (`discoverVariables` request fails;
   the session is keyed to a lakehouse, not a notebook). Test library reads through a notebook job, not
   Livy.
4. **`Context Docs/environment-reference.md` names the landing lakehouse `NYC_VehicleCrashes_Lakehouse`**; live
   (MCP `list_items`) it is `NYC_VehicleCrashes_Landing_Lakehouse`. The IDs match.
5. **Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` description is stale.** It still says the watermark is read
   from the SQL endpoint; Phase 6 finding 1 replaced that with Fabric Notebook `nb_etl_watermark`.
6. **Fabric Notebook `RefreshSemanticModel` sits in repo folder `2_dev/Misc_Fabric_Items/`.** It refreshes
   semantic model `NYC_VehicleCrashes_Semantic`, so it belongs beside the model in repo folder `2_dev/4_Model/`.
   Move it as a git folder move, not in the Fabric UI. Its `default_warehouse` binding is unused by its code.
7. **Warehouse population is still manual (carried from the Phase 7 deferral).** Recommend a new Dev
   pipeline, promoted Dev → Test → Prod. Keep it separate from Fabric Pipeline `pl_cdc_NYC_Crashes_Landing`,
   because landing is never a deployment stage. Order: Fabric Notebook `nb_cdc_to_delta` ×3
   (crashes/persons/vehicles) → Fabric Notebooks `04`–`13` in dependency waves → Fabric Notebook `RefreshSemanticModel`.
   Prerequisite: tag the parameters cell in `nb_cdc_to_delta` (Phase 7 deferral).

---

## Phase 9 — What was done / What was deferred / Other findings

**Commits:** results file only. A deployment pipeline is not a Git item. Runbook not edited.

### What was done

| Step | Result |
|---|---|
| Pre-flight | Signed in as `Jpb_fabric_user7`. No deployment pipeline existed. All four workspaces are type `Workspace`, not Template App (Context 4). Test and Prod hold 0 items |
| Fabric deployment pipeline `dp_NYC_VehicleCrashes` | Created via Fabric REST (`az rest`, no MCP tool exists): `df1e3e42-ea3a-4c74-9567-a63a7bc1898f` |
| Stage assignment | Development → `2_NYC_VehicleCrashes_dev` · Test → `3_NYC_VehicleCrashes_test` · Production → `4_NYC_VehicleCrashes_prod`. Landing workspace not assigned |
| Verification | GET `/stages` returns exactly those three workspaces. Nothing was deployed |

Phase 9 **Done when** is satisfied.

### What was deferred

- **Shortcut wiring decision (Phase 8 deferral) is carried to Phase 10.** It covers committing repo file
  `shortcuts.metadata.json` and pointing shortcut `raw_nyc_crashes` at `vl_NYC_Crashes`. Pat ruled it out of
  Phase 9 scope. Decide before the first deploy, since the deploy may or may not carry the shortcut.

### Other findings (recorded, not fixed)

1. **`Context Docs/environment-reference.md` doesn't record the deployment pipeline.** Add Fabric deployment
   pipeline `dp_NYC_VehicleCrashes` `df1e3e42-…` and its stage IDs (Development `e7887720-…`, Test `a0ab3671-…`,
   Production `314d8788-…`).
2. **All stages were created `isPublic: false`.** No deployment depends on this. Revisit if Prod content needs
   to be shared as a published app stage.
3. **Runbook header is stale.** It still says "Current phase: 3"; the Phase 3–9 checkboxes are unticked.
   Update by hand.
