# ADR-0006: Code-first report authoring in Power BI Desktop

- **Status:** Accepted
- **Date:** 2026-10-14
- **Supersedes:** the "Fabric web UI only" report rule in CLAUDE.md

## Context

Reports were restricted to the Fabric web UI after PBID raised Direct Lake framing errors on a
`byConnection` report over the Warehouse-backed model. The exact error was never recorded. That
experience predates the model's conversion to Direct Lake on SQL (2026-09-21, ADR-0004).

On 2026-10-14 a thin PBIP report (`NYC_CrashReports`), authored in PBID with `byConnection` to the
Dev model, was committed under `2_dev/5_Reports/`, synced to the Dev workspace with Update All and
rendered correctly. Deployed report-only to Test, the deployment pipeline rebound it to Test's model
(confirmed via lineage).

## Decision

- Reports are authored code-first in PBID as thin PBIP reports under `2_dev/5_Reports/`,
  `byConnection` to the Dev semantic model, and promoted by the deployment pipeline.
- `byPath` is not used: PBID would host and rewrite the TMDL model, which is authored only as
  local TMDL files.
- Git-managed reports are not edited in the Fabric web UI.
- CC may edit PBIR files with Microsoft's `powerbi-report-authoring` skill and its CLIs
  (`powerbi-report-author`, `powerbi-desktop`). The plugin's `semantic-model-authoring` skill stays
  off; `powerbi-report-management` (direct Fabric item CRUD) is user-invocable only.
- Self-service reports live in a separate workspace on Build permission to the Prod model, never in
  Test or Prod, and are adopted into `2_dev/5_Reports/` when business-critical.

## Consequences

- Reports get the same review, history and promotion path as the model.
- The `user7` account is documented as Free-licensed, yet the Git-synced report was created and
  opened. Whether Git sync bypasses the licence check, or the licence changed, is unconfirmed.
- Round-trip editing (web UI then PBID) is untested and avoided by the one-surface rule.
