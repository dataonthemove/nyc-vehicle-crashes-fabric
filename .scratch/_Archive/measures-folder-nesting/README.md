# Measures grouped in one `_Measures` folder per fact table

## The problem

Report authors browsing the model in Fabric found each fact table's measure folders scattered among its columns, because the Data pane sorts folders and fields together alphabetically. There was no single place to see all of a table's measures. Pat raised it while reviewing the measure layer.

## The fix

Every measure folder now sits inside one underscore-prefixed _Measures folder, which sorts to the top of each fact table, with the subject folders kept inside it. It reached Dev, Test and Prod, and Pat confirmed the result. Side effect: Fact Crash Vehicles sorts above every other table.
