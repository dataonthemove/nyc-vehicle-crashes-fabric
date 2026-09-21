# ADR-0002: Raw data lands once, in a landing workspace outside the deployment pipeline

- **Status:** Accepted
- **Date:** 2026-09-21 (decided 2026-09-08, built 2026-09-08 → 2026-09-21)
- **Context:** landing-zone build, Phases 1–11

## Context

Ingestion used to live in Dev. Fabric Pipeline `pl_cdc_NYC_Crashes` pulled from Socrata into Dev's
lakehouse `Files/`, and Warehouse table `dbo.etl_watermark` tracked progress. Promoting Dev → Test → Prod
would have meant either copying 2.9 GB of raw files into every stage, or having three stages each call
Socrata with three watermarks that could drift. Raw data had no single owner.

## Decision

**Raw data lands once, in workspace `1_NYC_VehicleCrashes_Landing`. That workspace is never a
deployment-pipeline stage.**

1. **Ownership.** Fabric Lakehouse `NYC_VehicleCrashes_Landing_Lakehouse` holds raw CSV under
   `Files/raw/{crashes,persons,vehicles}`, owned by no stage. Fabric Pipeline
   `pl_cdc_NYC_Crashes_Landing` is the only ingester.
2. **Shortcut contract.** Every stage reaches the raw data through a OneLake shortcut named
   `raw_nyc_crashes`, mounted at `Files/raw_nyc_crashes` and targeting landing `Files/raw/`. It targets
   `Files/`, not `Tables/`, because each stage builds its own Delta from the files (`nb_cdc_to_delta`).
   The target is the same for every stage, so it is not parameterised.
3. **Watermark.** The authoritative store is Delta table `etl_watermark` in the landing lakehouse,
   seeded `1900-01-01`. Fabric Notebook `nb_etl_watermark` (PySpark) is its only writer. The SQL
   endpoint is read-only, and it cannot be a pipeline dependency in Git, so the pipeline also reads the
   watermark through the notebook (`mode=read`).
4. **Pipeline boundary.** Fabric pairs whole workspaces, so excluding landing just means never
   assigning it to `dp_NYC_VehicleCrashes`.

## Options rejected

- **Ingest per stage.** Three Socrata callers, three watermarks and three copies of raw data. Test and
  Prod could silently diverge from Dev at the source.
- **Landing as a pipeline stage.** A deployment pipeline promotes definitions, not data, and landing
  has no Dev/Test/Prod lifecycle.
- **Shortcut to `Tables/`.** That would couple every stage to one Delta schema and remove each stage's
  ability to rebuild independently.

## Consequences

- The shortcut **is** Git-serialized (lakehouse `shortcuts.metadata.json`) and **is** carried by
  deployment. Verified in Test and Prod, so no manual recreation is needed.
- All stages read landing as `Jpb_fabric_user7`. A per-stage "Viewer on landing" cannot be expressed
  until a second principal or an Entra group exists.
- Below landing there is no orchestration. Delta build, ETL and refresh are manual job runs per stage.
- Warehouse `dbo.etl_watermark` is legacy (0 rows) and a retirement candidate.
- Known defect carried over from the old pipeline: the watermark advances to run time, not to the
  maximum `crash_date` loaded.
