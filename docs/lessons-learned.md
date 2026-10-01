# Lessons from the Build

### Problems this build hit and what each one taught. 

<br>

**Bridge cross-filtering**  
A single-direction filter on the factor bridge silently returned the full crash count for every contributing factor. Key-level validation caught it; setting the relationship to both directions fixed it.
<br>
<br>

**Header/line facts**  
The person and vehicle facts couldn't be filtered by crash-level dimensions. Fixed by copying the header's dimension keys onto each line fact, not by bidirectional filters or per-measure DAX.
<br>
<br>

**Stage binding**
After deployment, the Test semantic model was still silently reading Dev's warehouse, because Direct Lake on OneLake can't be rebound per stage. Converted to Direct Lake on SQL and added deployment rules.
<br>
<br>

**Single source of raw data**
Moved ingestion into a dedicated landing workspace outside the deployment pipeline. Raw files now land once, under one watermark, instead of each of three stages calling the API and drifting apart.
<br>
<br>

**Profile before measuring**
A "> 0" filter threw out 480K genuine zero-occupant vehicles along with the unreported ones, which skewed the average.
<br>
<br>

**Green runs prove nothing**<br>
Three successful-looking ingestion runs each hid a silent corruption. One wrote tables into a hidden schema namespace, one let positional CSV binding null the key on 2.4M rows, and one split 210K multi-line records into fragments. Checking the catalog and the row, null-key and distinct-key counts caught all three.
<br>
<br>

**0.025% of rows, 888x the total**<br>
1,127 corrupt occupant values in the source inflated the vehicle-occupant SUM 888-fold. Capped in the ETL rather than in DAX, at 100 rather than 20, because buses legitimately carry more. The load is incremental, so the fix also needed a one-time backfill, or it would only have applied to new rows.
<br>
<br>

**Assumed limits**<br>
A 2M-row cap on the API extract was believed to be a source limit. It wasn't. Lifting it showed every earlier baseline had come from truncated data.
<br>
<br>

**One procedure, two copies**<br>
Each load proc lived in both its authoring notebook and the Warehouse item definition that deployment promotes. 10 of 12 item definitions had gone stale, and validation never noticed because running the notebook masks the deployed copy.
<br>
<br>

**Deployments can wipe data**<br>
A routine Test deploy with no schema change recreated every star table empty, and nothing failed. Row counts now get checked after every deploy that includes the Warehouse.
<br>
<br>

**Branch-out isn't isolation**<br>
A Fabric branch-out workspace kept Dev's endpoints and default lakehouse, so "isolated" test runs wrote into Dev until those were repointed.
<br>
<br>

**Think in sets**<br>
The date dimension's WHILE loop ran one INSERT per day and took 29 minutes for 5,479 rows. Fabric Warehouse doesn't support MAXRECURSION or cross joins on sys.all_objects, so it was rewritten to cross-join small VALUES lists into a number series and finishes in seconds.
