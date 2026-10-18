"""Regression tests for the Core GitHub Actions impact contract."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("check_ci_coverage.py")
spec = importlib.util.spec_from_file_location("check_ci_coverage", SCRIPT)
assert spec and spec.loader
coverage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(coverage)


class CICoverageTests(unittest.TestCase):
    def test_inline_and_block_paths_are_parsed(self):
        text = """name: test
on:
  push:
    branches: ['**']
    paths: ['core/packages/**', 'core/Package.swift']
  pull_request:
    paths:
      - 'core/packages/**'
      - 'core/dependencies/catalog.json'
  workflow_dispatch:
permissions:
  contents: read
jobs:
  test:
    runs-on: ubuntu-latest
"""
        self.assertEqual(coverage.event_paths(text, "push"), {"core/packages/**", "core/Package.swift"})
        self.assertEqual(coverage.event_paths(text, "pull_request"),
                         {"core/packages/**", "core/dependencies/catalog.json"})

    def test_missing_event_and_unfiltered_event_are_distinct(self):
        text = """on:
  push:
    paths: ['core/packages/**']
  pull_request:
permissions:
  contents: read
"""
        self.assertIsNone(coverage.event_paths(text, "pull_request"))
        with self.assertRaises(ValueError):
            coverage.event_paths(text, "workflow_dispatch")

    def test_missing_dependency_trigger_is_detected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "core-ci.yml"
            path.write_text("""on:
  push:
    paths: ['core/packages/**']
  pull_request:
    paths: ['core/packages/**']
""")
            errors = coverage.check_coverage(Path(tmp))
            self.assertTrue(any("core-ci.yml:push" in error and "core/Package.swift" in error
                                for error in errors), errors)

    def test_repository_workflows_cover_consumer_changes(self):
        self.assertEqual(coverage.check_coverage(), [])


if __name__ == "__main__":
    unittest.main()
