import hashlib
import importlib.util
import os
import json
import re
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class BuildOutput(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name).resolve() / 'checkout'
        for name in ['scripts', 'src', 'tests', 'docs/public', 'dist']:
            (self.root / name).mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / 'scripts/build.py', self.root / 'scripts/build.py')
        shutil.copyfile(ROOT / 'tests/test_packages.py', self.root / 'tests/test_packages.py')
        (self.root / 'README.md').write_text('Public readme')
        shutil.copyfile(ROOT / 'LICENSE', self.root / 'LICENSE')
        for name in ['install', 'compatibility', 'feedback', 'CHANGELOG', 'forum-post', 'development']:
            (self.root / f'docs/public/{name}.md').write_text('Public instructions')
        for name in ['core.js', 'web.js']:
            (self.root / 'src' / name).write_text('/* fixture */')
        for name in ['compatibility.js', 'compatibility-rules.json', 'config.js']:
            if (ROOT / 'src' / name).exists():
                shutil.copyfile(ROOT / 'src' / name, self.root / 'src' / name)
        self.output = Path(self.folder.name).resolve() / 'deliveries'
        self.fake_library = Path(self.folder.name) / 'stub.dylib'
        self.fake_library.write_bytes(b'library fixture')

    def load_module(self, relative):
        spec = importlib.util.spec_from_file_location('output_fixture', self.root / relative)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def build_without_compiler(self, builder):
        # Archive writes stay real; only the native compiler/SDK boundary is replaced.
        with mock.patch.object(builder, 'library', return_value=self.fake_library), \
                mock.patch.object(builder.subprocess, 'check_output', return_value='/sdk'):
            builder.main()

    def test_output_dir_is_explicit(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': str(self.output)}):
            builder = self.load_module('scripts/build.py')
        self.build_without_compiler(builder)
        package = self.output / f'ZZPicker-{builder.VERSION}-source.zip'
        self.assertTrue(package.is_file(), 'Explicit output directory was ignored')
        self.assertEqual(list((self.root / 'dist').iterdir()), [])
        with zipfile.ZipFile(package) as archive:
            self.assertEqual(archive.read('zz-picker/README.md'), b'Public readme')

    def test_relative_output_dir_is_project_relative(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': 'artifacts/nested'}):
            builder = self.load_module('scripts/build.py')
        self.build_without_compiler(builder)
        self.assertTrue((self.root / f'artifacts/nested/ZZPicker-{builder.VERSION}-source.zip').is_file())
        self.assertEqual(list((self.root / 'dist').iterdir()), [])

    def test_output_dir_defaults_to_dist(self):
        with mock.patch.dict(os.environ):
            os.environ.pop('ZZ_PICKER_OUTPUT_DIR', None)
            builder = self.load_module('scripts/build.py')
        self.build_without_compiler(builder)
        self.assertTrue((self.root / f'dist/ZZPicker-{builder.VERSION}-source.zip').is_file())

    def test_empty_output_dir_is_rejected(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': '  '}):
            with self.assertRaises(ValueError):
                self.load_module('scripts/build.py')

    def test_existing_version_is_not_overwritten(self):
        names = ['rootless.deb', 'roothide.deb', 'trollfools.dylib', 'trollfools.zip',
                 'source.zip', 'release.zip', 'release.zip.sha256']
        with mock.patch.dict(os.environ):
            os.environ.pop('ZZ_PICKER_OUTPUT_DIR', None)
            builder = self.load_module('scripts/build.py')
        for suffix in names:
            with self.subTest(suffix=suffix), tempfile.TemporaryDirectory() as folder:
                builder.DIST = Path(folder)
                sentinel = builder.DIST / f'ZZPicker-{builder.VERSION}-{suffix}'
                sentinel.write_bytes(b'existing delivery')
                before = hashlib.sha256(sentinel.read_bytes()).hexdigest()
                (self.root / 'build').mkdir(exist_ok=True)
                embedded = self.root / 'build/Embedded.h'
                embedded.write_bytes(b'existing embedded header')
                error = None
                try:
                    self.build_without_compiler(builder)
                except FileExistsError as caught:
                    error = caught
                self.assertIsNotNone(error, 'Existing candidate must stop the build')
                self.assertEqual(hashlib.sha256(sentinel.read_bytes()).hexdigest(), before)
                self.assertEqual(embedded.read_bytes(), b'existing embedded header')
                self.assertEqual(set(builder.DIST.iterdir()), {sentinel})

    def test_shared_release_files_are_not_overwritten(self):
        with mock.patch.dict(os.environ):
            os.environ.pop('ZZ_PICKER_OUTPUT_DIR', None)
            builder = self.load_module('scripts/build.py')
        for name in ['README.md', 'SHA256SUMS']:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as folder:
                builder.DIST = Path(folder)
                sentinel = builder.DIST / name
                sentinel.write_bytes(b'older release metadata')
                error = None
                try:
                    self.build_without_compiler(builder)
                except FileExistsError as caught:
                    error = caught
                self.assertIsNotNone(error, 'Shared metadata must not be overwritten')
                self.assertEqual(sentinel.read_bytes(), b'older release metadata')
                self.assertEqual(set(builder.DIST.iterdir()), {sentinel})

    def test_other_version_files_are_preserved(self):
        with mock.patch.dict(os.environ):
            os.environ.pop('ZZ_PICKER_OUTPUT_DIR', None)
            builder = self.load_module('scripts/build.py')
        sentinel = self.root / 'dist/ZZPicker-0.9.0-rootless.deb'
        sentinel.write_bytes(b'older package')
        self.build_without_compiler(builder)
        self.assertEqual(sentinel.read_bytes(), b'older package')
        self.assertTrue((self.root / f'dist/ZZPicker-{builder.VERSION}-rootless.deb').is_file())

    def test_custom_output_inside_sources_is_not_archived(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': 'src/candidates'}):
            builder = self.load_module('scripts/build.py')
        builder.DIST.mkdir(parents=True, exist_ok=True)
        (builder.DIST / 'old.dylib').write_bytes(b'not source')
        builder.source_archive()
        with zipfile.ZipFile(builder.DIST / f'ZZPicker-{builder.VERSION}-source.zip') as archive:
            self.assertIn('zz-picker/src/core.js', archive.namelist())
            self.assertFalse(any(n.startswith('zz-picker/src/candidates/') for n in archive.namelist()))

    def test_output_above_checkout_keeps_sources(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': str(self.root.parent)}):
            builder = self.load_module('scripts/build.py')
        self.build_without_compiler(builder)
        with zipfile.ZipFile(self.root.parent / f'ZZPicker-{builder.VERSION}-source.zip') as archive:
            self.assertEqual(archive.read('zz-picker/src/core.js'), b'/* fixture */')

    def test_package_checks_use_same_output_directory(self):
        with mock.patch.dict(os.environ, {'ZZ_PICKER_OUTPUT_DIR': 'artifacts/packages'}):
            checks = self.load_module('tests/test_packages.py')
        self.assertEqual(checks.DIST, self.root / 'artifacts/packages')

    def test_embedded_rules_match_source(self):
        builder = self.load_module('scripts/build.py')
        self.assertTrue(hasattr(builder, 'core_bundle'), 'Bundled rule source is missing')
        builder.BUILD.mkdir()
        builder.embed()
        header = (builder.BUILD / 'Embedded.h').read_text()
        match = re.search(r'ZZCoreBytes\[\] = \{([^}]*)\}', header)
        data = bytes(map(int, match.group(1).split(',')))
        self.assertEqual(data, builder.core_bundle())
        text = data.decode()
        declaration = text.split(' = ', 1)[1].split(';\n', 1)[0]
        self.assertEqual(json.loads(declaration), json.loads((ROOT / 'src/compatibility-rules.json').read_text()))
        self.assertIn((ROOT / 'src/compatibility.js').read_text(), text)
        self.assertTrue(text.endswith((self.root / 'src/core.js').read_text()))


if __name__ == '__main__':
    unittest.main(verbosity=2)
