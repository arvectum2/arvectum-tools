"""Check the offline ASO gallery references all staged native screenshot slots."""
import json
import re
import unittest
from pathlib import Path
from urllib.parse import unquote
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/"core/appstore/staged-2026-10-26"
class ASOReviewGalleryTests(unittest.TestCase):
    def test_gallery_is_local_only_and_complete(self):
        content=(STAGE/"review-gallery.html").read_text(encoding="utf-8")
        self.assertNotIn("<script src=",content)
        self.assertNotIn("fetch(",content)
        match=re.search(r'<script type="application/json" id="data">(.*?)</script>',content,re.DOTALL)
        self.assertIsNotNone(match)
        rows=json.loads(match.group(1))
        self.assertEqual(len(rows),112)
        self.assertEqual(sum(len(row["images"]) for row in rows),448)
        for row in rows:
            self.assertEqual(len(row["images"]),4)
            for shot in row["images"]:
                path=STAGE/unquote(shot["src"])
                self.assertTrue(path.is_file(),f"Missing gallery image: {path}")
if __name__=="__main__":
    unittest.main()
