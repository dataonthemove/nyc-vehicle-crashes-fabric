# 02: Fact Crash Persons measures

**What to build:** Report authors in Dev get the 9 `Fact Crash Persons` measures per the spec's measure catalogue: `Person Records`, `Persons Involved`, `Injured Persons (Person-Level)`, `Killed Persons (Person-Level)`, `Average Age`, `Average Age of Killed`, `Child Casualties (<18)`, `Ejection Rate %` and `Person Fatality Rate %`. Person Age is hidden. Every description names its source (recorded injured persons). Rates and "involved" counts also state the 2016 break: before 2016 the table holds only injured and killed people.

**Blocked by:** 01 (the first measures and the doc corrections land there; this ticket extends the same doc sections)

**Status:** ready-for-agent

| Step | Description | Owner | Done when | Status |
|---|---|---|---|---|
| 1 | Pull current Dev model state via MCP; confirm ticket 01's measures are live | CC | Recorded in Comments | done |
| 2 | Add the 9 measures to the `Fact Crash Persons` TMDL with format strings, display folders (`Volume`, `Recorded Casualties`, `Demographics`, `Rates`) and `///` descriptions; hide Person Age | CC | TMDL diff shows exactly 9 measures and Person Age hidden | done |
| 3 | Update the Measures section and the Person Age column note in the semantic model doc | CC | Doc lists the person measures and notes Person Age is hidden | done |
| 4 | Commit locally (`model_factpersons_measures`) | CC | Commit exists; working tree clean | done |
| 5 | Push to ADO; Dev Source Control → Update All | Pat | Nothing pending for the semantic model | todo |
| 6 | `refresh_semantic_model` on Dev to frame | CC | Refresh completes | todo |
| 7 | Metadata check: 9 person measures, each with description, format string and display folder; Person Age hidden | CC | All hold | todo |
| 8 | Base equality by `Dim Date`[Year]: `Person Records`, the person-level injured/killed counts and `Persons Involved` equal independent `COUNTROWS` with explicit filters; literal Person Role values re-checked against `VALUES` | CC | Every row matches | todo |
| 9 | Regressions: `Child Casualties (<18)` equals an independent count of injured or killed persons with a non-blank age below 18; the `Ejection Rate %` denominator equals the count of known ejection statuses only | CC | Both hold; figures in Comments | todo |
| 10 | Run `/dax-smoke-test` on Dev | CC | All checks pass | todo |

## Comments

**2026-10-12 — CC, step 1.** Live Dev (`INFO.VIEW.MEASURES` / `INFO.VIEW.COLUMNS`): ticket 01's 21
`Fact Crashes` measures all `Valid`, 2 hidden; `Fact Crash Persons` has no measures and Person Age,
Is Injured, Is Killed visible. Matches git. Literal values re-checked: Person Role values as the spec
lists, plus a blank role (194,889 rows: 2012–2015 entirely, 8,864 in 2016, 6 later; all but 25 injured or killed), kept as involved by `NOT … IN`; Ejection values exactly the
spec's six plus blank.

**2026-10-12 — CC, steps 2–3 (test-first).** All 9 measures run first as query-scoped `DEFINE MEASURE`
against Dev beside independent `COUNTROWS`/`AVERAGEX` expressions by `Dim Date`[Year]: 15 years,
all match. `Child Casualties (<18)` 2012 = 3,185 (naive `< 18` = 5,682). `Ejection Rate %` 2025 = 2.9%
(4,423 / 153,084 known statuses). 2012 `Ejection Rate %` is BLANK (0 ejected of 50 known). Then
`Fact Crash Persons.tmdl`: 9 measures plus `isHidden` on Person Age. Docs: semantic model doc (Measures
section, Fact Crash Persons row), `CONTEXT.md` Person Age mapping.

**2026-10-12 — CC, code review (standards + spec) applied.** Status label kept canonical; the three
all-role measures and both rates now say "Source: person records" instead of claiming to be
injured-only; 2016-break wording made uniform; blank Person Role (pre-2016 casualties) documented as
kept in the measure description, semantic model doc and spec literal-values line; `CONTEXT.md` Person Age
note names all three consuming measures. Not taken: an `Is Involved` / `Ejection Known` flag column
(new columns are out of scope) and rewriting `Child Casualties (<18)` away from the catalogue DAX.
