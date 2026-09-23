# Today Strain/Recovery Balance header well

## Sub-features
- Strain/Recovery Balance card header on Today
- `scale.3d` SF Symbol in a circular tint well (zone color)

## How to get to it (user POV)
1. Open Today
2. Scroll past Sleep Consistency to Balance
3. See Balance title with circular tint well

## Driving it with the harness
- UITest: `SurfacesUITests.testStrainRecoveryBalanceSurface`
- Captures `.audit/verify-strain-recovery.png`

## Gotchas
- Keep status Capsule and Recovery|Strain pair layout
- Do not invent Fitness+ chrome
