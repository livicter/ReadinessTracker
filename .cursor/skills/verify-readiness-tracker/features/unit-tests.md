# Unit tests

## Sub-features
- Strain / recovery / HRV / readiness calculators
- Coaching engine and AI recommendation rules
- Sleep cycle / stage helpers

## How to get to it (user POV)
Developer runs the test suite; end users never see this surface.

## Driving it with ci-verify
```bash
./scripts/ci-verify.sh
```

## Gotchas
- Prefer an explicit simulator name if `OS=latest` mismatches.
- Use `CODE_SIGNING_ALLOWED=NO` for simulator unit tests (already in the script).
