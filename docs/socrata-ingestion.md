# How ingestion from NYC Open Data works

This doc explains how Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` pulls the three Motor Vehicle
Collisions datasets from NYC Open Data (Socrata) into the landing lakehouse. The reasons behind
the design are in ADR-0001 (the app token) and ADR-0002 (the landing zone). Live IDs are in
`Context/environment-reference.md` → Connections.

**In short:** three anonymous HTTP connections each hold one dataset's base URL. At run time, each
Copy activity adds a SoQL query string to that URL, filtered on the watermark. The results land as
CSV files under `Files/raw/<source>/`.

## A. The fixed part: connection objects

1. **Where they are in the UI:** gear icon → **Manage connections and gateways**. They are
   connection objects, not workspace items, which means:
   - Git never serializes them.
   - They have no logical ID, so the ID is the same in every stage.
   - Deployment never rebinds them.

   The pipeline JSON only stores their IDs, in `externalReferences.connection`.
2. **There are three connections, one per dataset.** All are type **HTTP** with **Anonymous**
   authentication.

   | Source | Dataset | Socrata ID |
   |---|---|---|
   | crashes | Motor Vehicle Collisions - Crashes | `h9gi-nx95` |
   | persons | Motor Vehicle Collisions - Person | `f55k-p6yu` |
   | vehicles | Motor Vehicle Collisions - Vehicles | `bm4k-52h4` |

3. **Each connection's base URL has the form**
   `https://data.cityofnewyork.us/resource/<id>.csv`. The base URL is stored only in the connection
   object and appears in no repo file. The dataset IDs above were confirmed against the Socrata
   API on 2026-10-01. The `.csv` ending follows from the Copy source being DelimitedText.
4. **Why anonymous:** the earlier pipeline sent an `X-App-Token` header. The token only raised the
   rate limit. It was retired and rotated after it leaked into git history (ADR-0001).
5. **Why anonymous HTTP connections are easy to work with:** MCP `update_pipeline_definition` can
   edit them. The OAuth Lakehouse and Warehouse connections fail there with permission errors.

## B. The dynamic part: the Relative URL

6. **Where it is in the UI:** open the pipeline → click `Copy_<Source>_CDC` → **Source** tab. The
   tab shows:
   - **Connection:** the HTTP connection above.
   - **Relative URL:** set with **Add dynamic content**.
   - **File format:** DelimitedText, comma-separated, first row as header.
   - **Request method:** GET.
7. **The expression** (crashes shown; persons and vehicles differ only in the key at the end of
   the watermark reference):

   ```
   ?$where=crash_date>'@{json(activity('Read_Watermarks').output.result.exitValue).crashes}'&$order=crash_date&$limit=10000000
   ```

   Fabric appends it to the base URL.
8. **What each SoQL parameter does:**
   - `$where`: the incremental filter, "only rows with `crash_date` after the watermark."
   - `$order=crash_date`: gives a stable order.
   - `$limit=10000000`: Socrata returns only **1,000 rows** by default. This raises the cap far
     above the dataset size, so the first full load (watermark `1900-01-01`) comes back in one
     request.
9. **How the `@{…}` part works:** it is string interpolation.
   - The `Read_Watermarks` exit value is a JSON string such as `{"crashes":"…","persons":"…","vehicles":"…"}`.
   - `json()` parses that string.
   - `.crashes`, `.persons` or `.vehicles` picks the watermark for that Copy.

## C. Where the watermark comes from

10. **What `Read_Watermarks` does:** it runs notebook `nb_etl_watermark` with `mode=read`. The
    notebook reads Delta table `etl_watermark` in the landing lakehouse and returns it with
    `notebookutils.notebook.exit(json.dumps(payload))`.
11. **Why a notebook and not a Lookup activity:**
    - A Lookup would have to point at the lakehouse SQL endpoint.
    - That endpoint isn't a Git item, so Git import fails with `MissingDependencies`.
    - The endpoint is also read-only, so it couldn't advance the watermark anyway.
12. **The parameters cell:** the notebook's first cell must be tagged as the parameters cell
    (… → **Toggle parameter cell**). Without the tag, the pipeline can't override `mode`,
    `source_name` and `new_value`. The tag can only be set by hand in the UI.

## D. Where the data lands

13. **The Copy activity's Destination tab** has these settings:
    - Lakehouse `NYC_VehicleCrashes_Landing_Lakehouse`.
    - Root folder `Files`, folder `raw/<source>`, file extension `.csv`.
    - OAuth connection `Lakehouseconnection`.

    If the Copy fails with `LakehouseForbiddenError`, re-consent the credentials in Manage
    connections and gateways.
14. **What arrives:** every run adds new CSV files.
    - A run that finds no new rows still writes a file with only the header row.
    - The folder also holds a `.keep` sentinel file.

    Anything that reads these folders must tolerate both.
15. **How the stages get the data:** Dev, Test and Prod never call Socrata themselves. Each one
    reads the landing files through OneLake shortcut `raw_nyc_crashes` → landing `Files/raw/`,
    then builds its own Delta tables with `nb_cdc_to_delta` (ADR-0002).

## E. Run order and advancing the watermark

16. **Run order:**
    1. `Read_Watermarks` runs first.
    2. The three Copy activities run in parallel. Each retries 3 times, 120 s apart.
    3. `Advance_Watermark_*` (`mode=advance`) runs for each source, **one after another**.

    The advance steps can't run in parallel: concurrent merges into the single-file Delta table
    raise `ConcurrentAppendException`.
17. **The value written:** `new_value` is `@formatDateTime(utcnow(),'yyyy-MM-ddTHH:mm:ss')`.
    - The Fabric UI saves this parameter with an outer `"type": "Expression"`, and the run then
      fails when it is submitted.
    - The shape that works is
      `"new_value": {"value": {"value": "@…", "type": "Expression"}, "type": "string"}`.

## F. Known weaknesses

18. **The watermark advances to the run time, not to the latest `crash_date` loaded.** A crash
    that NYC publishes late, with a `crash_date` earlier than the last run, is never picked up.
19. **Edits to rows already loaded are never picked up.** The filter is on `crash_date`, not on a
    last-modified column such as Socrata's `:updated_at`. The open question is in
    `.scratch/_Doubtful/source-rows-append-only-NotUpdate/`.
