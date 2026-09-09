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
