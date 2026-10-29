"""Regression checks for reviewed Arvectum Tools localization copy.

The source locale's presence and key parity are NOT human editorial sign-off.
This test guards technical parity and previously observed semantic mistranslations.
"""
from __future__ import annotations

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]

CATALOGS = {
    "photo": ROOT / "photo-pdf-to-size/ios/PhotoPodRazmer/Resources",
    "pushkin": ROOT / "pushkin/ios/ArvectumNotify/Resources",
    "what": ROOT / "what/ios/WhatIOS",
    "chickmark": ROOT / "chickmark/ios/HabitsByArvectum",
}
COMPLETE = (
    "en", "ru", "es", "fr", "de", "pt-BR", "pt-PT", "it", "ja",
    "ko", "zh-Hans", "zh-Hant", "nl", "id",
)
FORMAT = re.compile(r"%(?:\d+\$)?(?:@|[dDiIuUxXfFeEgGaAcCsSp])")
ENTRY = re.compile(r'^"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)";\s*$')


def catalog(path: Path) -> dict[str, str]:
    data = {}
    for index, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.startswith('"'):
            continue
        match = ENTRY.fullmatch(line)
        if match is None:
            raise AssertionError(f"{path}:{index} malformed .strings entry")
        key, value = match.groups()
        if key in data:
            raise AssertionError(f"{path}:{index} duplicate key: {key}")
        data[key] = value
    return data


class EditorialLocalizationRegressionTests(unittest.TestCase):
    def test_existing_ios_app_catalogs_preserve_keys_and_placeholders(self):
        for app, root in CATALOGS.items():
            reference = catalog(root / "en.lproj/Localizable.strings")
            locales = (*COMPLETE, "tr") if app != "chickmark" else COMPLETE
            for locale in locales:
                with self.subTest(app=app, locale=locale):
                    translated = catalog(root / f"{locale}.lproj/Localizable.strings")
                    self.assertEqual(set(reference), set(translated))
                    for key, en_text in reference.items():
                        self.assertEqual(
                            sorted(FORMAT.findall(en_text)),
                            sorted(FORMAT.findall(translated[key])),
                            f"{app}/{locale} placeholder mismatch at {key!r}",
                        )

    def test_korean_transcripts_backups_and_branding(self):
        what = catalog(CATALOGS["what"] / "ko.lproj/Localizable.strings")
        chick = catalog(CATALOGS["chickmark"] / "ko.lproj/Localizable.strings")
        watch = catalog(
            ROOT / "chickmark/ios/HabitsByArvectumWatch/ko.lproj/Localizable.strings"
        )
        widget = catalog(
            ROOT / "chickmark/ios/HabitsByArvectumWidget/ko.lproj/Localizable.strings"
        )
        self.assertEqual(what["Saved transcript"], "저장된 녹취록")
        self.assertEqual(what["Folder"], "폴더")
        self.assertEqual(what["Save"], "저장")
        self.assertIn("UhWhat?", what["UhWhat?: review a note"])
        self.assertEqual(chick["backup.menu"], "백업")
        self.assertEqual(chick["backup.result"], "백업")
        self.assertEqual(chick["review.attachment.noText"].split(".")[0], "아직 녹취록이 없습니다")
        self.assertEqual(watch["watch.completed"], "완료")
        self.assertEqual(watch["watch.health.unit.steps"], "걸음")
        self.assertEqual(widget["widget.action.complete.format"], "%@ 완료")
        self.assertEqual(widget["widget.empty.small"], "오늘 예정된 습관 없음")
        for text in (*what.values(), *chick.values(), *watch.values(), *widget.values()):
            self.assertNotIn("성적표", text)
            self.assertNotIn("어뭐", text)

    def test_french_widget_preserves_brand(self):
        path = ROOT / "what/ios/WhatPhoneWidget/fr.lproj/Localizable.strings"
        values = catalog(path)
        for text in values.values():
            self.assertNotIn("euh quoi", text.lower())
            if "UhWhat" in text:
                self.assertIn("UhWhat?", text)


if __name__ == "__main__":
    unittest.main()
