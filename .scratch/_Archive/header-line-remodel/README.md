# Header/line remodel

Reworked the star schema to follow Kimball's header/line rule: the persons and vehicles facts now inherit the crash's date, location and factor-group keys, closing the RLS leak and letting every dimension filter all three facts.
