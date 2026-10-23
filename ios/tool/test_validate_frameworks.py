import os
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

from validate_frameworks import minimum_os, validate


class FrameworkValidationTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.app = Path(self.directory.name) / 'Runner.app'
        self.framework = self.app / 'Frameworks/onnxruntime.framework'
        self.framework.mkdir(parents=True)
        self.write(self.app / 'Info.plist', {'MinimumOSVersion': '15.5'})
        self.write(self.framework / 'Info.plist', {
            'MinimumOSVersion': '15.1', 'CFBundleExecutable': 'onnxruntime',
        })

    def write(self, path, data):
        path.write_bytes(plistlib.dumps(data))

    @patch('validate_frameworks.subprocess.check_output', return_value='    minos 15.1\n    minos 15.5\n')
    def test_uses_highest_minimum_across_architectures(self, _):
        self.assertEqual(minimum_os(Path('binary')), '15.5')

    @patch('validate_frameworks.subprocess.check_output', return_value='    version 15.1\n    sdk 18.0\n')
    def test_accepts_legacy_load_command(self, _):
        self.assertEqual(minimum_os(Path('binary')), '15.1')

    @patch('validate_frameworks.minimum_os', return_value='15.5')
    def test_archive_check_rejects_original_app_store_mismatch(self, _):
        with self.assertRaisesRegex(ValueError, 'plist declares 15.1'):
            validate(self.app)

    @patch.dict(os.environ, {'CODE_SIGNING_ALLOWED': 'YES', 'EXPANDED_CODE_SIGN_IDENTITY': 'test-identity'})
    @patch('validate_frameworks.subprocess.run')
    @patch('validate_frameworks.minimum_os', return_value='15.5')
    def test_repairs_and_resigns_only_the_onnx_framework(self, _, run):
        validate(self.app, repair_onnx=True)
        info = plistlib.loads((self.framework / 'Info.plist').read_bytes())
        self.assertEqual(info['MinimumOSVersion'], '15.5')
        self.assertEqual(info['CFBundleExecutable'], 'onnxruntime')
        self.assertEqual(run.call_args.args[0][0:4], ['codesign', '--force', '--sign', 'test-identity'])
        validate(self.app)
        self.assertEqual(run.call_count, 1)

    @patch('validate_frameworks.minimum_os', return_value='16.0')
    def test_never_hides_incompatible_binary_by_lowering_its_version(self, _):
        with self.assertRaisesRegex(ValueError, 'app declares 15.5'):
            validate(self.app, repair_onnx=True)
        self.assertEqual(plistlib.loads((self.framework / 'Info.plist').read_bytes())['MinimumOSVersion'], '15.1')

    @patch('validate_frameworks.minimum_os', return_value='15.5')
    def test_does_not_modify_unrelated_frameworks(self, _):
        self.framework.rename(self.framework.with_name('Other.framework'))
        with self.assertRaisesRegex(ValueError, 'Other.framework'):
            validate(self.app, repair_onnx=True)


if __name__ == '__main__':
    unittest.main()
