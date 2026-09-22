# Sleep Stages (Apple Health)

## Surface
Day Detail → Sleep Stage Analysis → `SleepStageBreakdown`, plus Today `SleepStageBar` labels and Sleep Analysis stage copy.

## Honest #61 chrome
- Order: Awake → REM → Core → Deep
- Stacked bar: continuous rounded segments, tiny gaps OK, **no icons inside**
- Labels **under** the bar (tint well + name + duration/%) — not a 2×2 `AppListRow` icon grid
- Header: "Sleep Stages" + quiet "Xh total" subline; **no** score capsule on this card
- User-visible "Light" / "Light Sleep" → **Core** (Apple Health). Data fields stay `lightSleepPercent` / `SleepStage.light`.

## Proof
- UITest: `testSleepStagesSurface` → `.audit/verify-sleep-stages.png`
- Expect Core (not Light), no in-bar icons, no score capsule on the Day Detail stages card.
