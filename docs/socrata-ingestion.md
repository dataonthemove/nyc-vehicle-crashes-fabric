# How ingestion from NYC Open Data works

NYC publishes its crash data on its open-data portal, which runs on a platform called **Socrata**.
This doc explains how Fabric Pipeline `pl_cdc_NYC_Crashes_Landing` downloads that data into our
landing lakehouse, and how it avoids downloading the same rows twice.

The reasons behind the design are in ADR-0001 (why no API token) and ADR-0002 (why a separate
landing workspace). Live IDs are in `Context/environment-reference.md` → Connections.

## The whole thing in one paragraph

The pipeline has three Copy activities, one for each dataset. Each one sends a web request to
NYC's API that says, in effect, "give me every row with a `crash_date` later than X". X is the
**watermark**: a note of where the last run got to, kept in the `etl_watermark` table. The rows
come back as a CSV file, which is saved in the landing lakehouse. When all three downloads are
done, the watermark moves forward so the next run starts where this one stopped.

## 1. The source: three NYC datasets

NYC publishes crashes, the people involved and the vehicles involved as three separate datasets.
Socrata identifies each dataset by a short ID. Dataset names and IDs were checked against the
Socrata API on 2026-10-01.

| Our name | NYC dataset | Socrata ID |
|---|---|---|
| crashes | Motor Vehicle Collisions - Crashes | `h9gi-nx95` |
| persons | Motor Vehicle Collisions - Person | `f55k-p6yu` |
| vehicles | Motor Vehicle Collisions - Vehicles | `bm4k-52h4` |

Each dataset can be downloaded from a URL of the form
`https://data.cityofnewyork.us/resource/<id>.csv`.

## 2. The connections: where the URLs are stored

A Fabric **connection** stores an address and the credentials for reaching it. We have one
connection per dataset.

- **Where to find them:** gear icon → **Manage connections and gateways**.
- **Type:** HTTP, with **Anonymous** authentication, so no login and no API key.
- **What each one holds:** the base URL for one dataset (section 1). That URL isn't stored in any
  repo file, so to see or change it, open the connection in Fabric.
- **Why they behave differently from workspace items:**
  - Connections are not workspace items, so Git doesn't track them.
  - A connection has the same ID in every stage, and deployment never repoints it.
  - The pipeline JSON stores only each connection's ID, in `externalReferences.connection`.
- **Why anonymous:** an earlier version of the pipeline sent a Socrata app token, a kind of API
  key. The token was only there to raise the rate limit. It leaked into git history, so it was
  rotated and dropped (ADR-0001).
- **A useful side effect:** MCP `update_pipeline_definition` can edit pipelines that use these
  connections. Pipelines that use the OAuth Lakehouse and Warehouse connections fail there with
  permission errors.

## 3. The request: building the URL for each run

The connection supplies the fixed part of the URL. Each Copy activity adds a query string that
changes on every run. To see it: open the pipeline → click `Copy_Crashes_CDC` (or the Persons or
Vehicles copy) → **Source** tab → **Relative URL**. The query string is entered through **Add
dynamic content**.

Here is the crashes version. The persons and vehicles versions differ only in the last word
inside `@{…}`:

```
?$where=crash_date>'@{json(activity('Read_Watermarks').output.result.exitValue).crashes}'&$order=crash_date&$limit=10000000
```

Fabric adds this to the end of the base URL. Reading it piece by piece:

- **`$where=crash_date>'…'`:** "only rows with a `crash_date` later than this date." This makes
  each run download only new rows, which is what makes the load incremental.
- **`@{…}`:** a Fabric expression that is filled in when the pipeline runs. It takes the output
  of the `Read_Watermarks` step (section 4), which is a small piece of JSON such as
  `{"crashes":"2026-09-30T14:02:11", …}`, and picks out the date for this dataset.
- **`$order=crash_date`:** returns the rows sorted by date.
- **`$limit=10000000`:** the maximum number of rows to return. Without it, Socrata returns only
  **1,000 rows**. Ten million is far more than the dataset holds, so the first full load, which
  starts from `1900-01-01`, comes back in one request.

The `$where`, `$order` and `$limit` parameters belong to **SoQL**, Socrata's query language.

### Which version of the API we use (SODA)

**SODA** (Socrata Open Data API) is the API that answers these requests. It has three versions,
and the version decides the URL form, how many rows one request can return, and whether you
need a token. Facts below are from dev.socrata.com, checked 2026-10-01.

| Version | URL form | Most rows per request | Token needed? |
|---|---|---|---|
| 2.0 | `/resource/<id>.csv` | 50,000 | No |
| 2.1 | `/resource/<id>.csv` (same) | No limit | No |
| 3.0 (2025) | `/api/v3/views/<id>/query.json` or `/export.csv` | No limit | **Yes** |

