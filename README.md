stoke
=====

## Format of database tables

They're basically CSV, with the following modifications. Final column is an optional JSON hash, including curly braces.
Comments set off with # last to end of line.
Blank lines allowed. Leading and trailing whitespace is ignored.

routes.tab: label,slope distance in miles,climb factor

Stats are from kcals.rb, with default parameters except for force_dem=1. Filtering=60 m, which is default.

Dates can be in any format recognized by ruby's Date.parse, which seems to be very permissive.
The year can be omitted, e.g., "may 11", in which case the year specified in the most recently
parsed date will be used.

