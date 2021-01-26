stoke
=====

## Installing

You will need the languages ruby and R installed.

## Basic use

Run stoke.rb to create stoke.pdf, a colored graph of running performance on routes of various lengths.
My own actual routes and logs are included in the git repository and can be used as sample files.

## Idiosyncratic stats and units

The y axis of the graph is in units of millikipchoges.
1 kipchoge is defined as the power output per unit body mass required to run 1 marathon in 2 hours.
It's equivalent to about 21 watt/kg (Minetti et al., "Energy cost of walking and running at extreme uphill and downhill slopes,"
https://sci-hub.do/10.1152/japplphysiol.01177.2001 ).
For comparison, cyclists seem to prefer talking about mechanical work done on
the pedals, in which case an elite athlete puts out about 5 watt/kg. 

The climb factor (CF) is a percentage by which the energy required for a certain run exceeds what it
would have been if the run had been flat. Climb factors can be determined using my script kcals.

## Format of database tables

They're basically CSV, with the following modifications. Final column is an optional JSON hash, including curly braces.
Comments set off with # last to end of line.
Blank lines allowed. Leading and trailing whitespace is ignored.

routes.tab: label,slope distance in miles,climb factor

Stats are from kcals.rb, with default parameters except for force_dem=1. Filtering=60 m, which is default.

Dates can be in any format recognized by ruby's Date.parse, which seems to be very permissive.
The year can be omitted, e.g., "may 11", in which case the year specified in the most recently
parsed date will be used.

