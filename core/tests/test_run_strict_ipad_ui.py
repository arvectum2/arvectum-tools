"""Bounded runner must never accept partial XCTest logs as green."""
import importlib.util
from pathlib import Path
import unittest

p = Path(__file__).resolve().parents[1] / 'tools/run_strict_ipad_ui.py'
spec = importlib.util.spec_from_file_location('xctest_gate', p)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class StrictIPadXCTestTests(unittest.TestCase):
    _pass_log = ("Test Case '-[WhatIOSUITests.CaptureFirstUITests testIPadRotation]' passed (9s).\n"
                 "Test Suite 'Selected tests' passed at 00:00.\n"
                 'Executed 1 test, with 0 failures (0 unexpected)\n')

    def test_exact_finished_case_is_required(self):
        self.assertTrue(gate.verified(self._pass_log, ['testIPadRotation']))
        self.assertFalse(gate.verified(self._pass_log, ['testIPadOther']))
        self.assertFalse(gate.verified(self._pass_log, ['testIPadRotation','testIPadOther']))

    def test_suite_pass_and_zero_failures_both_required(self):
        self.assertFalse(gate.verified(self._pass_log.replace("Selected tests' passed", "Selected tests' started"), ['testIPadRotation']))
        self.assertFalse(gate.verified(self._pass_log.replace('0 failures', '1 failures'), ['testIPadRotation']))

    def test_any_failure_or_xcode_failed_is_rejected(self):
        for extra in ('** TEST FAILED **',
                      "Test Case '-[Foo testFailure]' failed",
                      "Test Suite 'Selected tests' failed"):
            self.assertFalse(gate.verified(self._pass_log + '\n' + extra, ['testIPadRotation']))


if __name__ == '__main__':
    unittest.main()
