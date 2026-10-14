# Report Spec — NYC_CrashReports "Overview" page (demo)

Status: awaiting approval · 2026-10-14 · planner `powerbi-report-planning`, design `powerbi-report-design` (plugin 0.3.6)

## Report identity
- Report name: `NYC_CrashReports` (existing thin PBIP, `2_dev/5_Reports/`)
- Semantic model: `NYC_VehicleCrashes_Semantic`, Dev workspace, `byConnection` (unchanged)
- Audience: leadership / portfolio reviewers
- Primary purpose: understand the overall story in ≤ 10 s
- Delivery target: local PBIP → CC commit → Pat pushes + Update All (no MCP/REST publish)

## User decisions and constraints
- Scope: one new page, "Overview", placed first; existing "Page 1" untouched
- Interactivity: one Year slicer; default cross-highlight between visuals
- Model edit permissions: none needed — existing measures only (TMDL-first if that changes)
- Data caveats: 2012 starts Jul 1, 2026 ends Jun 11; ~30% of crashes have Borough = UNKNOWN; a crash with several contributing factors counts under each

## Narrative
- Core story: crashes fell ~60% from 2019 to 2025, deaths only ~6%
- Key questions: How many crashes/casualties? How has volume trended? Which boroughs? Which factors kill?

## Design identity
- Tone: civic data journalism — calm neutral surface, ink-navy volume, red reserved for deaths
- Signature: thesis-sentence title + "deaths in red only" colour rule across every visual

## Page plan
1. Overview — Executive Summary, variant B (KPI-strip): 5 comparable KPIs, no single hero metric
   - KPI strip: Total Crashes, Total Persons Injured, Total Persons Killed, Injury Crash Rate %, Fatalities per 1,000 Crashes
   - Trend: column chart, Total Crashes by Dim Date[Year]
   - Borough: bar chart, Total Crashes by Dim Location[Borough], desc
   - Factors: bar chart, top 10 Dim Contributing Factor by Total Persons Killed, desc
   - Slicer: Dim Date[Year] dropdown, top-right

## Design system summary
- Theme: `assets/base.json` adapted (custom theme `NYC_Civic`), page background #F3F2F1, white visual surfaces
- Colour semantics: crashes #1F4E79 · injured #C27C0E · killed #B3261E · rates #605E5C
- Typography: Segoe UI Semibold titles, Segoe UI body, tabular numerals
- Layout: 12×12 grid, 32 px margin, 24 px gutter, 8 px snap
- Accessibility: alt text on every visual, AA contrast on all text pairs, human-readable titles/axes

## Canonical design contract

