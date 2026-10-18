#!/usr/bin/env bash
# Repeatable Core baseline gate; application release gates remain product-owned.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
printf '\n[1/4] Architecture contract\n'
python3 core/tools/check_architecture.py
printf '\n[2/4] SwiftPM lockfiles\n'
python3 core/tools/check_swift_lockfiles.py
printf '\n[3/4] Shared dependency projections\n'
python3 core/tools/sync_dependencies.py --check
printf '\n[4/4] Core Swift tests\n'
swift test --package-path core
printf '\nCORE BASELINE PASS\n'
