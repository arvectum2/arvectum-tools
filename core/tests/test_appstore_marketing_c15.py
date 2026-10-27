"""C15: offline integrity tests for truthful iPad promotional composites."""
import hashlib,json,struct,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'core/appstore/staged-2026-10-26'
def jpeg_dimensions(path):
 data=path.read_bytes()
 if not data.startswith(b'\xff\xd8'):raise ValueError('Not JPEG: '+str(path))
 pos=2
 while pos < len(data)-12:
  if data[pos] != 255:
   pos+=1;continue
  marker=data[pos+1];pos+=2
  if marker in (0xD8,0xD9):continue
  if pos+2>len(data):break
  count=int.from_bytes(data[pos:pos+2],'big')
  if marker in (0xC0,0xC1,0xC2,0xC3):
   height=int.from_bytes(data[pos+3:pos+5],'big')
   width=int.from_bytes(data[pos+5:pos+7],'big')
   return width,height
  pos+=count
 raise ValueError('No JPEG SOF')
class MarketingC15(unittest.TestCase):
 def test_marketing_screens_show_only_real_recorded_ui(self):
  d=json.loads((STAGE/'editorial/c15-ipad-marketing-manifest.json').read_text())
  self.assertEqual(d['stage'],'DRAFT_NOT_UPLOADED')
  self.assertEqual(set(d['apps']),{'photo','what','chickmark'})
  unique=set()
  for app,records in d['apps'].items():
   self.assertEqual(len(records),64)
   for r in records:
    p=ROOT/r['marketingPath']
    self.assertTrue(p.is_file(),p)
    self.assertEqual(jpeg_dimensions(p),(2064,2752))
    self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),r['sha256'])
    unique.add(r['marketingPath'])
    self.assertEqual(len(r['sources']),2)
    self.assertIn(r['position'],(1,2,3,4))
    for src in r['sources']:
     native=ROOT/src['path']
     self.assertTrue(native.is_file(),native)
     self.assertEqual(hashlib.sha256(native.read_bytes()).hexdigest(),src['sha256'])
    self.assertEqual(r['stage'],'SIMULATOR_MARKETING_DRAFT')
  self.assertEqual(len(unique),144)
 def test_offline_marketing_gallery_has_all_regional_frames(self):
  html=(STAGE/"review-marketing-c15.html").read_text()
  self.assertEqual(html.count('<img loading="lazy"'),192)
  self.assertNotIn('<script src=',html)
  self.assertNotIn('fetch(',html)
if __name__=='__main__':unittest.main()
