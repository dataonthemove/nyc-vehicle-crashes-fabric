# Measure-readiness fixes: date sorting, blank members, Person Age, Vehicle Model Year

## The problem

A review before adding the first measures to the crash semantic model found four defects that would make early reports look broken or wrong: months and weekdays sorted alphabetically, every slicer offered a phantom "(Blank)" item, and Person Age and Vehicle Model Year held impossible values like 9999 and 20063.

## The fix

Month and weekday now sort in calendar order and dates display without a time. Assuming referential integrity on all relationships removed the blank member. The ETL now nulls implausible ages and model years, and existing rows were corrected. All four fixes reached Dev, Test and Prod, passing the smoke test.
