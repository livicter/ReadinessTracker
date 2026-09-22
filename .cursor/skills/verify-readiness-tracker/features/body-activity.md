# Today → Body

## Sub-features
- Body section grid of Body metric tiles
- Circular tinted SF Symbol wells + progress rings + sparklines
- Steps (etc.) sheet with hero ring + 7-day chart

## How to get to it
Today tab → scroll to Body

## Driving it with the harness
`SurfacesUITests.testBodyActivityVisibleAfterScroll` / `testBodyDetailSurface` → `.audit/verify-body-activity.png` / `verify-body-detail.png`

## Gotchas
Do not invent Move/Exercise/Stand Fitness+ chrome; keep existing metric set.
