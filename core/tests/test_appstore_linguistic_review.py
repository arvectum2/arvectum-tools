"""Guard hand-reviewed multilingual ASO texts against reverting to machine copy."""
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/"core/appstore/staged-2026-10-26"
MANUAL=STAGE/"editorial/c13-overrides.json"
class LinguisticASOReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.overrides=json.loads(MANUAL.read_text())
    def test_complete_review_and_canonical_fields(self):
        self.assertEqual({a:len(v) for a,v in self.overrides.items()},
                         {"pushkin":11,"what":11,"chickmark":11,"photo":2})
        fields={"promotionalText","description","whatsNew","keywords","screenshots"}
        for app,locales in self.overrides.items():
            data=json.loads((STAGE/(app+".json")).read_text())["localeData"]
            for loc,patch in locales.items():
                self.assertTrue(fields<=set(patch),(app,loc))
                self.assertEqual(len(patch["screenshots"]),4)
                for key in fields:
                    self.assertEqual(data[loc][key],patch[key],(app,loc,key))
                self.assertLessEqual(len(patch["keywords"].encode("utf-8")),100)
                self.assertLessEqual(len(patch["promotionalText"]),170)
    def test_bad_automated_terms_no_longer_present_in_reviewed_copy(self):
        banned={"POUCHKINE","Streifen","条纹","條紋","시청","ASSISTIR:","MIRAR:",
                "遗失帐户","觀看","assistir:","REGARDER :","RELÓGIO E WIDGETS",
                "assistir,"}
        for app,locales in self.overrides.items():
            for loc,p in locales.items():
                joined=" ".join([p["description"],p["promotionalText"],
                                 p["keywords"],*p["screenshots"]])
                for term in banned:
                    self.assertNotIn(term,joined,(app,loc,term))
    def test_guardrails_are_retained(self):
        for loc,p in self.overrides["pushkin"].items():
            self.assertIn("iOS",p["description"],loc)
            self.assertIn("PUSHKIN",p["description"],loc)
        for loc,p in self.overrides["what"].items():
            self.assertIn("Apple Watch",p["description"],loc)
            self.assertIn("iOS",p["description"],loc)
        for loc,p in self.overrides["chickmark"].items():
            self.assertIn("APPLE",p["description"].upper(),loc)
            self.assertIn("Apple",p["description"],loc)
        for loc,p in self.overrides["photo"].items():
            self.assertIn("PDF",p["description"],loc)
            self.assertIn("SDK",p["description"],loc)
if __name__=="__main__":
    unittest.main()
