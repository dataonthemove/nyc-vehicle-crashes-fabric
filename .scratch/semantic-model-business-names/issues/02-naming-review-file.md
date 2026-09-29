# 02: Naming review file

**What to build:** Pat has an approved, row-by-row vocabulary for the semantic model before any TMDL changes. Claude inventories every table and column in the Git-managed model definition and writes a current → proposed review file in this feature folder. Pat edits it in place and approves it.

**Blocked by:** None (can start immediately).

**Status:** done

**Who:** Claude drafts; Pat reviews and approves.

- [x] Naming rules are stated at the top: Title Case with spaces, Title Case `Dim `/`Fact ` table prefixes, abbreviations expanded, singular dimension nouns, facts named after the business process
- [x] Hidden columns are listed but default to "keep technical name", so Pat can override any row
- [x] The table has columns: table, current name, proposed name, visible/hidden, notes. It covers all 12 tables and all 78 columns
- [x] The bridge table's name (or whether it stays hidden/technical) is decided explicitly
- [x] Any proposed name that collides with another name in the same table, or across tables, is flagged
- [x] Pat marks the file approved (e.g. a `Approved: <date>` line at the top)
