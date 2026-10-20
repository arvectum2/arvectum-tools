"""Pure Python localization registry/format safety checks."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "core/tools"))
import localization_portfolio as i18n


class LocalizationPortfolioTests(unittest.TestCase):
    def test_registry(self):
        reg = i18n.config()
        self.assertEqual(len(reg["targets"]), 50)
        self.assertEqual(reg["targets"][0]["code"], "en")
        self.assertEqual(reg["fallback"], "en")
        self.assertEqual(set(reg["apps"]), {"chickmark", "pushkin", "what", "photo-pdf-to-size", "where"})
        self.assertEqual(reg["apps"]["photo-pdf-to-size"]["android"]["sourceLocale"], "en")
        self.assertEqual([sum(x["tier"] == t for x in reg["targets"]) for t in (1, 2, 3)], [20, 20, 10])

    def test_placeholders(self):
        self.assertEqual(i18n.placeholders("%d of %@"), i18n.placeholders("%2$@ from %1$d"))
        self.assertNotEqual(i18n.placeholders("%d of %@"), i18n.placeholders("%@"))
        self.assertEqual(i18n.placeholders("Print at 100% scale"), {})

    def test_existing_catalogs(self):
        self.assertEqual(i18n.audit(i18n.config()), 0)

    def test_english_development_region(self):
        for name in ("chickmark/ios/HabitsByArvectumIOS", "photo-pdf-to-size/ios/PhotoPodRazmerIOS", "pushkin/ios/ArvectumNotifyIOS", "what/ios/What"):
            project = ROOT / (name + ".xcodeproj/project.pbxproj")
            with self.subTest(name=name):
                self.assertIn("developmentRegion = en;", project.read_text())


if __name__ == "__main__":
    unittest.main()
