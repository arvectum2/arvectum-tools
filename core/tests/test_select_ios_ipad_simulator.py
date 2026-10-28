"""Never report an iPhone-only simulator run as iPad layout QA."""
import importlib.util
import unittest
from pathlib import Path

f = Path(__file__).resolve().parents[1] / 'tools/select_ios_ipad_simulator.py'
spec = importlib.util.spec_from_file_location('ipad_selector', f)
selector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selector)


class IPadSelectionTests(unittest.TestCase):
    def test_prefer_27_air_to_other_ipad_or_iphone(self):
        sample = {'devices': {'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [
            {'name': 'iPhone 18 Pro', 'udid': 'phone', 'state': 'Booted'},
            {'name': 'iPad Pro', 'udid': 'pro', 'state': 'Shutdown'},
            {'name': 'iPad Air', 'udid': 'air', 'state': 'Shutdown'}]}}
        self.assertEqual(selector.choose_ipad(sample), ('air', 'iPad Air'))

    def test_block_if_no_available_pad(self):
        sample = {'devices': {'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [
            {'name': 'iPhone 18', 'udid': 'phone', 'state': 'Booted'},
            {'name': 'iPad Air', 'udid': 'pad', 'state': 'Shutdown', 'isAvailable': False}]}}
        self.assertIsNone(selector.choose_ipad(sample))

    def test_ignore_wrong_runtime_and_unavailable_state(self):
        sample = {'devices': {'com.apple.CoreSimulator.SimRuntime.iOS-27-1': [
            {'name': 'iPad invalid', 'udid': 'bad', 'state': 'Unavailable'},
            {'name': 'iPad ready', 'udid': 'good', 'state': 'Booted'}],
            'com.apple.CoreSimulator.SimRuntime.iOS-26-0': [
                {'name': 'iPad old', 'udid': 'old', 'state': 'Booted'}]}}
        self.assertEqual(selector.choose_ipad(sample), ('good', 'iPad ready'))


if __name__ == '__main__':
    unittest.main()
