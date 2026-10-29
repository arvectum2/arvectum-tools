"""No fake localization coverage, screenshots, ASC readiness or submission."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'core/tools'))
import validate_appstore_locale_expansion as pending


class NewDutchStorefrontTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.draft = json.loads((pending.EXPANSION / 'photo-nl-NL.draft.json').read_text())
        cls.seed = json.loads((pending.STAGED / 'photo.json').read_text())
        registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
        cls.source_locales = set(registry['apps']['photo-pdf-to-size']['ios']['sourceCatalogs'])

    def test_dutch_is_a_valid_draft_not_a_released_localization(self):
        result = pending.validate(self.draft, self.seed, self.source_locales)
        self.assertEqual(result['metadata_locale'], 'nl-NL')
        self.assertEqual(result['new_asc_localization_exists'], 'UNVERIFIED')
        self.assertFalse(result['ready_for_upload'])
        self.assertFalse(result['screenshot_assets_ready'])
        self.assertEqual(self.draft['storefrontCountry'], 'NL')
        self.assertEqual(len(self.seed['localeData']), 16,
                         'Existing 64 staged regional cards must not be rewritten')
        self.assertEqual(len(self.draft['screenshotPlan']), 4)
        self.assertEqual(self.draft['screenshotAssets'], [])

    def test_fails_closed_without_native_source_or_real_capture_approval(self):
        with self.assertRaisesRegex(AssertionError, 'UI source locale'):
            pending.validate(self.draft, self.seed, self.source_locales - {'nl'})
        changes = [
            ('status', 'READY_FOR_REVIEW'),
            ('uploadedToASC', True),
            ('releaseApproved', True),
            ('humanEditorialApproved', True),
            ('screenshotAssets', ['made-up.png']),
            ('appleLocaleEnabledForThisAppInASC', True),
            ('appleMetadataLocale', 'nl-XX'),
            ('bundleId', 'other.bundle'),
        ]
        for key, value in changes:
            with self.subTest(key=key):
                copy_of_draft = copy.deepcopy(self.draft)
                copy_of_draft[key] = value
                with self.assertRaises(AssertionError):
                    pending.validate(copy_of_draft, self.seed, self.source_locales)

    def test_metadata_limits_and_privacy_risks(self):
        fields = self.draft['metadata']
        for key, max_length in pending.FIELD_LIMITS.items():
            self.assertLessEqual(len(fields[key]), max_length, key)
        self.assertLessEqual(len(fields['keywords'].encode('utf-8')), 100)
        self.assertIn('GOV.UK', fields['description'])
        self.assertIn('afbeeldingen', fields['description'])
        self.assertIn('privacybeleid', fields['description'])
        self.assertIn('apparaat', fields['description'])
        self.assertEqual(fields['privacyPolicyUrl'], self.seed['localeData']['en-GB']['privacyPolicyUrl'])
        for key, value in [('name', 'x'*31), ('keywords', 'x'*101),
                           ('description', 'x'*4001),
                           ('privacyPolicyUrl', 'https://bad.example/')]:
            with self.subTest(key=key):
                bad = copy.deepcopy(self.draft)
                bad['metadata'][key] = value
                with self.assertRaises(AssertionError):
                    pending.validate(bad, self.seed, self.source_locales)

    def test_pushkin_dutch_has_honest_shortcuts_copy_without_fake_capture(self):
        data = json.loads((pending.EXPANSION / 'pushkin-nl-NL.draft.json').read_text())
        seed = json.loads((pending.STAGED / 'pushkin.json').read_text())
        registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
        locales = set(registry['apps']['pushkin']['ios']['sourceCatalogs'])
        result = pending.validate(data, seed, locales)
        self.assertEqual(result['app'], 'pushkin')
        self.assertEqual(result['metadata_locale'], 'nl-NL')
        self.assertEqual(data['requiredRealNativeCaptures'], ['iphone-6.9'])
        self.assertEqual(data['screenshotAssets'], [])
        self.assertEqual(len(seed['localeData']), 16)
        self.assertFalse(result['ready_for_upload'])
        self.assertEqual(result['new_asc_localization_exists'], 'UNVERIFIED')
        description = data['metadata']['description']
        for phrase in ('Apple Opdrachten', 'niet toe', 'zelf toevoegen',
                       'uitgeschakeld', 'geen universeel', 'lokaal op je iPhone'):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, description)
        self.assertEqual(data['metadata']['privacyPolicyUrl'],
                         seed['localeData']['en-GB']['privacyPolicyUrl'])

    def test_pushkin_expansion_is_fail_closed_against_wrong_target_or_fake_approval(self):
        draft = json.loads((pending.EXPANSION / 'pushkin-nl-NL.draft.json').read_text())
        seed = json.loads((pending.STAGED / 'pushkin.json').read_text())
        registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
        available = set(registry['apps']['pushkin']['ios']['sourceCatalogs'])
        for key, value in (
            ('appId', 6816346084), ('bundleId', 'ru.arvectum.tools.tosize'),
            ('appleMetadataLocale', 'nl'), ('uploadedToASC', True),
            ('releaseApproved', True), ('screenshotQAApproved', True),
            ('screenshotAssets', ['imaginary.png']), ('appleLocaleEnabledForThisAppInASC', True),
            ('requiredRealNativeCaptures', ['iphone-6.9', 'ipad-13']),
        ):
            with self.subTest(key=key):
                mutated = copy.deepcopy(draft)
                mutated[key] = value
                with self.assertRaises(AssertionError):
                    pending.validate(mutated, seed, available)
        with self.assertRaisesRegex(AssertionError, 'UI source locale'):
            pending.validate(draft, seed, available - {'nl'})

    def test_what_dutch_is_a_private_watch_safe_draft_not_a_live_storefront(self):
        draft = json.loads((pending.EXPANSION / 'what-nl-NL.draft.json').read_text())
        seed = json.loads((pending.STAGED / 'what.json').read_text())
        registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
        available = set(registry['apps']['what']['ios']['sourceCatalogs'])
        result = pending.validate(draft, seed, available)
        self.assertEqual(result['metadata_locale'], 'nl-NL')
        self.assertFalse(result['ready_for_upload'])
        self.assertEqual(result['new_asc_localization_exists'], 'UNVERIFIED')
        self.assertEqual(draft['requiredRealNativeCaptures'], ['iphone-6.9', 'ipad-13'])
        self.assertEqual(draft['screenshotAssets'], [])
        self.assertEqual(len(draft['screenshotPlan']), 4)
        self.assertEqual(len(seed['localeData']), 16)
        description = draft['metadata']['description']
        for phrase in ('Apple Watch', 'totdat de iPhone', 'vertraagd',
                       'oorspronkelijke audio', 'spraakherkenning',
                       'afzonderlijke instellingen', 'lokaal op je apparaten'):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, description)
        self.assertEqual(draft['metadata']['privacyPolicyUrl'],
                         seed['localeData']['en-GB']['privacyPolicyUrl'])

    def test_what_dutch_rejects_nonexistent_source_or_fake_release_approval(self):
        draft = json.loads((pending.EXPANSION / 'what-nl-NL.draft.json').read_text())
        seed = json.loads((pending.STAGED / 'what.json').read_text())
        registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
        available = set(registry['apps']['what']['ios']['sourceCatalogs'])
        with self.assertRaisesRegex(AssertionError, 'UI source locale'):
            pending.validate(draft, seed, available - {'nl'})
        for key, value in (
            ('appId', 6816346084), ('bundleId', 'ru.arvectum.tools.tosize'),
            ('appleMetadataLocale', 'nl-XX'), ('releaseApproved', True),
            ('humanEditorialApproved', True), ('screenshotQAApproved', True),
            ('uploadedToASC', True), ('screenshotAssets', ['fake.png']),
            ('appleLocaleEnabledForThisAppInASC', True),
        ):
            with self.subTest(key=key):
                corrupted = copy.deepcopy(draft)
                corrupted[key] = value
                with self.assertRaises(AssertionError):
                    pending.validate(corrupted, seed, available)
