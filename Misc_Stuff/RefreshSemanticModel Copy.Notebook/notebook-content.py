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

labs.refresh_semantic_model(
    dataset="NYC_VehicleCrashes_Semantic",
    workspace="NYC_Motor_Vehicle_Collisions",
    refresh_type="calculate" # Recalculates dependencies/measures without pulling source data
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "jupyter_python"
# META }
