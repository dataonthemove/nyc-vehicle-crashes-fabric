# 04: Promote to Test

**What to build:** Test carries the full measure layer proven in Dev: 38 measures (2 of them hidden) and the 10 hidden raw columns. Only the semantic model is deployed. The Warehouse is deselected, so the deploy puts no table at risk.

**Blocked by:** 01, 02, 03

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Deploy Dev → Test via the deployment pipeline, selecting only the semantic model | Pat | Deployment succeeds; Warehouse not in the deployed set | todo |
| 2 | `refresh_semantic_model` on Test to frame | CC | Refresh completes | todo |
| 3 | Metadata check: `INFO.VIEW.MEASURES` shows 38 measures (2 hidden), each with description, format string and display folder; `INFO.VIEW.COLUMNS` shows the 10 columns hidden | CC | All hold | todo |
| 4 | Re-run the validation queries from tickets 01–03 on Test: base equality, date, child-casualty, denominator and guard regressions | CC | All hold; figures in Comments | todo |
| 5 | Run `/dax-smoke-test` on Test | CC | All checks pass | todo |

## Comments
