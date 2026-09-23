# ADR-0003: Stage-varying values live in a Variable Library; item bindings stay with deployment

- **Status:** Accepted
- **Date:** 2026-09-11
- **Context:** landing-zone build, Phase 8; proven in Phases 10–11

## Context

Promoting Dev → Test → Prod needs some values to differ per stage. Fabric offers two mechanisms:

- a **Variable Library**, a Git-managed item that is reviewable in a PR;
- **Deployment Rules**, which are workspace-side config, invisible to the repo and re-entered by hand per stage.

## Decision

**Use Variable Library `vl_NYC_Crashes` for every stage-varying *value*, chosen for its Git visibility.
Leave item *bindings* to deployment autobind, with Deployment Rules as the fallback.**

| Kind | Examples | Mechanism |
|---|---|---|
| Values | stage workspace name, semantic model name, refresh type, landing lakehouse reference | `vl_NYC_Crashes`: default value set = Dev; `Test` and `Prod` override |
| Bindings | notebook default lakehouse/warehouse, report → model | Deployment autobind (works for these) |
| Binding autobind can't handle | semantic model data source | Deployment Rule per stage (ADR-0004) |
| Binding autobind can't handle, no rule type exists | pipeline Stored Procedure activity Warehouse `endpoint` (TDS host) | `vl_NYC_Crashes.warehouse_endpoint` String, per-stage override (added 2026-09-23, stage-load ticket 06) |
| Stage-invariant | procedure lakehouse names, shortcut target, capacity | Nothing |

Fabric Notebook `RefreshSemanticModel` is the library's consumer. It reads through
`notebookutils.variableLibrary` and holds no literals.

## Options rejected

- **Deployment Rules for everything.** Rules are invisible to code review, and hand-entering them per
  stage is the usual cause of "worked in Test, broke in Prod".

## Consequences

- **Deployment never carries the active value set.** After each stage's first deploy, open
  `vl_NYC_Crashes` in that stage and set it to `Test` or `Prod` before running anything. If you skip
  this, `RefreshSemanticModel` reads Dev's defaults and silently refreshes the **Dev** model.
- Library reads fail from a Livy session, so test them through a notebook job.
- One Deployment Rule was still needed after all (ADR-0004). The library removes rules for values,
  not for every binding.
