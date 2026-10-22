# ReadinessTracker

iOS readiness app. Bright Apple Health UI.

**Sources.** Apple Health (HealthKit) by default. Optional **Fitbit** via Google Health API (`DataSource.fitbit`; secrets in gitignored `Secrets.xcconfig`). WHOOP metrics appear when shared into Apple Health — no unofficial WHOOP OAuth.

**Today.** Gym / Work / Sleep rings + READY; check-in; recommendations. **Load Simulator** (seed from air, A/B snapshots + READY Δ gauge, lever deltas + sensitivity + polarity bars, checkable air-gap tasks, lift progress + next preview + READY ceiling + path spark + path zones + READY zones + zone jump + seedΔ + task radial + ring deltas + ring parity + composition stack + task waterfall + impact ladder + READY pace + impact share + air coverage radar + READY headroom + burn-down + GH triad + task ring mix + batch lift + seed confidence + READY momentum + zone buffer + task efficiency + READY climb + READY handoff + climb pace + climb ETA + climb surplus + climb runway + climb glide + climb intercept). **Fitbit/Health Air** (density legend + ring cycle, spark scrub/Δ vs avg + density hist + CV + skew + IQR + percentile + envelope + MAD + Tukey fences + slope + z-score + ACF₁ + entropy + kurtosis + span + Gini + volatility + outliers + HHI + drawdown + rebound + Sharpe + Sortino + Calmar + Omega + Ulcer + Sterling + Burke + Martin + Kappa + Gain/Pain + Tail + density detail sheet (cat overlays) + Health Air Today scrub/Gain–Pain glance + cat overlays + 7/14/30d period + Health density Detail sheet + scrub readout + Health Gain/Pain meter (#628 parity) + Health Tail (#629 parity) + Health Martin (#624 parity) + Health Kappa (#627 parity) + Health Burke (#622 parity) + Health Sterling (#620 parity) + Health Ulcer (#618 parity) + Health Omega (#616 parity) + Health Calmar (#614 parity) + Health Sortino (#612 parity) + Health Sharpe (#610 parity) + Health Rebound (#608 parity) + Health Span (#596 parity) + Health Kurtosis (#594 parity) + Health Entropy (#592 parity) + Health ACF (#590 parity) + Health slope (#586 parity) + Health z-score (#588 parity) + Health Skew (#574 parity) + Health IQR (#576 parity) + Health Gini (#598 parity) + Health Percentile (#578 parity) + Health Volatility (#600 parity) + Health Outliers (#602 parity) + Health HHI (#604 parity) + Health Drawdown (#606 parity) + Health gaps/category fill + forecast vs mean + confidence + 3-day horizon + residual spark + hit-rate + bias, gaps + category fill gauges). **Balance Dial** zone snaps. Body tiles + Recovery / Strain / sleep stack. Tonight | Baseline cards open classic **`MetricDetailView`** (Steps-parity `*.md.nav`).

**Elsewhere.** History, Check-in, Settings (Fitbit + Health air density ring + category fill). Home + Lock widgets. Watch app and complications.

**Build.**

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/ci-verify.sh
```

CI: `ci-guard-tree.sh`, `ci-verify.sh`, `capture-surfaces.sh`. Screenshots under `.audit/verify-*.png`.

**Setup.** HealthKit on device. Fitbit: `Secrets.xcconfig.example` → `Secrets.xcconfig` (`FITBIT_SETUP.md`). App Group `group.com.readinesstracker`.

![Today](.audit/verify-dashboard.png)
