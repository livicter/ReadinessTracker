# Trends MA14 + EMA Overlays (Honest #262)

## Intent
Elevate unused `movingAverage(window: 14)` / `exponentialMovingAverage` on the
Trends primary depth timeline. Classic #247 / Advanced already draw MA14 + EMA;
DepthTimelineChart previously only dotted MA7.

## Surface
- History → Browse Trends → TrendDetailView → Depth Timeline
- Toggle chips **MA14** + **EMA** (default on)
- Chart: dashed MA14 (recovery) + dashed EMA7 (hrv) LineMarks
- Legend + soft cue copy (classic/Advanced parity)
- A11y: `trends.ma14` / `.toggle`, `trends.ema` / `.toggle`

## Verify
- UITest: `testTrendsMA14EMASurface`
- Shot: `.audit/verify-trends-ma14-ema.png`

## Non-goals
- No classic MA7 toggle (MA7 already drawn); no BAC / HK duals
