# Core CI impact coverage

Run `python3 core/tools/check_ci_coverage.py` to check that changes in Core
packages, SwiftPM manifests and shared dependency catalogs trigger builds of
the relevant product consumers. This is a policy guard, not a YAML interpreter;
supported workflows intentionally use direct, explicit `on.push.paths` and
`on.pull_request.paths` entries.

Core changes must reach the iOS apps, watchOS and Android via
`.github/workflows/core-ci.yml`. App workflows also run for changes that
affect their own builds. Where? is excluded until buildable app code exists.
The architecture workflow validates these filters so missing paths cannot
silently bypass product regressions. The actual builds and device QA remain
owned by the app workflows and release plans.
