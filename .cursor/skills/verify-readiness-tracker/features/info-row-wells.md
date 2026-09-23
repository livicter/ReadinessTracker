# Metric About InfoRow wells

## Sub-features
- Circular tint wells on Metric Detail / Advanced Metric About HealthKit info bullets (checkmark / xmark)

## How to get to it (user POV)
1. Today → Metrics → Sleep (or any metric) → scroll to About / older-data cue

## Driving it with the harness
- Soft UITest path that saves `.audit/verify-metric-about.png` (scroll to About cue; soft assert)

## Gotchas
- Icons already include `.circle.fill`; well is a light tint behind the glyph (22pt), not a second SF Symbol
- keep Gym/Work/Sleep naming elsewhere; no Fitness+ invent
