# Branch-out pre-flight

A **branch workspace** (Git → Branch out to new workspace) is not a stage. It is not isolated from Dev:
its active value set is Dev's, and its notebook default lakehouse still points at Dev's Lakehouse.
The main risk: a branch that changes Ingest logic runs a MERGE that rewrites **Dev's** Delta tables.

Before running anything in a branch workspace:

1. **Warehouse endpoint.** On the branch, set `vl_NYC_Crashes.warehouse_endpoint` (the default value)
   to the branch Warehouse's TDS host. Otherwise every Stored Procedure activity in
   `pl_stage_load_NYC_Crashes` connects to Dev's host and fails with "database was not found".
2. **Default lakehouse.** Repoint `nb_cdc_to_delta`'s default lakehouse (`default_lakehouse` and
   `default_lakehouse_workspace_id` in its `# META` header) to the branch Lakehouse.
3. **SQL endpoint sync.** After the first Ingest into a fresh branch Lakehouse, refresh the branch SQL
   endpoint's metadata (`POST sqlEndpoints/{id}/refreshMetadata?preview=true`) before Transform.
   Otherwise Transform fails with `Invalid object name`.
4. **Keep it on the branch.** Commit these repoints on the branch only. Never merge them to `main`.

If you skip all of this, confirm that nothing in the run writes to Dev.

Background: `CONTEXT.md` (Branch workspace, Default lakehouse, Rehydrate) and ADR-0003 amendment.
