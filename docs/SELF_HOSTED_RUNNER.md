# Self-hosted macOS runner (Mac mini)

CI `ios-tests` and `ios-ui` run on a self-hosted Mac mini. `tree-guard` stays on `ubuntu-latest`.

## Runner location

- Directory: `/Users/victor/actions-runner`
- Registered name: `mac-mini`
- Required labels (workflow `runs-on`): `self-hosted`, `macOS`, `ARM64`
  - GitHub adds `self-hosted` automatically; configure with `--labels macOS,ARM64`.

## Prerequisites

- Xcode installed and selected on PATH (`xcode-select -p` / `xcodebuild -version`)
- At least one available iPhone simulator (`xcrun simctl list devices available`)
- `Secrets.xcconfig` stays gitignored — never commit it; local/CI secrets stay on the machine only

## Start / stop (LaunchAgent service)

```bash
cd /Users/victor/actions-runner
./svc.sh status
./svc.sh start   # or stop / uninstall
```

If the service is unavailable, fall back to:

```bash
cd /Users/victor/actions-runner
nohup ./run.sh > runner.log 2>&1 &
```

Confirm Idle before relying on CI:

```bash
gh api repos/livicter/ReadinessTracker/actions/runners
# expect status=online, busy=false
```
