# Simulator A−B lever diff (Honest #533 / #726)

## Why
A/B compare showed READY Δ only — show per-lever A→B (or A→Live) deltas and tap to focus.

## Surface
- `sim.load.ab.leverdiff`

## Verify
- `testReadinessLoadSimulatorSurface`
- `.audit/verify-readiness-load-simulator-ab-lever-diff.png`
- `.audit/verify-simulator-ab-leverdiff.png`

Honest #726 restyles the existing chips to WHOOP wells (focused filled kind.color + white; unfocused zero = ghost/hairline 8%/28%; unfocused nonzero = 14% fill + 28% hairline). No new SID.
