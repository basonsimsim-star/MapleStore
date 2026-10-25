"""Regression checks for artifacts that can look valid but cannot be installed."""
import importlib.util
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path

script = Path(__file__).resolve().parents[1] / 'Resources/Scripts/check.maplestore.ipa.py'
spec = importlib.util.spec_from_file_location('ipa_check', script)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class PackageTests(unittest.TestCase):
    def package(self, root, platform='iPhoneOS', executable=True, extra=None):
        path = Path(root) / 'fixture.ipa'
        info = {'CFBundleIdentifier': 'app.maplestore.client', 'CFBundleDisplayName': 'MapleStore',
                'CFBundleSupportedPlatforms': [platform], 'CFBundleExecutable': 'Asspp'}
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('Payload/Asspp.app/Info.plist', plistlib.dumps(info))
            if executable:
                archive.writestr('Payload/Asspp.app/Asspp', b'\xcf\xfa\xed\xfe' + bytes(32))
            if extra:
                archive.writestr(*extra)
        return path

    def test_device_archive_structure(self):
        with tempfile.TemporaryDirectory() as root:
            validator.check(self.package(root))

    def test_simulator_archive_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaisesRegex(ValueError, 'device build'):
                validator.check(self.package(root, platform='iPhoneSimulator'))

    def test_missing_executable_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaises(KeyError):
                validator.check(self.package(root, executable=False))

    def test_accidental_signing_assets_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaisesRegex(ValueError, 'signing assets'):
                validator.check(self.package(root, extra=('Payload/Asspp.app/embedded.mobileprovision', b'private')))

    def test_personal_build_paths_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaisesRegex(ValueError, 'personal home'):
                validator.check(self.package(root, extra=('Payload/Asspp.app/debug.txt', b'/Users/developer/project')))

    def test_unsafe_archive_path_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaisesRegex(ValueError, 'Unsafe'):
                validator.check(self.package(root, extra=('../outside', b'data')))


if __name__ == '__main__':
    unittest.main()
