# 01: Fact Crashes measures

**What to build:** Report authors in Dev get the full `Fact Crashes` measure layer, 21 measures per the spec's measure catalogue:
- volume: `Total Crashes`;
- the 8 reported casualty totals (`Total Persons Injured` … `Total Motorists Killed`);
- severity: `Injury Crashes`, `Fatal Crashes`, `Injury Crash Rate %`, `Fatalities per 1,000 Crashes`, `Vulnerable Road User Fatality %`;
- time intelligence: the hidden `First Data Date` / `Last Data Date` helpers, `Avg Daily Crashes`, `Crashes PY`, `Crashes YoY %`, `Crashes Rolling 12M`;
- data quality: `Geocoded Crash %`.

The 8 raw casualty columns are hidden, so measures are the only aggregate surface on the header fact. Each measure carries its format string, display folder and a `///` description naming its source (reported injury counts). This ticket also lands the first measures in the model, so the docs that say "the model has no measures" are corrected here.

**Blocked by:** None (can start immediately)

**Status:** done (2026-10-12)

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev model state via MCP and confirm it still matches git (no measures, the 8 casualty columns visible) | CC | Live state recorded in Comments; no unexpected drift | done |
| 2 | Add the 21 measures to the `Fact Crashes` TMDL with format strings, display folders (`Volume`, `Reported Casualties`, `Severity`, `Time Intelligence`, `Data Quality`, `Helpers`) and `///` descriptions; hide the two helper measures and the 8 casualty columns | CC | TMDL diff shows exactly 21 measures and 8 hidden casualty columns; no other change | done |
| 3 | Update docs: Measures section and column notes in the semantic model doc; drop "no measures" from the environment reference and from the `/dax-smoke-test` CC skill premise (its checks stay measure-free); add **Injury crash** / **Fatal crash** under *Severity* in `CONTEXT.md` | CC | No doc still states the model has no measures; Severity no longer marked unconfirmed | done |
| 4 | Commit locally (`model_factcrashes_measures`) | CC | Commit exists; working tree clean | done |
| 5 | Push to ADO; Dev Source Control → Update All | Pat | Source Control pane shows nothing pending for the semantic model | done |
| 6 | `refresh_semantic_model` on Dev to frame | CC | Refresh completes | done |
| 7 | Metadata check: `INFO.VIEW.MEASURES` shows 21 `Fact Crashes` measures (2 hidden), each with description, format string and display folder; `INFO.VIEW.COLUMNS` shows the 8 casualty columns hidden | CC | All hold | done |
| 8 | Base equality by `Dim Date`[Year]: each count/sum measure equals an independent `COUNTROWS`/`SUM` over the raw column in the same query; `Injury Crashes` / `Fatal Crashes` equal independent `> 0` row counts | CC | Every row matches | done |
| 9 | Date regressions: `Crashes PY` and `Crashes Rolling 12M` are BLANK for every year after `Last Data Date`; `Crashes PY` for the last data year equals the prior year's crashes up to the same day of year; `Avg Daily Crashes` under one contributing-factor filter equals crashes ÷ calendar days in the data range | CC | All hold; figures in Comments | done |
| 10 | Run `/dax-smoke-test` on Dev | CC | All checks pass | done |

## Comments

**2026-10-12 — CC, step 1.** Live Dev (`INFO.VIEW.MEASURES` / `INFO.VIEW.COLUMNS` via `execute_dax_query`):
0 measures; on `Fact Crashes` the 8 casualty columns plus Latitude and Longitude visible. Matches git, no drift.

**2026-10-12 — CC, steps 2–4.** `Fact Crashes.tmdl`: 21 measures added (2 hidden helpers) and `isHidden` on the
8 casualty columns; nothing else changed. Docs updated: semantic model doc (Measures section, Fact Crashes
row), `CONTEXT.md` (Injury crash / Fatal crash; Severity removed from Open terms; hidden columns noted),
environment reference, and the `/dax-smoke-test` CC skill in the `~/.claude` repo (committed there separately). Code review (standards + spec) applied: Severity glossary row, descriptions no longer cite stale figures or ticket-02 measures, DAX vars renamed.

**2026-10-12 — CC, step 6–7 (first attempt).** Refresh completed, but `INFO.VIEW.MEASURES` showed
`Avg Daily Crashes`, `Crashes PY` and `Crashes Rolling 12M` as `InvalidExpression` (`SYNTAXERROR`).
Cause: the review rename used DAX variable names `firstDate` / `lastDate`, which collide with the
`FIRSTDATE` / `LASTDATE` functions (DAX names are case-insensitive). Renamed to `firstDataDate` /
`lastDataDate`, verified query-scoped against Dev, recommitted. Steps 5–6 repeat.

**2026-10-12 — CC, steps 6–9 (after `864b8fa`, push + Update All).**
- Step 6: `refresh_semantic_model` Completed (refresh `460243340`).
- Step 7: `INFO.VIEW.MEASURES` — 21 `Fact Crashes` measures, all `State = Valid`, 2 hidden (both
  `Helpers`), 21 with description and display folder. Format strings read from the live TMDL
  (`get_semantic_model_definition`; `INFO.VIEW.MEASURES` has no format column): all 21 per spec.
  `INFO.VIEW.COLUMNS` — 8 casualty columns hidden; only Latitude, Longitude visible on the table.
- Step 8: by `Dim Date`[Year], 15 data years, 0 failing rows. Each `Total …` measure equals
  `SUM` over its raw column, `Total Crashes` equals `COUNTROWS`, `Injury Crashes` / `Fatal Crashes`
  equal `FILTER(… > 0)` row counts, `Geocoded Crash %` equals an independent non-blank, non-zero
  latitude share. Grand totals: 2,269,187 crashes · 3,617 killed · 558,603 injury crashes ·
  3,469 fatal crashes.
- Step 9: helpers equal independent `MINX`/`MAXX` over fact dates (2012-07-01 → 2026-06-11).
  0 years after 2026 return a value for `Crashes PY`, `Crashes Rolling 12M`, `Crashes YoY %` or
  `Avg Daily Crashes`. 2026 `Crashes PY` 36,774 = independent count 2025-01-01 → 2025-06-11;
  2026 `Crashes Rolling 12M` 85,196 = independent count 2025-06-12 → 2026-06-11; `Crashes YoY %`
  −0.95%. `Avg Daily Crashes` under the rarest bridged factor (`70`, 4 crashes) = 4 ÷ 5,094
  calendar days = 0.000785 (dividing by days with crashes would give 1.0).

**2026-10-12 — CC, step 10.** `/dax-smoke-test` on Dev — all pass. No rebuild preceded it, so
check 1 compared Spark counts with the model's DAX counts instead of a pre-drop capture.

| Check | Subject | Result | Offending | Expected vs actual |
|---|---|---|---|---|
| 1 | Fact rows, Spark vs model (3) | PASS | 0 | 2,269,187 · 5,984,110 · 4,551,002 both sides |
| 2 | Line → header key agreement, duplicate `collision_id` (9) | PASS | 0 | 0 mismatches |
| 3 | Orphaned / null keys on 15 relationships; duplicate dim keys (7) | PASS | 0 | 0 |
| 4 | Factor-group integrity, Unknown location, `dim_driver` uniqueness (7) | PASS | 0 | 1 empty-set group, 1 Unknown |
| 5 | Every bridged factor filters all three facts | PASS | 0 | 63 factors, 0 failing |
| 6 | Relationships match spec | PASS | 0 | 0 missing/wrong, 0 extra, 0 RI off |

Ticket closed. Next: ticket 02 (`Fact Crash Persons` measures).
