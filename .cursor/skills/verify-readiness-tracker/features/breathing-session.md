# Breathing session

## Sub-features
- Settings → Insights → Breathing opens HRV Coherence session
- Coaching cards whose action mentions breath deep-link to the same session
- Start/Stop control with phase cue (Inhale / Hold / Exhale)

## How to get to it (user POV)
1. Settings → Insights → Breathing
2. Or Coaching → action that mentions breathing → Open Breathing

## Driving it with the harness
- `SurfacesUITests.testBreathingSessionSurface` → `.audit/verify-breathing.png`
- Soft asserts on `settings.link.breathing` / `breathing.session` / `breathing.start` / Start

## Gotchas
- Session was already implemented; Honest #102 only wires navigation + proof (no new scoring)
- Keep Gym/Work/Sleep rings + source pills; no Fitness+ invent
- Fixture not required — static session UI
