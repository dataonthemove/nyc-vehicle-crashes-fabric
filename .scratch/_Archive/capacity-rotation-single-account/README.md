# Capacity rotation with a single account

## The problem

Trial capacities expire every 60 days, and each rotation had muddied who did the work. user7's Power BI trial lapsed with its capacity, so user8 was added to Dev to author reports. Pat wanted one permanent working account, with each new trial account doing nothing but host capacity.

## The fix

user7 became the single owner of all four workspaces and the only identity for Git, ADO, the Fabric UI, az and MCP. Trial accounts only host capacity, and user8's Dev role was removed. The capacity reassignment runbook was updated and confirmed as the only rotation process document.
