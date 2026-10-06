# Architecture Diagram v4 — Review 2 Observations

Reviewed: `Arch_NYC_VehicleCrashes_v4.drawio` (working copy, all layers visible) on 2026-10-06,
re-rendered with the draw.io CLI and checked against the XML. Rows are listed most important first.

**Who can fix it:**
- **CC** — Claude Code can edit the `.drawio` XML directly.
- **Pat** — needs your decision, or is layout and routing work that's easier by hand in draw.io.
- **CC + Pat** — you decide, then Claude Code makes the edit.

| # | Observation / issue | Issue type | Recommendation | Who can fix it |
|---|---|---|---|---|
| 1 | The Fabric web UI box still says reports are authored against the Prod model and that Source Control syncs them to ADO. Prod isn't Git-bound, `user7`'s Free licence can't save reports, and no reports exist. | Logic / accuracy | Reword to "planned", or note the licence block. Drop the ADO-sync claim. Also fix the grammar slip "Reports is read-only". | CC + Pat (choose the framing) |
| 2 | Landing data is shown twice in conflicting styles: a grey hollow "Dependency: Shortcut" arrow, and black solid "Pull data via Landing Shortcut" arrows (black means data movement in the legend). | Logic / redundancy | Keep one. The shortcut is a reference, so drop the black right-side arrows, or restyle them to match the hollow dependency arrow. | CC + Pat (choose which to keep) |
| 3 | The legend defines the hollow grey arrow as "Source data dependency (NYC SODA API)" only, but it now also marks the shortcut and the report `byConnection` binding. | Legend / consistency | Rename the entry "Dependency (reference, no data movement)". Add the shortcut chain-link icon to the legend. | CC |
| 4 | The red MCP lines to Landing, Test and Prod share the Dev line's trunk and draw over its label, striking through "refresh_semantic_model". | Formatting glitch | Bring edge `733` (the labelled one) to the front, or move its label onto a segment no other line shares. | CC |
| 5 | The red vertical running down to Test and Prod makes a large S-shaped bulge where it jumps the green Git line, caused by rounded corners plus a 20 px jump close to a bend. | Formatting glitch | Move the vertical away from the bend, or reduce its jump size, so it shows a clean single arc. | Pat (routing) |
| 6 | The three outer containers share their top and right edges again (all tops at y −5640, all rights at x −2610). The earlier inset was undone, probably during a resize. | Formatting regression | Re-apply the 30 px inset on the top and right edges and nudge the titles down. | CC |
| 7 | Some items aren't attached: the SODA dependency arrow has no source or target, the Test → Prod deployment arrow has no source, and the Shortcut icon floats free of its line. They won't follow when boxes move. | Formatting / robustness | Connect both arrows to their boxes. Group the Shortcut icon with its label or line. | CC (attach edges); Pat (group icon) |
| 8 | All green Git edges, including the GitHub push, now have `jumpStyle=none`. That contradicts your "all lines should have line jumps" rule and the legend note. | Consistency | Reset them to `jumpStyle=arc;jumpSize=20`. | CC |
| 9 | Neither pipeline is connected to anything. Pipeline `pl_stage_load_NYC_Crashes` has no orchestration arrows, and pipeline `pl_cdc_NYC_Crashes_Landing` has no arrow into `Files/raw/`. | Omission (carried over) | Add arrows: CDC pipeline → `Files/raw/`, and stage pipeline → notebooks → stored procedures → refresh. | Pat (routing) |
| 10 | The watermark note says "manages CDC  values" (vague wording, double space). The watermark is the high-water mark the Copy Data queries filter on. | Wording / accuracy | Change to "Notebook nb_etl_watermark advances etl_watermark, the high-water mark that parameterizes the Copy Data queries." | CC |
| 11 | The ADO box still says "main + short-lived feature branches"; you commit straight to main. | Accuracy (carried over) | Change to "main (trunk-based)". | CC |
| 12 | The legend sits across the Azure / Fabric boundary, so it looks like part of the cloud architecture. | Layout | Move it fully inside the Internet column, or outside all three containers. | Pat |
| 13 | The shortcut box title reads "OneLake  Shortcut" (double space), and its "(To Landing lakehouse)" subtitle is 13 px, below the 14 px minimum. | Typo / font | Single space; set the subtitle to 14 px. | CC |
| 14 | The shortcut arrow runs up through the Dev header area and into the Landing lakehouse box before reaching the Files icon, crossing that box's content. | Layout | Route it to enter the Landing lakehouse box from the left side, at the Files icon's height. | Pat |
| 15 | The Power BI Consumers box is now mostly empty; its description moved onto the blue arrow label. | Layout | Shrink the box, or move the text back inside and shorten the arrow label. | Pat |
| 16 | Variable library `vl_NYC_Crashes` and notebook `RefreshSemanticModel` are still missing, though both deployment labels mention Variable Libraries. | Omission (optional) | Add a small icon for each in the Dev workspace, or accept them as out of scope. | CC + Pat (decide scope) |
| 17 | Layer name "5 - Users consumer semantic model" has a typo. It doesn't show in exports. | Typo / metadata | Rename to "5 - Users consume semantic model". | CC |
