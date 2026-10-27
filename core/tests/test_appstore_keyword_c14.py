"""Assert Apple ASO keyword dedup stays reproducible without live mutations."""
import json,re,unittest
from pathlib import Path
STAGE=Path(__file__).resolve().parents[1]/'appstore/staged-2026-10-26'
class KeywordC14(unittest.TestCase):
 def test_curated_overrides_and_no_exact_header_repeats(self):
  changes=json.loads((STAGE/'editorial/c14-keyword-overrides.json').read_text())
  self.assertEqual(sum(map(len,changes.values())),45)
  for app in ('photo','pushkin','what','chickmark'):
   rows=json.loads((STAGE/(app+'.json')).read_text())['localeData']
   self.assertEqual(len(rows),16)
   for locale,meta in rows.items():
    k=meta['keywords'];self.assertLessEqual(len(k.encode()),100)
    title=set(re.findall(r'[^\W_]+',(meta['name']+' '+meta['subtitle']).casefold()))
    self.assertFalse([x for x in k.split(',') if len(x)>2 and ' ' not in x and x.casefold() in title],(app,locale))
    if locale in changes.get(app,{}):
     self.assertEqual(k,changes[app][locale]['after'])
 def test_c14_did_not_modify_non_keyword_metadata(self):
  changes=json.loads((STAGE/'editorial/c14-keyword-overrides.json').read_text())
  for app,rows in changes.items():
   for locale,record in rows.items():
    self.assertNotEqual(record['before'],record['after'])
    self.assertTrue(record['removed'] or app in ('pushkin','what','chickmark'))
if __name__=='__main__':unittest.main()
