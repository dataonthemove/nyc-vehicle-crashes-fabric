# Semantic model measure layer: 38 governed measures

## The problem

The crash semantic model had no measures after the header/line remodel, so report authors could only drag raw columns into visuals. The obvious calculations were also subtly wrong: unknown ages counted as children, date logic ran past the data's end, and rates divided by mostly-blank populations.

## The fix

Thirty-eight governed measures now cover crashes, people and vehicles, each with a business name, format, folder and description naming its source. The ten raw columns they replace are hidden. Every measure was checked against independent counts in Dev, Test and Prod, with identical figures and a passing smoke test.
