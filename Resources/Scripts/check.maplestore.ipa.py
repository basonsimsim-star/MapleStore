#!/usr/bin/env python3
"""Verify an unsigned MapleStore device archive before uploading it."""
import plistlib
import re
import sys
import zipfile
from pathlib import PurePosixPath


def check(archive):
    with zipfile.ZipFile(archive) as package:
        if package.testzip() is not None:
            raise ValueError('Corrupt ZIP member')
        names = package.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate ZIP member')
        app_roots = set()
        for name in names:
            path = PurePosixPath(name)
            if path.is_absolute() or '..' in path.parts or '\\' in name:
                raise ValueError('Unsafe archive path')
            if len(path.parts) > 1 and path.parts[0] == 'Payload' and path.parts[1].endswith('.app'):
                app_roots.add('/'.join(path.parts[:2]))
            if path.suffix.lower() in {'.p12', '.p8', '.mobileprovision', '.provisionprofile'}:
                raise ValueError('Unsigned build contains signing assets')
            if path.name in {'Developer.xcconfig', 'rootCA-key.pem'}:
                raise ValueError('Archive contains private build configuration')
        if app_roots != {'Payload/Asspp.app'}:
            raise ValueError('Expected exactly one device application')
        info = plistlib.loads(package.read('Payload/Asspp.app/Info.plist'))
        if info.get('CFBundleIdentifier') != 'app.maplestore.client':
            raise ValueError('Unexpected bundle identifier')
        if info.get('CFBundleDisplayName') != 'MapleStore':
            raise ValueError('Unexpected display name')
        if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError('Expected an iOS device build, not a simulator build')
        executable = info.get('CFBundleExecutable', '')
        if not executable or '/' in executable or '\\' in executable or executable in {'.', '..'}:
            raise ValueError('Invalid executable name')
        binary = package.read('Payload/Asspp.app/' + executable)
        if binary[:4] not in {b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf', b'\xca\xfe\xba\xbe', b'\xbe\xba\xfe\xca'}:
            raise ValueError('Missing Mach-O device executable')
        for name in names:
            if not name.endswith('/') and re.search(rb'/Users/(?!runner(?:admin)?/|Shared/)[A-Za-z0-9._-]+/', package.read(name)):
                raise ValueError('Archive contains a personal home directory path')
    print('MapleStore IPA structure and build metadata verified; installation is not tested.')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('Usage: check.maplestore.ipa.py PATH.ipa')
    check(sys.argv[1])
