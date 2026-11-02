import io
import plistlib
from pathlib import Path
import subprocess
import struct
import tarfile
import unittest
import zipfile
import importlib.util
import tempfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('package_output', ROOT / 'scripts/build.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
DIST = builder.output_dir()

def ar_members(path):
    data = path.read_bytes()
    if not data.startswith(b'!<arch>\n'):
        raise ValueError('Not a Debian ar archive')
    result = {}
    offset = 8
    while offset < len(data):
        header = data[offset:offset + 60]
        if len(header) != 60 or header[58:] != b'`\n':
            raise ValueError('Invalid ar member header')
        name = header[:16].decode().strip().rstrip('/')
        size = int(header[48:58])
        result[name] = data[offset + 60:offset + 60 + size]
        offset += 60 + size + size % 2
    if offset != len(data):
        raise ValueError('Truncated archive')
    return result

class Packages(unittest.TestCase):
    def test_candidate_version_agrees_with_native_header(self):
        self.assertEqual(builder.VERSION, '2.0.0-alpha1')
        self.assertIn('@"' + builder.VERSION + '"', (ROOT / 'src/ZZPicker.h').read_text())

    def test_all_variants_embed_identical_complete_rules_and_modules(self):
        bundle = builder.core_bundle()
        self.assertIn((ROOT / 'src/config.js').read_bytes(), bundle)
        self.assertIn((ROOT / 'src/compatibility.js').read_bytes(), bundle)
        binaries = {'trollfools': (DIST / f'ZZPicker-{builder.VERSION}-trollfools.dylib').read_bytes()}
        for variant, prefix in [('rootless', 'var/jb/'), ('roothide', '')]:
            members = ar_members(DIST / f'ZZPicker-{builder.VERSION}-{variant}.deb')
            with tarfile.open(fileobj=io.BytesIO(members['data.tar.gz'])) as archive:
                binaries[variant] = archive.extractfile(prefix + 'Library/MobileSubstrate/DynamicLibraries/ZZPicker.dylib').read()
        for variant, binary in binaries.items():
            with self.subTest(variant=variant):
                self.assertIn(bundle, binary, 'Device package needs the whole rule bundle without sidecar files')
                with tempfile.NamedTemporaryFile(suffix='.dylib') as candidate:
                    candidate.write(binary)
                    candidate.flush()
                    subprocess.run(['codesign', '--verify', '--strict', candidate.name], check=True, capture_output=True)

    def test_debs_have_separate_layout_architecture_and_only_target_app(self):
        for variant, arch, prefix in [('rootless', 'iphoneos-arm64', 'var/jb/'), ('roothide', 'iphoneos-arm64e', '')]:
            with self.subTest(variant=variant):
                path = DIST / f'ZZPicker-{builder.VERSION}-{variant}.deb'
                self.assertTrue(path.exists(), 'Package not built: ' + path.name)
                members = ar_members(path)
                self.assertEqual(members['debian-binary'], b'2.0\n')
                with tarfile.open(fileobj=io.BytesIO(members['control.tar.gz'])) as t:
                    control = t.extractfile('control').read().decode()
                self.assertIn('Architecture: ' + arch + '\n', control)
                self.assertIn('Version: ' + builder.VERSION.replace('-', '~', 1) + '\n', control)
                with tarfile.open(fileobj=io.BytesIO(members['data.tar.gz'])) as t:
                    folder = prefix + 'Library/MobileSubstrate/DynamicLibraries/'
                    self.assertEqual(set(t.getnames()), {folder + 'ZZPicker.dylib', folder + 'ZZPicker.plist'})
                    self.assertEqual(t.getmember(folder + 'ZZPicker.dylib').mode, 0o755)
                    filt = plistlib.loads(t.extractfile(folder + 'ZZPicker.plist').read())
                    self.assertEqual(filt, {'Filter': {'Bundles': ['com.wuba.zhuanzhuan']}})
                    for entry in t:
                        self.assertTrue(entry.isfile())
                        self.assertNotIn('..', Path(entry.name).parts)
    def test_trollfools_zip_contains_self_contained_library(self):
        path = DIST / f'ZZPicker-{builder.VERSION}-trollfools.zip'
        self.assertTrue(path.exists(), 'TrollFools package not built')
        with zipfile.ZipFile(path) as z:
            self.assertEqual(z.namelist(), ['ZZPicker.dylib'])
            self.assertEqual(z.read('ZZPicker.dylib'), (DIST / f'ZZPicker-{builder.VERSION}-trollfools.dylib').read_bytes())
    def test_macho_is_ios_arm64_and_only_links_system_libraries(self):
        path = DIST / f'ZZPicker-{builder.VERSION}-trollfools.dylib'
        self.assertTrue(path.exists(), 'Library not built')
        arch = subprocess.check_output(['xcrun', 'lipo', '-archs', str(path)], text=True).strip()
        self.assertEqual(arch, 'arm64')
        deps = subprocess.check_output(['xcrun', 'otool', '-L', str(path)], text=True).splitlines()[2:]
        for dep in deps:
            self.assertTrue(dep.strip().startswith(('/System/Library/', '/usr/lib/')), dep)
        binary = path.read_bytes()
        self.assertEqual(struct.unpack_from('<I', binary)[0], 0xFEEDFACF)
        offset = 32
        build_version = None
        for _ in range(struct.unpack_from('<I', binary, 16)[0]):
            command, size = struct.unpack_from('<II', binary, offset)
            if command == 0x32:
                build_version = struct.unpack_from('<II', binary, offset + 8)
            offset += size
        self.assertEqual(build_version, (2, 15 << 16))  # PLATFORM_IOS, minimum 15.0
        subprocess.run(['codesign', '--verify', '--strict', str(path)], check=True, capture_output=True)

    def test_source_archive_matches_project_and_excludes_capture_secrets(self):
        with zipfile.ZipFile(DIST / f'ZZPicker-{builder.VERSION}-source.zip') as z:
            self.assertEqual(z.read('zz-picker/LICENSE'), (ROOT / 'LICENSE').read_bytes())
            self.assertTrue(all(n.startswith('zz-picker/') for n in z.namelist()))
            for path in sorted((ROOT / 'src').glob('*')):
                if path.is_file():
                    self.assertEqual(z.read('zz-picker/src/' + path.name), path.read_bytes())
            for name in ['compatibility.test.cjs', 'config.test.cjs', 'fixtures/compatibility-cases.json', 'configuration.m']:
                self.assertEqual(z.read('zz-picker/tests/' + name), (ROOT / 'tests' / name).read_bytes())
            self.assertFalse(any(p in {'build', 'dist', '.git', '__pycache__', '.DS_Store'} for n in z.namelist() for p in Path(n).parts[1:]))
            self.assertFalse(any(n.startswith('zz-picker/docs/') and not n.startswith('zz-picker/docs/public/') for n in z.namelist()))
            for name in z.namelist():
                self.assertNotIn(b'/Users/' + b'weihaishenlan/', z.read(name), name)

    def test_source_root_does_not_depend_on_checkout_directory_name(self):
        spec = importlib.util.spec_from_file_location('package_builder', ROOT / 'scripts/build.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        with tempfile.TemporaryDirectory() as folder:
            checkout = Path(folder) / 'renamed-checkout'
            checkout.mkdir()
            (checkout / 'README.md').write_text('public source')
            builder.ROOT = checkout
            builder.DIST = checkout / 'dist'
            builder.DIST.mkdir()
            builder.source_archive()
            with zipfile.ZipFile(builder.DIST / f'ZZPicker-{builder.VERSION}-source.zip') as z:
                self.assertEqual(z.namelist(), ['zz-picker/README.md'])
    def test_manifest_matches_every_delivery(self):
        import hashlib
        for line in (DIST / 'SHA256SUMS').read_text().splitlines():
            digest, filename = line.split('  ', 1)
            self.assertEqual(hashlib.sha256((DIST / filename).read_bytes()).hexdigest(), digest)

    def test_release_bundle_is_complete_and_independently_checkable(self):
        import hashlib
        release = DIST / f'ZZPicker-{builder.VERSION}-release.zip'
        digest, filename = (DIST / (release.name + '.sha256')).read_text().strip().split('  ', 1)
        self.assertEqual(filename, release.name)
        self.assertEqual(hashlib.sha256(release.read_bytes()).hexdigest(), digest)
        with zipfile.ZipFile(release) as z:
            names = set(z.namelist())
            self.assertEqual(z.read('LICENSE'), (ROOT / 'LICENSE').read_bytes())
            self.assertEqual(z.read('development.md'), (ROOT / 'docs/public/development.md').read_bytes())
            manifest = z.read('SHA256SUMS').decode().splitlines()
            self.assertEqual(names, {'SHA256SUMS'} | {line.split('  ', 1)[1] for line in manifest})
            for line in manifest:
                expected, name = line.split('  ', 1)
                self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), expected)
                self.assertFalse(Path(name).is_absolute())
                self.assertNotIn('..', Path(name).parts)
                self.assertNotIn('test6', name)
            for name in ['install.md', 'compatibility.md', 'feedback.md', 'CHANGELOG.md', 'forum-post.md']:
                self.assertIn(name, names)
                self.assertEqual(z.read(name), (ROOT / 'docs/public' / name).read_bytes())

if __name__ == '__main__':
    unittest.main(verbosity=2)
