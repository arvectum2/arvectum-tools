#!/usr/bin/env python3
"""Fail-closed offline validation for *new* metadata localization drafts.

Distinct from the 16 existing released-storefront source baseline. No Apple
API calls, file uploads, screenshot synthesis or state mutations.
"""
from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
EXPANSION = ROOT / 'core/appstore/locale-expansion-2026-10-29'
STAGED = ROOT / 'core/appstore/staged-2026-10-26'
SUPPORTED_VERIFIED_PAIRS = {('NL', 'nl-NL', 'nl'), ('ID', 'id', 'id')}
SUPPORTED_APPS = {'photo': 'photo-pdf-to-size', 'pushkin': 'pushkin', 'what': 'what', 'chickmark': 'chickmark'}
REAL_DEVICE_CAPTURES = {'photo': ['iphone-6.9', 'ipad-13'], 'pushkin': ['iphone-6.9'], 'what': ['iphone-6.9', 'ipad-13'], 'chickmark': ['iphone-6.9', 'ipad-13']}
FIELD_LIMITS = {'name': 30, 'subtitle': 30, 'keywords': 100,
                'promotionalText': 170, 'description': 4000, 'whatsNew': 4000}
PENDING = 'COPY_DRAFT_NEEDS_EDITORIAL_AND_NATIVE_ASSETS'


def validate(data: dict, published_seed: dict, available_source_locales: set[str]) -> dict:
    assert data['status'] == PENDING, 'New region must remain a pending draft'
    assert (data['storefrontCountry'], data['appleMetadataLocale'],
            data['uiSourceLocale']) in SUPPORTED_VERIFIED_PAIRS, 'Not a reviewed Apple country/locale mapping'
    assert data['uiSourceLocale'] in available_source_locales, 'UI source locale not in Xcode'
    assert data['app'] in SUPPORTED_APPS, 'Unexpected app in regional expansion'
    assert data['bundleId'] == published_seed['bundleId']
    assert data['appId'] == published_seed['appId'], 'Wrong app metadata target'
    assert data['appleMetadataLocalePublishedSupport'] is True
    assert data['appleLocaleEnabledForThisAppInASC'] is None, 'No live ASC query was performed'
    assert data['uploadedToASC'] is False and data['releaseApproved'] is False
    assert data['humanEditorialApproved'] is False and data['screenshotQAApproved'] is False
    assert data['screenshotAssets'] == [], 'Do not claim uncaptured images exist'
    assert data['requiredRealNativeCaptures'] == REAL_DEVICE_CAPTURES[data['app']]
    assert all(isinstance(ref, str) and ref.startswith('https://developer.apple.com/')
               for ref in data['supportingAppleReferences'])
    fields = data['metadata']
    assert fields['privacyPolicyUrl'] == published_seed['localeData']['en-GB']['privacyPolicyUrl']
    for key, limit in FIELD_LIMITS.items():
        value = fields[key]
        assert isinstance(value, str) and value.strip() and len(value) <= limit, key
        if key == 'keywords':
            assert len(value.encode('utf-8')) <= limit, 'Keyword bytes overflow'
            tokens = value.lower().split(',')
            assert len(tokens) == len(set(tokens)), 'Duplicate keywords'
            assert all(t.strip() == t and t and ' ' not in t for t in tokens)
    assert len(data['screenshotPlan']) == 4
    assert [row['position'] for row in data['screenshotPlan']] == [1, 2, 3, 4]
    assert all(row['caption'].strip() and row['screen'].strip() for row in data['screenshotPlan'])
    return {'app': data['app'], 'country': data['storefrontCountry'],
            'metadata_locale': data['appleMetadataLocale'], 'source_locale': data['uiSourceLocale'],
            'fields_valid': True, 'new_asc_localization_exists': 'UNVERIFIED',
            'screenshot_assets_ready': False, 'ready_for_upload': False}


def main() -> None:
    registry = json.loads((ROOT / 'core/localization/portfolio-locales.json').read_text())
    registry_apps = registry['apps']
    paths = sorted(EXPANSION.glob('*.draft.json'))
    if not paths:
        raise SystemExit('No new-region drafts found')
    for path in paths:
        draft = json.loads(path.read_text())
        app = draft['app']
        assert app in SUPPORTED_APPS, f'Unsupported regional draft: {path.name}'
        assert path.name == f"{app}-{draft['appleMetadataLocale']}.draft.json", 'Unexpected file/locale mapping'
        seed = json.loads((STAGED / f'{app}.json').read_text())
        result = validate(draft, seed,
            set(registry_apps[SUPPORTED_APPS[app]]['ios']['sourceCatalogs']))
        print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    main()
