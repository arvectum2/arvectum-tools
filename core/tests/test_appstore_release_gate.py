"""A complete screenshot inventory must never be mistaken for release approval."""
import json,subprocess,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
STAGE=ROOT/'core/appstore/staged-2026-10-26/editorial'
class ReleaseApprovalBoundary(unittest.TestCase):
 def test_all_six_explicit_gates_still_require_signed_evidence(self):
  d=json.loads((STAGE/'c14-release-gate.json').read_text())
  self.assertEqual(d['stage'],'DRAFT_NOT_UPLOADED')
  self.assertEqual(len(d['requiredBeforeAppStoreMutation']),6)
  for name,v in d['requiredBeforeAppStoreMutation'].items():
   self.assertFalse(v['approved'],name)
   self.assertIsNone(v['evidence'],name)
 def test_release_cli_blocks_unapproved_mutation(self):
  cmd=[sys.executable,str(ROOT/'core/tools/check_appstore_release_readiness.py')]
  self.assertEqual(subprocess.run(cmd,capture_output=True).returncode,0)
  blocked=subprocess.run(cmd+['--for-release'],capture_output=True,text=True)
  self.assertEqual(blocked.returncode,2)
  self.assertIn('BLOCKED',blocked.stderr)
if __name__=='__main__':unittest.main()
