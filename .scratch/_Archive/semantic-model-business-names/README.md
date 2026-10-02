# Semantic model business names

## The problem

The Direct Lake semantic model showed report authors the Warehouse's raw technical names, such as fact_crashes, dim_contributing_factor and factor_desc. Snake_case, prefixes and abbreviations in the field list made the model read like a database schema rather than an analytical product, weakening it as a portfolio piece.

## The fix

Visible tables and columns were renamed to business-friendly names, such as Fact Crashes and Contributing Factor, at the semantic layer only. Claude drafted a naming-review file, Pat approved it, and the TMDL was edited locally. The Warehouse was untouched, so no reloads were needed, and hidden columns kept their technical names.
