# Task Plan: below-fold proof then WHOOP/Google completeness

## Goal
Make WHOOP and Body cards observable without VoiceOver, then finish remaining product gaps. One PR per slice.

## Exit predicate
- `./scripts/ci-verify.sh` prints TEST SUCCEEDED
- `.audit/verify-dashboard.png`
- `.audit/verify-whoop-stack.png` (scrolled in-app)
- `.audit/verify-body-activity.png` (scrolled in-app)
- `.audit/verify-settings-sources.png`
- Scripted capture. No Simulator Accessibility swipe.

## Resume
HEAD after PR #7: `745926b`. Overnight INCONCLUSIVE was viewport-only screenshots.

## Phases
### PR-0 visual-parity (this branch)
Identifiers, `-ui-fixture` seed, XCUITest scrollTo, `scripts/capture-surfaces.sh`.
**Status:** in_progress

### PR-1 WHOOP product
Disturbance count on Today sleep row. Journal strip at 7 days. Confirm wheel/sleep-need. WHOOP-via-Health copy (fixture already sets Whoop).
**Status:** pending

### PR-2 Google Health home
Move Body & activity above WHOOP. Finish denied → iOS Settings.
**Status:** pending

## Decisions
| Decision | Why |
|---|---|
| XCUITest swipeUp + identifiers | Root cause was viewport screenshot, not missing cards |
| `-ui-fixture` launch arg | UI tests get a clean container; need 14 nights so cards exist |
| Screenshots via /tmp/rt-audit then copy | UI test sandbox cannot rely on SRCROOT writes |
| No heartbeat restart | Two no-progress ticks already |
| Body stays below WHOOP in PR-0 | Proof of current layout. Move is PR-2 |
