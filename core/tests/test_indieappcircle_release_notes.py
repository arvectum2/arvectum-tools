"""Ensure curated feedback release notes are localizable, honest and reproducible."""
import json
import subprocess
import sys
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'core/appstore/staged-2026-10-26'

class FeedbackReleaseNotes(unittest.TestCase):
    def test_all_four_apps_have_16_localized_release_notes(self):
        overrides=json.loads((STAGE/'editorial/c17-feedback-whatsnew-overrides.json').read_text())
        self.assertEqual(set(overrides),{'photo','pushkin','what','chickmark'})
        for app,versions in overrides.items():
            self.assertEqual(len(versions),16)
            metadata=json.loads((STAGE/(app+'.json')).read_text())['localeData']
            for locale,note in versions.items():
                with self.subTest(app=app,locale=locale):
                    self.assertEqual(metadata[locale]['whatsNew'],note['after'])
                    self.assertTrue(note['after'].strip())
                    self.assertLessEqual(len(note['after']),4000)
                    self.assertNotIn('Demo Ad',note['after'])
                    self.assertNotIn('No data collected',note['after'])
    def test_reapplying_curated_editorial_notes_is_idempotent(self):
        watched=['photo','pushkin','what','chickmark']
        before={n:(STAGE/(n+'.json')).read_bytes() for n in watched}
        result=subprocess.run([sys.executable,str(ROOT/'core/tools/apply_appstore_editorial.py')],
                              text=True,capture_output=True)
        self.assertEqual(result.returncode,0,result.stderr[:200])
        self.assertEqual(before,{n:(STAGE/(n+'.json')).read_bytes() for n in watched})
    def test_c17_build_versions_are_newer_than_public(self):
        versions={'photo-pdf-to-size':('1.0.4','16'),
                  'pushkin':('1.0.3','7'),'what':('1.1.2','10'),
                  'chickmark':('1.5.3','21')}
        for app,(version,build) in versions.items():
            project=(ROOT/app/'ios/project.yml').read_text()
            self.assertIn('MARKETING_VERSION: "'+version+'"',project)
            self.assertIn('CURRENT_PROJECT_VERSION: "'+build+'"',project)
if __name__=='__main__':unittest.main()
