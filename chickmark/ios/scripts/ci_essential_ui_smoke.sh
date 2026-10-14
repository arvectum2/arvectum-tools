#!/usr/bin/env bash
# Xcode 27 on CI can keep xcodebuild alive long after the selected UI suites
# have passed. Preserve strict test assertions while bounding teardown latency.
set -euo pipefail

log="$(mktemp -t chickmark-essential-ui.XXXXXX)"
pid=""
cleanup() {
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill -TERM "$pid" 2>/dev/null || true
    sleep 2
    kill -KILL "$pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

xcodebuild \
  -project HabitsByArvectumIOS.xcodeproj \
  -onlyUsePackageVersionsFromResolvedFile \
  -scheme HabitsByArvectum \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -jobs 2 -parallel-testing-enabled NO \
  -only-testing:HabitsByArvectumUITests/HabitFlowUITests/testAccessibilityAuditCoreScreens \
  -only-testing:HabitsByArvectumUITests/HabitFlowUITests/testMultiCheckHistoryIndividualSlotsPersist \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test \
  > "$log" 2>&1 &
pid=$!

# No synthetic success: every expected test must actually report PASSED and
# XCTest must report the entire selected suite with zero failures.
selected_suite_passed() {
  grep -Fq "testAccessibilityAuditCoreScreens]' passed" "$log" &&
  grep -Fq "testMultiCheckHistoryIndividualSlotsPersist]' passed" "$log" &&
  grep -Fq "Test Suite 'Selected tests' passed" "$log" &&
  grep -Eq 'Executed 2 tests, with 0 failures \(0 unexpected\)' "$log" &&
  ! grep -Eq "Test Case '.*' failed|Test Suite '.*' failed|with [1-9][0-9]* failures|TEST FAILED|Failing tests:" "$log"
}

# The workflow retains its outer timeout as a hard safety bound.
for (( tick=0; tick<90; tick++ )); do
  if ! kill -0 "$pid" 2>/dev/null; then
    set +e
    wait "$pid"
    result=$?
    set -e
    pid=""
    tail -n 35 "$log"
    exit "$result"
  fi

  if selected_suite_passed; then
    # Give Xcode its ordinary cleanup opportunity first.
    sleep 15
    if ! kill -0 "$pid" 2>/dev/null; then
      set +e
      wait "$pid"
      result=$?
      set -e
      pid=""
      tail -n 35 "$log"
      exit "$result"
    fi
    echo 'Xcode 27 UI tests passed 2/2 with zero failures; terminating stalled runner teardown.'
    tail -n 35 "$log"
    exit 0
  fi

  if (( tick % 10 == 0 )); then
    echo "Waiting for selected UI smoke: $((tick * 3))s elapsed"
    tail -n 3 "$log" || true
  fi
  sleep 3
done

echo 'UI smoke did not complete inside the CI-specific 270-second budget.'
tail -n 70 "$log"
exit 1
