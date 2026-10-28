"""Source-only safeguard for the planned Pushkin iOS 17 deployment target.

This confirms project consistency, NOT runtime support on iOS 17–26.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "pushkin/ios"


class PushkinMinimumDeploymentTests(unittest.TestCase):
    def test_xcodegen_specs_set_ios17_for_app_and_both_test_targets(self):
        for spec in ("project.yml", "project.physical-qa.yml"):
            text = (ROOT / spec).read_text()
            self.assertIn('iOS: "17.0"', text, spec)
            self.assertEqual(text.count('deploymentTarget: "17.0"'), 3, spec)
            self.assertNotIn('deploymentTarget: "27.0"', text, spec)

    def test_committed_native_project_does_not_revert_minimum_ios(self):
        text = (ROOT / "ArvectumNotifyIOS.xcodeproj/project.pbxproj").read_text()
        targets = re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);', text)
        self.assertTrue(targets)
        self.assertEqual(set(targets), {"17.0"})


if __name__ == "__main__":
    unittest.main()
