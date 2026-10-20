# ReadinessTracker

iOS readiness app. Bright Apple Health UI.

**Sources.** Apple Health (HealthKit) by default. Optional **Fitbit** via Google Health API (`DataSource.fitbit`; secrets in gitignored `Secrets.xcconfig`). WHOOP metrics appear when shared into Apple Health — no unofficial WHOOP OAuth.

**Today.** Gym / Work / Sleep rings + READY; check-in; recommendations. **Load Simulator** (seed from air, A/B snapshots + READY Δ gauge, lever deltas + sensitivity + polarity bars, checkable air-gap tasks, lift progress + next preview + READY ceiling + path spark + path zones + READY zones + zone jump + seedΔ + task radial + ring deltas + ring parity + composition stack + task waterfall + impact ladder + READY pace + impact share + air coverage radar + READY headroom + burn-down + GH triad + task ring mix + batch lift + seed confidence + READY momentum + zone buffer + task efficiency + READY climb + READY handoff). **Fitbit/Health Air** (density legend + ring cycle, spark scrub/Δ vs avg + density hist + CV + skew + IQR + percentile + envelope + MAD + Tukey fences + slope + z-score + ACF₁ + entropy + kurtosis + span + Gini + volatility + outliers + HHI + drawdown + rebound + Sharpe + Sortino + Calmar + Omega + forecast vs mean + confidence + 3-day horizon + residual spark + hit-rate + bias, gaps + category fill gauges). **Balance Dial** zone snaps. Body tiles + Recovery / Strain / sleep stack. Tonight | Baseline cards open classic **`MetricDetailView`** (Steps-parity `*.md.nav`).

**Elsewhere.** History, Check-in, Settings. Home + Lock widgets. Watch app and complications.

**Build.**

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/ci-verify.sh
```

CI: `ci-guard-tree.sh`, `ci-verify.sh`, `capture-surfaces.sh`. Screenshots under `.audit/verify-*.png`.

**Setup.** HealthKit on device. Fitbit: `Secrets.xcconfig.example` → `Secrets.xcconfig` (`FITBIT_SETUP.md`). App Group `group.com.readinesstracker`.

![Today](.audit/verify-dashboard.png)
