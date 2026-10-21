"""Static regression gate for the Android GUI Photo Picker QA runner.

The GUI test itself must be run on an Android emulator and its result
must be read from qa-photo-picker-report.json. Static checks do NOT
claim that the end-to-end Android GUI test passed.
"""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
TOOLS=ROOT/"photo-pdf-to-size/android/tools"

class AndroidPickerQaRunnerTest(unittest.TestCase):
    def test_runner_uses_real_photo_picker_and_export_not_internal_receiver(self):
        script=(TOOLS/"qa_photo_picker_e2e.py").read_text()
        for expected in (
            "Choose photo", "Photo taken", "Done", "900×700 px",
            "500 KB", "Compress to 500 KB", "Save",
            "qa-photo-picker-report.json", "qa-picker-exported.jpg",
            "jpeg-verified-in-downloads", "QA_FULL_GUI_E2E_PASS",
        ):
            self.assertIn(expected,script)
        self.assertNotIn("QA_IMAGE_PIPELINE",script)
        self.assertNotIn("ImagePipelineQaReceiver",script)

    def test_script_generates_synthetic_local_data_only(self):
        script=(TOOLS/"qa_photo_picker_e2e.py").read_text()
        self.assertIn("make_synthetic_png(source)",script)
        self.assertIn("random.Random(914441)",script)
        self.assertNotIn("Library/Photos",script)
        self.assertIn("ArvectumSSD",script)

    def test_emulator_guard_refuses_existing_instance_and_bad_output_path(self):
        wrapper=(TOOLS/"qa_photo_picker_emulator.sh").read_text()
        self.assertIn("emulator-5554",wrapper)
        self.assertIn("Won't replace existing emulator",wrapper)
        self.assertIn("QA output must be on ArvectumSSD",wrapper)
        self.assertIn("trap cleanup EXIT",wrapper)

if __name__ == "__main__":
    unittest.main()
