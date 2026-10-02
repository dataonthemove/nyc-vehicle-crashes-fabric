# Header/line remodel

The star schema broke Kimball's header/line rule. Only the crashes fact carried location and factor-group keys, so those dimensions could not filter persons or vehicles, and the Borough_Reader RLS role leaked unfiltered rows. A review against Kimball's method found five more modelling shortfalls to fix together.

The persons and vehicles facts now inherit the crash's date, location and factor-group keys. dim_collision was dropped for a degenerate collision_id, and a new dim_driver was added. dim_damage became dim_vehicle_circumstance. The leaking RLS role, all measures and all reports were removed for later rebuilding, then promoted Dev → Test → Prod.
