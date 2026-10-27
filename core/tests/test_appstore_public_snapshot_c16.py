"""Pinned, read-only Apple Lookup evidence for all four public storefront apps.

No network calls in CI: the live lookup is conducted separately, and the dated
snapshot prevents stale public version assumptions from contaminating RC gates.
"""
import datetime
import json
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'core/appstore/staged-2026-10-26/editorial/c16-public-storefront-snapshot.json'
IDS={'photo','pushkin','what','chickmark'}

class PublicAppStoreC16(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.snapshot=json.loads(SOURCE.read_text())
    def test_full_applookup_matrix(self):
        countries=self.snapshot['countries']
        self.assertEqual(len(countries),16)
        for country,apps in countries.items():
            self.assertEqual(set(apps),IDS,country)
            for app,info in apps.items():
                self.assertRegex(info['version'],r'^\d+(?:\.\d+){1,3}$')
                self.assertTrue(info['name'],(app,country))
                self.assertTrue(info['languages'],(app,country))
                self.assertGreaterEqual(info['screenshots']['screenshotUrls'],1)
    def test_public_snapshot_not_asc_release_approval(self):
        self.assertIn('not App Store Connect',self.snapshot['source'])
        dt=datetime.datetime.fromisoformat(self.snapshot['asOfUTC'])
        self.assertIsNotNone(dt.tzinfo)
        # Snapshot does not and cannot contain unpublished ASC build or keyword secrets.
        for apps in self.snapshot['countries'].values():
            for info in apps.values():
                self.assertNotIn('keywords',info)
                self.assertNotIn('buildNumber',info)
                self.assertNotIn('appPrivacy',info)
    def test_habits_release_archive_is_separate_github_ci_gate(self):
        workflow=(ROOT/'.github/workflows/habits-ios-ci.yml').read_text()
        unit,archive=workflow.split('\n  archive-smoke:',1)
        self.assertIn('    timeout-minutes: 45',unit)
        self.assertNotIn('scripts/archive_smoke.sh',unit)
        self.assertIn('    timeout-minutes: 25',archive)
        self.assertIn('scripts/archive_smoke.sh',archive)

    def test_current_ru_public_versions_and_categories(self):
        apps=self.snapshot['countries']['ru']
        self.assertEqual({app:v['version'] for app,v in apps.items()},{
            'photo':'1.0.3','pushkin':'1.0.2','what':'1.1.1','chickmark':'1.5.2'})
        self.assertEqual(apps['chickmark']['category'],'Productivity')
        self.assertEqual(apps['pushkin']['minimumOs'],'27.0')
if __name__=='__main__':
    unittest.main()
