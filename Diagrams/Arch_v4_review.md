# Architecture Diagram v4 — Review Observations

Reviewed: `Arch_NYC_VehicleCrashes_v4.drawio` / `.png` on 2026-10-06, checked against the repo and
`Context/environment-reference.md`. Rows are listed most important first.

**Who can fix it:**
- **CC** — Claude Code can edit the `.drawio` XML directly (text, styles, geometry).
- **Pat** — needs your decision, or is visual layout work that's easier by hand in draw.io.
- **CC + Pat** — you decide on scope or placement, then Claude Code makes the edit.

Re-exporting the PNG is always a Pat step.

| # | Observation / issue | Issue type | Recommendation | Who can fix it |
|---|---|---|---|---|
| 1 | The Dev arrow label and the Semantic Model box say "Direct Lake over OneLake." The model has been Direct Lake on SQL since 2026-09-21 (`Sql.Database(...)` in `expressions.tmdl`). | Logic / accuracy | Relabel both as "Direct Lake on SQL (Warehouse TDS endpoint)." | CC |
| 2 | The Prod box says "All items promoted from dev workspace." Prod is promoted from Test. | Logic / accuracy | Change the Prod text to "promoted from test workspace." | CC |
| 3 | The Fabric web UI box says reports are authored against the Prod model and sync to ADO. Prod isn't Git-bound, `user7` (Free licence) can't save reports, and there are currently no reports. | Logic / accuracy | Mark report authoring as "planned" or blocked by licence. Drop the "syncs to ADO" claim for Prod. | CC + Pat (choose the framing) |
| 4 | The "Landing Lakehouse" inside the Dev workspace reads as a duplicate item. It is actually OneLake shortcut `raw_nyc_crashes` in the Dev lakehouse `Files/`. | Logic / clarity | Relabel it as a shortcut, add a shortcut icon, and draw a dashed link back to the Landing lakehouse. | CC (relabel); Pat (icon and link placement) |
| 5 | The Test and Prod boxes say everything is promoted "except … shortcuts," but the shortcut is promoted via `shortcuts.metadata.json`. | Logic / accuracy | Remove "shortcuts" from the exclusion list. | CC |
| 6 | Lakehouse files show `Files/NYC_CrashData/{crashes\|persons\|vehicles}`; the actual path is `Files/raw/{crashes,persons,vehicles}`. | Accuracy | Change the path text in both lakehouse boxes. | CC |
| 7 | The watermark is missing: table `Tables/etl_watermark` and its only writer, notebook `nb_etl_watermark`. | Omission | Add both to the Landing workspace, with an arrow showing the pipeline reading and advancing the watermark. | CC + Pat (decide placement) |
| 8 | Pipeline `pl_stage_load_NYC_Crashes` doesn't visibly orchestrate anything. Pipeline `pl_cdc_NYC_Crashes_Landing` has no arrow into the lakehouse `Files/`. | Omission / logic | Add orchestration arrows: pipeline → notebooks → stored procedures → refresh, and CDC pipeline → `Files/raw`. | Pat (routing is layout work) |
| 9 | The ADO box says "main + short-lived feature branches"; in practice you commit straight to main. | Accuracy | Change to "main (trunk-based)," or mark feature branches as optional. | CC |
| 10 | The GitHub public mirror (`dataonthemove/nyc-vehicle-crashes-fabric`, pushed by the ADO pipeline in `ops/github-mirror/`) is missing. | Omission | Add a GitHub box outside Azure with a one-way arrow from ADO labelled "read-only mirror." | CC + Pat (decide placement) |
| 11 | Variable library `vl_NYC_Crashes`, notebook `RefreshSemanticModel`, notebook `nb_cdc_to_delta` and the refresh step are missing, though the deployment labels mention variable libraries. | Omission | Add small item icons for them in the Dev workspace. | CC + Pat (decide level of detail) |
| 12 | MCP arrows only reach the Landing and Dev workspaces, but validation and refreshes also run in Test and Prod. | Logic / omission | Extend the MCP arrow to Test and Prod, or add "(all stages)" to the label. | CC (label); Pat (if extending the arrows) |
| 13 | The two red MCP labels repeat each other word for word. | Formatting / clutter | Keep one label, or merge the two lines into a single bracket with one label. | CC |
| 14 | "All deployment workspaces pull data from the landing workspace" appears three times on the right edge. | Formatting / clutter | Use one shared trunk line with branch arrows and a single label. | Pat (re-routing) |
| 15 | Font sizes are inconsistent, and much 6–8 pt text is unreadable at normal zoom: Socrata, MCP, ADO and web UI box text, item names, and the "Python Notebooks"/"stored procedures" arrow labels. | Formatting | Set a minimum of about 11–12 pt for body text and arrow labels, and trim wording to fit. | CC (font sizes); Pat (resize boxes that overflow) |
| 16 | The three outer containers (Internet, Azure, Fabric) share their top and right edges, so borders stack and rounded corners collide at bottom-right. | Formatting glitch | Inset each inner container by 20–30 px from its parent on all sides. | CC |
| 17 | There's a stray "↑" glyph beside the Delta Lake icon in the Dev lakehouse box. | Formatting glitch | Delete the stray character or edge fragment. | CC (locate first); Pat if it's an embedded image detail |
| 18 | The grey "Source data dependency" arrow repeats the black CDC arrow between the same two endpoints. It says "SODA API" while the box says "Socrata." | Clutter / consistency | Remove the grey arrow and its legend entry, or standardize the name as "Socrata (SODA API)." | CC + Pat (keep or remove) |
| 19 | The legend promises arcs where lines cross, but the green/red dashed crossing near the Dev MCP label shows no visible arc. | Formatting / consistency | Check every crossing edge has `jumpStyle=arc`, or re-route to avoid crossings. | CC (set the style); Pat (visual check) |
| 20 | Typos and style: "Power BI/ Fabric UI" is missing a space; the legend has a stray capital "Between"; the Landing heading uses capital "Landing" while Dev/Test/Prod headings use lowercase stage names. | Typo / consistency | Fix the spacing and capitalization, and use one casing style for all workspace headings. | CC |
| 21 | The v4 file's page name is still "NYC VehicleCrashes Architecture v2" (diagram ID `nyc-crashes-arch-v2`). | Metadata | Rename the page to v4. | CC |

Rows 7–12 are judgment calls about how much detail you want on the diagram.
