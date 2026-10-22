"""Static security/regression checks for the Android-only Debug QA harness.

Runtime image processing is validated on Android Emulator. These tests guard
against accidentally exposing the debug-only receiver to Release sources.
"""
import unittest
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[2]
ANDROID = ROOT / "photo-pdf-to-size/android/app/src"
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"


class DebugImageQaIsolationTests(unittest.TestCase):
    def test_debug_receiver_requires_privileged_shell_permission(self):
        debug_manifest = ElementTree.parse(
            ANDROID / "debug/AndroidManifest.xml"
        ).getroot()
        receivers = debug_manifest.findall(".//receiver")
        self.assertEqual(len(receivers), 1)
        receiver = receivers[0]
        self.assertEqual(
            receiver.attrib[ANDROID_NS + "name"], ".qa.ImagePipelineQaReceiver"
        )
        self.assertEqual(
            receiver.attrib[ANDROID_NS + "permission"], "android.permission.DUMP"
        )
        self.assertEqual(receiver.attrib[ANDROID_NS + "exported"], "true")

    def test_production_source_does_not_register_debug_receiver(self):
        manifest = (ANDROID / "main/AndroidManifest.xml").read_text()
        self.assertNotIn("ImagePipelineQaReceiver", manifest)
        self.assertNotIn("QA_IMAGE_PIPELINE", manifest)
        self.assertFalse(
            list((ANDROID / "main").rglob("ImagePipelineQaReceiver.kt"))
        )
        self.assertFalse(
            list((ANDROID / "release").rglob("ImagePipelineQaReceiver.kt"))
        )

    def test_receiver_uses_real_pipeline_with_local_synthetic_image(self):
        qa = (
            ANDROID /
            "debug/java/ru/arvectum/tools/tosize/qa/ImagePipelineQaReceiver.kt"
        ).read_text()
        for call in (
            "storage.inspect(uri)", "engine.compressByBytes(",
            "engine.resizeLongSide(", "engine.preparePassport(",
            "storage.save(result, targetUri)", "ExifInterface(passport.file)"
        ):
            self.assertIn(call, qa)
        self.assertIn("Random(914441L)", qa)
        self.assertNotIn("READ_MEDIA_IMAGES", qa)
        self.assertIn("pending.finish()", qa)


if __name__ == "__main__":
    unittest.main()
