# Task Plan: ReadinessTracker UI/UX + WHOOP / Google Health parity

## Goal
Ship bright Apple Health UI (readable chips, real taps, no nested-link collisions) plus WHOOP product surfaces via HealthKit and Google Health breadth metrics, verified by `./scripts/ci-verify.sh` and `.audit/verify-dashboard.png`.

## Current Phase
Phase 5 (landed, visual WHOOP below fold still INCONCLUSIVE)

## Exit predicate (all must be true)
- `./scripts/ci-verify.sh` prints `TEST SUCCEEDED`
- `.audit/verify-dashboard.png` is a bright Today tab
- No selected control uses white type on `RTColor.surfaceHighlight`
- Morning/Evening cards open Check-in for that time
- `whoopSection` and hero have no nested NavigationLink collisions / force-unwrap
- Dashboard WHOOP stack shows Recovery, Strain, Sleep Performance, Sleep HRV, Sleep Debt, Sleep Quality Trend, Sleep Consistency (or explicit empty)
- Settings can connect/refresh Apple Health and Fitbit; WHOOP via HealthKit label; Body & activity + cycle privacy
- Feature map files updated
- No secrets committed

## Phases

### Phase 0: Inventory
- Confirm P0/P1 still in tree on `main` @ 979105c
- Write `.audit/ui-ux-audit.tsv` and design spec
- **Status:** complete

### Phase 1: P0 contrast + taps
- **Status:** complete

### Phase 2: History / Settings chrome + empty state
- **Status:** complete

### Phase 3: WHOOP product surfaces
- **Status:** complete (screenshot below fold INCONCLUSIVE)

### Phase 4: Google Health breadth
- **Status:** complete

### Phase 5: Verify + feature map
- **Status:** complete for tests + above-fold screenshot

## Decisions
| Decision | Why |
|---|---|
| Work on `feature/ui-whoop-google-parity` off `main` | Isolated, reversible |
| No persisted WHOOP DataSource | HealthKit label is enough |
| Sleep need = 14-night average via BaselineManager | Replaces undocumented `* 1.1` |
| Wheel recovery = RecoveryCalculator.totalScore | Label says recovery |
| AppChip lives in AppleNativeTheme.swift | One selected-state |
| Tests go in existing XCTest files | Avoid pbxproj churn |
