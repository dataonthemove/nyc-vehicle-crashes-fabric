# 02: Stage hygiene: dead variable, ADR-0003 amendment, glossary, branch-out pre-flight

**What to build:** Update the Variable Library, ADR-0003, the glossary and the branch-out guidance to match
how per-stage config works now that stage-load ticket 06 has shipped `warehouse_endpoint`. Ship it as one
commit. No Fabric changes. The only Variable Library change is removing a variable nothing reads.

This replaces issue 01 (`01-stage-hygiene-branch-out.md`). Retiring 01 is part of this ticket's scope. The
stage-load spec and ticket 06 items from 01 are no longer needed (archived). The endpoint gap is closed:
`warehouse_endpoint` exists, and ADR-0003 already records it.

**Blocked by:** None (can start immediately)

**Status:** done (2026-09-25)

## Acceptance criteria

- [x] **Dead variable removed:** delete `landing_lakehouse` from `vl_NYC_Crashes`, in the variable definitions and in any value set that overrides it. Verified 2026-09-25: nothing reads it. Dev reaches the landing lakehouse through the `raw_nyc_crashes` OneLake shortcut, whose target IDs are written into the Lakehouse shortcut metadata. The pipeline pulls in only `warehouse_endpoint`, and `RefreshSemanticModel` reads only `semantic_model_name` and `refresh_type`.
- [x] **ADR-0003 amendment:** append a dated **Amendment**, leaving the original text untouched. It records:
  - `stage_workspace_name` is gone and `RefreshSemanticModel` refreshes the model in its own workspace. The "wrong value set → silently refreshes the **Dev** model" warning is obsolete: a wrong active value set now only switches `refresh_type` between `calculate` and `full`, and points `warehouse_endpoint` at the wrong stage's Warehouse.
  - `landing_lakehouse` was removed as unused.
  - Value vs binding: the line between them is Fabric's behaviour, not meaning. A literal string is a *value*, even if it names an item. A reference Fabric rewrites on deploy is a *binding*. The SP `endpoint` is therefore a value. Reconcile this with the ADR's table row that calls it a "binding autobind can't handle".
- [x] **Glossary:** the Pipeline section of `CONTEXT.md` gains these terms:
  - **Stage-varying value**: A setting whose value differs between Dev, Test and Prod, and which Fabric treats as a literal. It lives in the stage's variable library.
  - **Binding**: A reference from one item to another that Fabric re-points to the target stage's item when it deploys.
  - **Active value set**: The set of variable values a stage's library currently serves. It is chosen by hand in each stage and never deployed.
  - **Branch workspace**: A feature workspace created by Git branch-out. It is *not* a stage: its bindings still point at Dev, and its active value set is Dev's.
  - **Default lakehouse**: The lakehouse a notebook resolves relative `Files/` and `Tables/` paths against. It is stored in the `# META` header of the notebook's git file. Autobind repoints it on deploy, but branch-out doesn't.
- [x] **Branch-out pre-flight doc:** new, short `Context/branch-out-preflight.md`. Before running anything in a branch workspace:
  - set `warehouse_endpoint` to the branch Warehouse's TDS host
  - repoint `nb_cdc_to_delta`'s default lakehouse (in its `# META` header) to the branch Lakehouse
  - after the first Ingest, refresh the branch SQL endpoint metadata
  - commit these changes on the branch only, and never merge them

  Main risk to state: a branch that changes Ingest logic runs a MERGE that rewrites Dev's Delta tables.
- [x] **Memory note** `branch_out_does_not_isolate.md` (outside the repo): drop the "Refresh would refresh the Dev model" claim and link `Context/branch-out-preflight.md`.
- [x] **Retire issue 01:** set `01-stage-hygiene-branch-out.md` to closed and superseded by 02, then archive the `03-stage-config-hygiene` folder under `.scratch/zz_Archive/` once 02 is done.
- [x] One commit: `CC Commit: stageconfig_hygiene_docs`
