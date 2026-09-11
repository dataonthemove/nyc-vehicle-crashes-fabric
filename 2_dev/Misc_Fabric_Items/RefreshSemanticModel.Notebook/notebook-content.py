# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "jupyter",
# META     "jupyter_kernel_name": "python3.12"
# META   },
# META   "dependencies": {
# META     "warehouse": {
# META       "default_warehouse": "da2b14e1-b933-a3f7-47de-f697ddedf601",
# META       "known_warehouses": [
# META         {
# META           "id": "da2b14e1-b933-a3f7-47de-f697ddedf601",
# META           "type": "Datawarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

# Welcome to your new notebook
# Type here in the cell editor to add code!



import sempy_labs as labs

# Stage-varying values come from Variable Library vl_NYC_Crashes (active value set chosen per stage).
vl = notebookutils.variableLibrary.getLibrary("vl_NYC_Crashes")
print(f"workspace={vl.stage_workspace_name} dataset={vl.semantic_model_name} refresh_type={vl.refresh_type}")

labs.refresh_semantic_model(
    dataset=vl.semantic_model_name,
    workspace=vl.stage_workspace_name,
    refresh_type=vl.refresh_type
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
