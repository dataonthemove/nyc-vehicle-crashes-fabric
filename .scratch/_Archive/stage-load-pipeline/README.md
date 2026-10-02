# Stage load pipeline

After the landing-zone split, raw data arrived once in the landing workspace, but nothing below it was orchestrated. In Dev, Test and Prod, someone had to run Ingest three times, twelve Transform procedures in order, then the model refresh. A missed or misordered step silently left a half-loaded star.

Each stage got one Fabric Data Pipeline that runs a complete Stage load: Ingest the three raw sources into Delta, Transform them into the Warehouse star, then Refresh the Direct Lake model. It runs manually, with no schedule. Any failure stops the run before Refresh and shows in the Monitor hub.
