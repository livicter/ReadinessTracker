# ReadinessTracker

iOS readiness app. Bright Apple Health UI.

**Sources.** Apple Health (HealthKit) by default. Optional **Fitbit** via Google Health API (`DataSource.fitbit`; secrets in gitignored `Secrets.xcconfig`). WHOOP metrics appear when the user shares WHOOP into Apple Health — no unofficial WHOOP OAuth. Not in scope: Google Fit REST / Heart Points.

**Today.** Gym / Work / Sleep rings with center READY score; Morning / Evening check-in; recommendations; **Load Simulator** (scrub sleep/HRV/strain/RHR/SpO₂ + checkable tasks); **Fitbit/Health Air** density; interactive **Balance Dial**; Body tiles; WHOOP-style Recovery / Strain / sleep stack. Tonight | Baseline cards open classic **`MetricDetailView`** (Steps-parity `*.md.nav`) across activity, nutrition, vitals, and sports.

**Elsewhere.** History (weekly report + trends), Check-in, Settings. Home Screen + Lock Screen widgets. Watch app (dashboard / strain / sleep / check-in) and complications.

**Build.** Xcode project `ReadinessTracker.xcodeproj`. CI: tree guard, unit tests, UI surfaces (`./scripts/ci-guard-tree.sh`, `ci-verify.sh`, `capture-surfaces.sh`). Simulator captures live under `.audit/verify-*.png`.

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/ci-verify.sh
```

**Setup.** HealthKit on device. Fitbit: `Secrets.xcconfig.example` → `Secrets.xcconfig` (`FITBIT_SETUP.md`, `docs/DEVICE_SETUP.md`). App Group `group.com.readinesstracker` for widgets.

![Today](.audit/verify-dashboard.png)