- **We use 2.1.** Versions 2.0 and 2.1 share the same URL form, so the URL alone doesn't say which
  one we're on. We know it isn't 2.0 because our full load returned millions of rows in one
  request, and 2.0 stops at 50,000.
- **Requests without a token can be slowed down.** Socrata may throttle anonymous traffic from
  the same IP address and reply with HTTP **429** ("too many requests"). Each Copy retries 3 times,
  2 minutes apart, which covers short bursts of throttling.
- **Moving to version 3.0 would mean using a token again.** If we ever do:
  - Store the token in the connection's settings, never in the pipeline JSON. Putting it in the
    pipeline JSON is how it leaked before.
  - Expect the URLs and query parameters to change too.

  Socrata hasn't said if or when the 2.x URLs will stop working.

## 4. The watermark: the `etl_watermark` table

The watermark records how far the last download got. It is a small Delta table called
`etl_watermark` in the landing lakehouse, with one row per dataset:

| Column | What it holds |
|---|---|
| `source_name` | `crashes`, `persons` or `vehicles` |
| `last_loaded_value` | The date the next run filters on (`crash_date > this`). Despite the name, it is set to **the time of the last run**, not the latest `crash_date` loaded (see section 7). It starts at `1900-01-01`, so the first run downloads everything. |
| `last_run_utc` | When the row was last written. This is only an audit stamp, and the pipeline never reads it. |

**Only notebook `nb_etl_watermark` ever writes to this table.** The pipeline calls the notebook
in one of two modes:

- **`mode=read`:** the `Read_Watermarks` step. The notebook reads the table and returns all three
  dates to the pipeline as one piece of JSON.
- **`mode=advance`:** the `Advance_Watermark_*` steps. The notebook updates one dataset's row.

A third mode, `seed`, creates the starting rows, and is run by hand once.

**Why a notebook does this, not a Lookup activity:** a Lookup activity would read the table
through the lakehouse's SQL endpoint. That endpoint is read-only, so it couldn't advance the
watermark. A Lookup that points at it also breaks Git import with `MissingDependencies`, because
Git doesn't track the endpoint.

**A setup step that's easy to forget:** the notebook's first cell must be marked as the
parameters cell (… → **Toggle parameter cell**). Without that, the pipeline can't pass `mode` and
the other values in. The setting can only be changed by hand in the Fabric UI.

## 5. Where the data lands

The **Destination** tab of each Copy activity saves the download as a CSV file in lakehouse
`NYC_VehicleCrashes_Landing_Lakehouse`, under `Files/raw/crashes`, `Files/raw/persons` or
`Files/raw/vehicles`. It writes through OAuth connection `Lakehouseconnection`. If a write fails
with `LakehouseForbiddenError`, open that connection in Manage connections and gateways and
re-enter its credentials.

- **Every run adds new files and never replaces old ones.** A run that finds no new rows still
  writes a file containing only the header row. The raw folders also contain a `.keep`
  placeholder file. Anything that reads these folders must tolerate both.
- **Dev, Test and Prod never call NYC themselves.** Each one reads the landing files through a
  OneLake shortcut, a kind of pointer, named `raw_nyc_crashes`. Each one then builds its own Delta
  tables from the files with `nb_cdc_to_delta` (ADR-0002).

## 6. The order of a run

1. **`Read_Watermarks`** gets the three watermark dates.
2. **The three Copy activities** download at the same time.
3. **The three `Advance_Watermark_*` steps** update the watermark, **one at a time**. If they ran
   at the same time, they would all write to the same small Delta table at once, and the writes
   would collide with `ConcurrentAppendException`.

Each advance step sets the watermark to the current time, using the expression
`@formatDateTime(utcnow(),'yyyy-MM-ddTHH:mm:ss')`.

**A UI quirk:** when you save this parameter, the Fabric UI wraps it in an extra
`"type": "Expression"`, and the run then fails to start. Fix it in the JSON. The shape that works is
`"new_value": {"value": {"value": "@…", "type": "Expression"}, "type": "string"}`.

## 7. Known weaknesses

- **Late-arriving crashes can be missed.** The watermark is set to the time of the run, not to
  the latest `crash_date` downloaded. Suppose NYC adds a crash from last Tuesday after
  Wednesday's run. Every later run asks only for crashes dated after Wednesday, so that crash is
  never downloaded. This is a known, unfixed defect (ADR-0002).
- **Corrections to rows already loaded never arrive.** The filter looks only at `crash_date`, so
  if NYC edits a row that we've already downloaded, we never see the change. Filtering on a
  "last modified" column, such as Socrata's `:updated_at`, would catch edits. The open question is
  in `.scratch/_Doubtful/source-rows-append-only-NotUpdate/`.