```yaml
Design Brief:
  generated_by: powerbi-report-design
  contract_version: 1
  mode: brownfield
  design_identity:
    tone: civic data journalism
    signature: thesis-sentence title + deaths-in-red-only colour rule
    current_tone: indistinct
    current_signature: none
  archetype: Executive
  color_map:
    - measure: "Fact Crashes[Total Crashes]"
      color: "#1F4E79"
      tint: "#DCE6F1"
    - measure: "Fact Crashes[Total Persons Injured]"
      color: "#C27C0E"
      tint: "#F8EBD5"
    - measure: "Fact Crashes[Total Persons Killed]"
      color: "#B3261E"
      tint: "#F6DCDA"
    - measure: "Fact Crashes[Injury Crash Rate %]"
      color: "#605E5C"
      tint: "#EDEBE9"
    - measure: "Fact Crashes[Fatalities per 1,000 Crashes]"
      color: "#605E5C"
      tint: "#EDEBE9"
  pages:
    - name: Overview
      role: landing
      archetype: Executive
      layout_variant: B
      variant_rationale: "Five KPIs of comparable weight and no single hero metric, so the KPI strip carries the message."
      page_background: "#F3F2F1"
      layout_summary: "Title + Year slicer band; full-width 5-card strip; trend and borough side by side; full-width factor ranking."
      layout_contract:
        canvas: { width: 1920, height: 1080, margin: 32, gutter: 24, snap: 8 }
        grid:
          columns: 12
          rows: 12
          regions:
            header:  [1,  1,  9,  2]
            filters: [9,  1, 13,  2]
            kpis:    [1,  2, 13,  4]
            trend:   [1,  4,  7, 10]
            borough: [7,  4, 13, 10]
            factors: [1, 10, 13, 13]
        placements:
          - id: page_title
            region: header
            kind: textbox
            text: "NYC crashes have fallen sharply since 2019 — deaths have not"
            purpose: "State the page insight before any chart."
          - id: year_slicer
            region: filters
            kind: slicer
            field_bindings: "Dim Date[Year]"
            slicer_type: dropdown
          - id: kpi_crashes
            region: kpis
            kind: cardVisual
            purpose: "How many crashes?"
            field_bindings: "Fact Crashes[Total Crashes]"
            color_strategy: measure_match
            slot: 1
            of: 5
          - id: kpi_injured
            region: kpis
            kind: cardVisual
            purpose: "How many people were injured?"
            field_bindings: "Fact Crashes[Total Persons Injured]"
            color_strategy: measure_match
            slot: 2
            of: 5
          - id: kpi_killed
            region: kpis
            kind: cardVisual
            purpose: "How many people were killed?"
            field_bindings: "Fact Crashes[Total Persons Killed]"
            color_strategy: measure_match
            slot: 3
            of: 5
          - id: kpi_injury_rate
            region: kpis
            kind: cardVisual
            purpose: "What share of crashes injure someone?"
            field_bindings: "Fact Crashes[Injury Crash Rate %]"
            color_strategy: measure_match
            slot: 4
            of: 5
          - id: kpi_fatality_rate
            region: kpis
            kind: cardVisual
            purpose: "How deadly is the average crash?"
            field_bindings: "Fact Crashes[Fatalities per 1,000 Crashes]"
            color_strategy: measure_match
            slot: 5
            of: 5
          - id: crashes_by_year
            region: trend
            kind: columnChart
            purpose: "How has crash volume changed year by year?"
            field_bindings: { Category: "Dim Date[Year]", Y: "Fact Crashes[Total Crashes]" }
            sort_policy: category_asc
            color_strategy: measure_match
          - id: crashes_by_borough
            region: borough
            kind: barChart
            purpose: "Which boroughs have the most crashes?"
            field_bindings: { Category: "Dim Location[Borough]", Y: "Fact Crashes[Total Crashes]" }
            sort_policy: value_desc
            color_strategy: measure_match
          - id: deadliest_factors
            region: factors
            kind: barChart
            purpose: "Which contributing factors are linked to the most deaths?"
            field_bindings: { Category: "Dim Contributing Factor[Contributing Factor]", Y: "Fact Crashes[Total Persons Killed]" }
            filter: "Top 10 by Total Persons Killed"
            sort_policy: value_desc
            color_strategy: measure_match
        space_audit:
          content_cell_count: 132
          placed_cell_count: 132
          empty_cell_pct: 0
          unplaced_regions: []
          largest_region: { name: trend, pct_of_content: 27 }
          balance_rationale: "KPI strip plus three equal analysis regions; no hero dominates and no dead band."
  interaction_pattern:
    drill_targets: []
    cross_filter_rules: "Default highlight between visuals; Year slicer filters all."
  accessibility:
    alt_text_strategy: chart+structure
    contrast_notes: "Red #B3261E and navy #1F4E79 both pass AA on white; no red-on-red."
  theme:
    base: assets/base.json adapted as NYC_Civic
    user_overrides: "Existing Page 1 keeps working under the new theme; no other pages."
```

## Implementation notes
- Model changes: none
- PBIR authoring: `powerbi-report-authoring` + `powerbi-report-author` CLI; new page folder + 9 visuals + custom theme
- Validation: `powerbi-report-author validate`; DAX via MCP to check card values
- Desktop verification: `powerbi-desktop reload` + `screenshot`
- Publishing boundary: CC commits only; Pat pushes and runs Update All
- Risks: Year slicer may list empty years 2027–2030 (Dim Date runs to 2030); factor chart counts multi-factor crashes under each factor
