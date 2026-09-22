# Settings → Notifications

## Sub-features
- Master Allow Notifications toggle with tinted bell well
- Morning Summary / Low Recovery / Bedtime / Quiet Hours rows with SF Symbol wells
- Delivery time + quiet-hour pickers when enabled

## How to get to it
Settings tab → Notifications

## Driving it with the harness
`SurfacesUITests.testSettingsNotificationsSurface` under `-ui-fixture` → `.audit/verify-settings-notifications.png`

## Gotchas
When master is off, per-type sections are hidden. Soft-assert optional rows.
