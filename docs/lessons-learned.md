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
To average occupants per vehicle, a "> 0" filter was meant to drop unreported rows. But the source keeps NULL (unreported, 1.83M) and 0 (genuinely empty, 480K, mostly parked cars) apart. The filter dropped both, inflating the average to 1.39 (true: 1.15). Count each bucket first; the fix was `NOT ISBLANK`.
<br>
<br>

**Green runs prove nothing**<br>
Three successful-looking ingestion runs each hid a silent corruption. 
* One wrote tables into a hidden schema namespace, 
* one let positional CSV binding null the key on 2.4M rows, 
* and one split 210K multi-line records into fragments.<br>

Checking the catalog and the row, null-key and distinct-key counts caught all three.
<br>
<br>

**0.025% of rows, 888x the total**<br>
1,127 corrupt occupant values in the source inflated the vehicle-occupant SUM 888-fold. Capped in the ETL rather than in DAX, at 100 rather than 20, because buses legitimately carry more. The load is incremental, so the fix also needed a one-time backfill, or it would only have applied to new rows.
<br>
<br>

**Assumed limits**<br>
First attempt: 50,000-row pages, a legacy SODA 2.0 ceiling. Next, one 2M-row request with an app token (Socrata API key) was assumed to be the source maximum. It wasn't: 12–67% of rows silently missing. Tokens govern throttling, not row count. Token later leaked, so dropped: now anonymous, `$limit=10000000`.
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
Fabric branch-out copies items but keeps Dev references: notebooks' default lakehouse, Stored Procedure activities' SQL endpoint, and variable library values. "Isolated" runs wrote into Dev. Fix: before any run, follow `Context/branch-out-preflight.md` to repoint each to the branch-out workspace's own lakehouse, Warehouse endpoint and variable values. Commit those repoints on its Git branch only; never merge them into Dev.
<br>
<br>

**Think in sets**<br>
The date dimension's WHILE loop ran one INSERT per day and took 29 minutes for 5,479 rows. Fabric Warehouse doesn't support MAXRECURSION or cross joins on sys.all_objects, so it was rewritten to cross-join small VALUES lists into a number series and finishes in seconds.
