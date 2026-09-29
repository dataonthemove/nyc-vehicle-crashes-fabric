# 01: Delete the existing report

**What to build:** The only existing report on `NYC_VehicleCrashes_Semantic` is gone from every stage where it exists, and the deletion is committed to Git. After that, nothing downstream depends on the model's current table or column names, so the rename needs no visual rebinding.

**Blocked by:** None (can start immediately).

**Status:** done

**Who:** Pat (Fabric web UI + Source Control pane).

- [x] Report located in each stage workspace (Dev, Test, Prod) where it exists
- [x] Report deleted in Dev via the Fabric web UI
- [x] Dev deletion committed through the Fabric Source Control pane and visible in ADO `main`
- [x] Report deleted in Test and Prod (directly, or by deploying the deletion through the deployment pipeline)
- [x] `list_items` in each stage confirms no Report item remains bound to the semantic model
