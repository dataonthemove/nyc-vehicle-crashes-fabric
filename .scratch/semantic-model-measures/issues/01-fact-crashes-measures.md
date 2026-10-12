# 01: Fact Crashes measures

**What to build:** Report authors in Dev get the full `Fact Crashes` measure layer, 21 measures per the spec's measure catalogue:
- volume: `Total Crashes`;
- the 8 reported casualty totals (`Total Persons Injured` … `Total Motorists Killed`);
- severity: `Injury Crashes`, `Fatal Crashes`, `Injury Crash Rate %`, `Fatalities per 1,000 Crashes`, `Vulnerable Road User Fatality %`;
- time intelligence: the hidden `First Data Date` / `Last Data Date` helpers, `Avg Daily Crashes`, `Crashes PY`, `Crashes YoY %`, `Crashes Rolling 12M`;
- data quality: `Geocoded Crash %`.

The 8 raw casualty columns are hidden, so measures are the only aggregate surface on the header fact. Each measure carries its format string, display folder and a `///` description naming its source (reported injury counts). This ticket also lands the first measures in the model, so the docs that say "the model has no measures" are corrected here.

**Blocked by:** None (can start immediately)

**Status:** in-progress (steps 1–4 done; awaiting Pat push + Update All)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev model state via MCP and confirm it still matches git (no measures, the 8 casualty columns visible) | CC | Live state recorded in Comments; no unexpected drift | done |
| 2 | Add the 21 measures to the `Fact Crashes` TMDL with format strings, display folders (`Volume`, `Reported Casualties`, `Severity`, `Time Intelligence`, `Data Quality`, `Helpers`) and `///` descriptions; hide the two helper measures and the 8 casualty columns | CC | TMDL diff shows exactly 21 measures and 8 hidden casualty columns; no other change | done |
| 3 | Update docs: Measures section and column notes in the semantic model doc; drop "no measures" from the environment reference and from the `/dax-smoke-test` CC skill premise (its checks stay measure-free); add **Injury crash** / **Fatal crash** under *Severity* in `CONTEXT.md` | CC | No doc still states the model has no measures; Severity no longer marked unconfirmed | done |
| 4 | Commit locally (`model_factcrashes_measures`) | CC | Commit exists; working tree clean | done |
| 5 | Push to ADO; Dev Source Control → Update All | Pat | Source Control pane shows nothing pending for the semantic model | todo |
| 6 | `refresh_semantic_model` on Dev to frame | CC | Refresh completes | todo |
| 7 | Metadata check: `INFO.VIEW.MEASURES` shows 21 `Fact Crashes` measures (2 hidden), each with description, format string and display folder; `INFO.VIEW.COLUMNS` shows the 8 casualty columns hidden | CC | All hold | todo |
| 8 | Base equality by `Dim Date`[Year]: each count/sum measure equals an independent `COUNTROWS`/`SUM` over the raw column in the same query; `Injury Crashes` / `Fatal Crashes` equal independent `> 0` row counts | CC | Every row matches | todo |
| 9 | Date regressions: `Crashes PY` and `Crashes Rolling 12M` are BLANK for every year after `Last Data Date`; `Crashes PY` for the last data year equals the prior year's crashes up to the same day of year; `Avg Daily Crashes` under one contributing-factor filter equals crashes ÷ calendar days in the data range | CC | All hold; figures in Comments | todo |
| 10 | Run `/dax-smoke-test` on Dev | CC | All checks pass | todo |

## Comments

**2026-10-12 — CC, step 1.** Live Dev (`INFO.VIEW.MEASURES` / `INFO.VIEW.COLUMNS` via `execute_dax_query`):
0 measures; on `Fact Crashes` the 8 casualty columns plus Latitude and Longitude visible. Matches git, no drift.

**2026-10-12 — CC, steps 2–4.** `Fact Crashes.tmdl`: 21 measures added (2 hidden helpers) and `isHidden` on the
8 casualty columns; nothing else changed. Docs updated: semantic model doc (Measures section, Fact Crashes
row), `CONTEXT.md` (Injury crash / Fatal crash; Severity removed from Open terms; hidden columns noted),
environment reference, and the `/dax-smoke-test` CC skill in the `~/.claude` repo (committed there separately). Code review (standards + spec) applied: Severity glossary row, descriptions no longer cite stale figures or ticket-02 measures, DAX vars renamed.
