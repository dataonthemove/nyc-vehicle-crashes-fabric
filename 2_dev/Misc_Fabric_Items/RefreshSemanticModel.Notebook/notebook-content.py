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



import time
import sempy.fabric as fabric  # semantic-link, preinstalled in Fabric; no pip install needed

# Stage-varying values come from Variable Library vl_NYC_Crashes (active value set chosen per stage).
vl = notebookutils.variableLibrary.getLibrary("vl_NYC_Crashes")
print(f"dataset={vl.semantic_model_name} refresh_type={vl.refresh_type}")

# No workspace argument: sempy defaults to the workspace this notebook runs in, so each stage refreshes its own model.
request_id = fabric.refresh_dataset(
    dataset=vl.semantic_model_name,
    refresh_type=vl.refresh_type
)

# refresh_dataset is asynchronous; poll so the job fails if the refresh fails.
for _ in range(60):
    status = fabric.get_refresh_execution_details(vl.semantic_model_name, request_id).status
    if status not in ("Unknown", "NotStarted", "InProgress"):
        break
    time.sleep(10)
print(f"refresh {request_id}: {status}")
if status != "Completed":
    raise RuntimeError(f"Semantic model refresh ended with status {status}")


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
