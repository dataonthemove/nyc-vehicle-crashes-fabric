# 01: Stage  hygiene: values vs bindings, stale docs, branch-out pre-flight

**What to build:** Bring the Variable Library, ADR-0003, the stage-load spec, the glossary and the
branch-out guidance into line with how per-stage config actually works today. Ship it as one commit.
No Fabric changes, and no Variable Library change beyond removing an unused variable.

**Blocked by:** none

**Status:** ready-for-agent

> Generated from a grilling session on 2026-09-23 about Variable Library use and branch-out isolation.

## Findings (verified 2026-09-23)

- `vl_NYC_Crashes` has 3 variables. Only `refresh_type` varies by stage. `landing_lakehouse` is never read,
  and the sole consumer, `RefreshSemanticModel`, reads only `semantic_model_name` and `refresh_type`.
- `stage_workspace_name` was removed from the library. `RefreshSemanticModel` passes no workspace, so it
  refreshes the model in its own workspace. ADR-0003's warning "wrong value set → silently refreshes the **Dev**
  model" is obsolete: a wrong active value set now only changes `calculate` vs `full`.
- The 12 Stored Procedure activities in `pl_stage_load_NYC_Crashes` carry a literal Dev TDS `endpoint`.
  Nothing rebinds it today. Ticket 06 of `.scratch/stage-load-pipeline/` tests this.
- Branch-out risk (ticket 04) is accepted for now, because Pat works solo and rarely branches out. The real
  exposure is a branch that changes Ingest logic, since its MERGE then rewrites Dev's Delta tables. A Variable
  Library can't guard against this, because a branch workspace's active value set is Dev's.

## Decisions

- **Keep ADR-0003's split.** Stage-varying values go in the Variable Library. Bindings go to autobind, then to Deployment Rules.
- **The line between them is Fabric's behaviour, not meaning.** A literal string is a *value*, even if it
  names an item. A reference Fabric rewrites on deploy is a *binding*. The SP `endpoint` is therefore a value.
- **Endpoint gap: wait for evidence.** Wait for ticket 06. If the endpoint doesn't rebind, use one library variable per stage.
- **Not doing:** runtime lakehouse resolution in `nb_cdc_to_delta`. It's not logged as an issue. No Variable Library change before ticket 06 produces evidence.

## Acceptance criteria

- [ ] `2_dev/99_Config/vl_NYC_Crashes.VariableLibrary/variables.json`: `landing_lakehouse` removed
- [ ] `docs/adr/0003-variable-library-for-stage-config.md`: dated **Amendment (2026-09-23)** appended, original text untouched. It records:
  - `stage_workspace_name` is gone, so a wrong active value set now affects only `refresh_type`
  - the value-vs-binding rule above
  - the SP `endpoint` is a value
- [ ] `.scratch/stage-load-pipeline/spec.md` Test 4 (and its Further Notes "Active value set" bullet) reworded. The Dev-refresh trap is obsolete; the check now guards `refresh_type`
- [ ] `.scratch/stage-load-pipeline/issues/06-promote-to-test.md`: the SP checkbox's fix path reads "library variable per stage (the endpoint is a value, ADR-0003 amendment)". It replaces "Deployment Rule or Variable Library item reference"
- [ ] `CONTEXT.md` *Pipeline* section gains these four terms, verbatim:
  - **Stage-varying value**: A setting whose value differs between Dev, Test and Prod, and which Fabric treats as a literal. It lives in the stage's variable library.
  - **Binding**: A reference from one item to another that Fabric re-points to the target stage's item when it deploys.
  - **Active value set**: The set of variable values a stage's library currently serves. It is chosen by hand in each stage and never deployed.
  - **Branch workspace**: A feature workspace created by Git branch-out. It is *not* a stage: its bindings still point at Dev, and its active value set is Dev's.
- [ ] New `Context/branch-out-preflight.md`, short. Before running anything in a branch workspace:
  - repoint each SP activity `endpoint` to the branch Warehouse's TDS host
  - repoint `nb_cdc_to_delta` META `default_lakehouse` / `default_lakehouse_workspace_id` to the branch Lakehouse
  - after the first Ingest, refresh the branch SQL endpoint metadata
  - commit these repoints on the branch only, and never merge them
- [ ] Memory note `branch_out_does_not_isolate.md` (outside the repo):
  - drop the "Refresh would refresh the Dev model" claim
  - link `Context/branch-out-preflight.md`
- [ ] One commit: `CC Commit: stageconfig_hygiene_docs`
