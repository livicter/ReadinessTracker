# Density detail scrub readout

## Sub-features
- Readout under density scrub (date, %, fill, Δpp)
- SIDs fitbit/health `.air.density.detail.scrub.readout`

## How to get to it
Today → Fitbit Air or Health Air → Detail → scrub chart

## Driving it with the harness
UITest taps detail open, scrubs chart, asserts readout SID, saves PNG.

## Gotchas
Shared sheet; SID switches with source.
