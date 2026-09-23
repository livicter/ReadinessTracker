# Wake Episodes (Honest #113)

## Intent
Elevate `wakeEpisodes` (buried Sleep Analysis timing chip + Today “N disturbances” cue) into a WHOOP-style **Tonight | Baseline** dual callout on the Today WHOOP sleep stack, with Calm/Typical/Restless/Disrupted band and 7-night spark.

## Surface
- Today → WHOOP sleep stack → **Wake Episodes** (after Sleep Efficiency)
- A11y: `wake.episodes.card`, `wake.episodes.baseline`, `wake.episodes.spark`

## Verify
- UITest: `testWakeEpisodesSurface` asserts title, Tonight, Baseline; shot `.audit/verify-wake-episodes.png`
- Fixture: today 1 wake (Calm); older nights vary 0…3 via `coherentSleepStages(..., wakeCount:)` so spark has shape; stages stay coherent with `wakeEpisodes`

## Non-goals
- No new readiness score term
- Sleep Disturbance timeline on Sleep Analysis unchanged
- Sleep Midpoint / chronotype left for a later Honest
