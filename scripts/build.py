#!/usr/bin/env python3
"""Build self-contained iOS libraries and Debian archives with Xcode + Python."""
from pathlib import Path
import gzip
import hashlib
import io
import json
import plistlib
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
DIST = ROOT / 'dist'
VERSION = '1.2.0-beta16'

def run(args):
    subprocess.run(args, cwd=ROOT, check=True)

def tar_gz(files):
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode='w', format=tarfile.USTAR_FORMAT) as archive:
        for name, data, mode in files:
            info = tarfile.TarInfo(name)
            info.size, info.mode, info.mtime = len(data), mode, 0
            info.uid = info.gid = 0
            info.uname = info.gname = 'root'
            archive.addfile(info, io.BytesIO(data))
    return gzip.compress(stream.getvalue(), mtime=0)

def ar(files):
    out = bytearray(b'!<arch>\n')
    for name, data in files:
        header = f'{name + "/":<16}{0:<12}{0:<6}{0:<6}{"100644":<8}{len(data):<10}`\n'.encode('ascii')
        if len(header) != 60:
            raise ValueError('Invalid ar header')
        out.extend(header)
        out.extend(data)
        if len(data) % 2:
            out.extend(b'\n')
    return bytes(out)

def embed():
    lines = []
    for label, name in [('ZZCore', 'core.js'), ('ZZWeb', 'web.js')]:
        data = (ROOT / 'src' / name).read_bytes()
        lines.append(f'static const unsigned char {label}Bytes[] = {{' + ','.join(map(str, data)) + '};')
        lines.append(f'static const unsigned long {label}Length = {len(data)};')
    (BUILD / 'Embedded.h').write_text('\n'.join(lines) + '\n')

def library(variant, sdk):
    output = BUILD / f'ZZPicker-{variant}.dylib'
    run(['xcrun', '--sdk', 'iphoneos', 'clang', '-arch', 'arm64', '-isysroot', sdk,
         '-miphoneos-version-min=15.0', '-fobjc-arc', '-fmodules', '-fvisibility=hidden',
         '-Wall', '-Wextra', '-Werror', '-Os', '-dynamiclib',
         '-I' + str(BUILD), '-I' + str(ROOT / 'src'), f'-DZZ_VARIANT="{variant}"',
         '-framework', 'Foundation', '-framework', 'UIKit', '-framework', 'WebKit',
         '-framework', 'JavaScriptCore', '-install_name', '@rpath/ZZPicker.dylib',
         *[str(p) for p in sorted((ROOT / 'src').glob('*.m'))], '-o', str(output)])
    run(['codesign', '--force', '--sign', '-', '--timestamp=none', '--identifier',
         'com.codex.zzpicker.' + variant, str(output)])
    run(['codesign', '--verify', '--strict', str(output)])
    return output

def deb(variant, dylib):
    arch, prefix = ('iphoneos-arm64', 'var/jb/') if variant == 'rootless' else ('iphoneos-arm64e', '')
    binary = dylib.read_bytes()
    control = ('Package: com.codex.zzpicker\n'
               'Name: 转转选机助手\n'
               'Version: 1.2.0~beta16\n'
               f'Architecture: {arch}\n'
               'Maintainer: Local Developer\n'
               'Section: Tweaks\n'
               'Depends: firmware (>= 15.0)\n'
               f'Installed-Size: {(len(binary) + 1023) // 1024}\n'
               'Description: Foreground product filtering and optional favorites in Zhuanzhuan.\n').encode()
    filt = plistlib.dumps({'Filter': {'Bundles': ['com.wuba.zhuanzhuan']}}, fmt=plistlib.FMT_XML)
    folder = prefix + 'Library/MobileSubstrate/DynamicLibraries/'
    payload = tar_gz([(folder + 'ZZPicker.dylib', binary, 0o755), (folder + 'ZZPicker.plist', filt, 0o644)])
    archive = ar([('debian-binary', b'2.0\n'), ('control.tar.gz', tar_gz([('control', control, 0o644)])), ('data.tar.gz', payload)])
    (DIST / f'ZZPicker-{VERSION}-{variant}.deb').write_bytes(archive)

def source_archive():
    with zipfile.ZipFile(DIST / f'ZZPicker-{VERSION}-source.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for path in sorted(ROOT.rglob('*')):
            relative = path.relative_to(ROOT)
            if not path.is_file() or any(p in {'build', 'dist', '__pycache__', '.git', '.DS_Store'} for p in relative.parts):
                continue
            if not (relative.parts[0] in {'src', 'scripts', 'tests'} or relative.parts[:2] == ('docs', 'public') or relative.as_posix() in {'README.md', 'Makefile', '.gitignore', 'LICENSE'}):
                continue
            z.write(path, 'zz-picker/' + relative.as_posix())

def manifest():
    hashes = []
    for p in release_files():
        hashes.append(hashlib.sha256(p.read_bytes()).hexdigest() + '  ' + p.relative_to(DIST).as_posix())
    (DIST / 'SHA256SUMS').write_text('\n'.join(hashes) + '\n')

def release_files():
    names = [f'ZZPicker-{VERSION}-{suffix}' for suffix in
             ['trollfools.dylib', 'trollfools.zip', 'rootless.deb', 'roothide.deb', 'source.zip']]
    names += ['LICENSE', 'README.md', 'install.md', 'compatibility.md', 'feedback.md', 'CHANGELOG.md', 'forum-post.md', 'development.md']
    names += ['images/' + p.name for p in sorted((ROOT / 'docs/public/images').glob('*')) if p.is_file()]
    return [DIST / name for name in sorted(names)]

def release_bundle():
    for source in [ROOT / 'LICENSE', ROOT / 'README.md', *sorted((ROOT / 'docs' / 'public').glob('*.md'))]:
        text = source.read_text()
        if source.name == 'README.md':
            text = text.replace('docs/public/', '')
        (DIST / source.name).write_text(text)
    for image in sorted((ROOT / 'docs/public/images').glob('*')):
        if image.is_file():
            target = DIST / 'images' / image.name
            target.parent.mkdir(exist_ok=True)
            target.write_bytes(image.read_bytes())
    manifest()
    release = DIST / f'ZZPicker-{VERSION}-release.zip'
    with zipfile.ZipFile(release, 'w', zipfile.ZIP_DEFLATED) as z:
        for path in [*release_files(), DIST / 'SHA256SUMS']:
            z.write(path, path.relative_to(DIST).as_posix())
    (DIST / (release.name + '.sha256')).write_text(hashlib.sha256(release.read_bytes()).hexdigest() + '  ' + release.name + '\n')

def main():
    BUILD.mkdir(exist_ok=True)
    DIST.mkdir(exist_ok=True)
    embed()
    sdk = subprocess.check_output(['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'], text=True).strip()
    for variant in ['rootless', 'roothide', 'trollfools']:
        print('Building ' + variant, flush=True)
        path = library(variant, sdk)
        if variant in ['rootless', 'roothide']:
            deb(variant, path)
        else:
            (DIST / f'ZZPicker-{VERSION}-trollfools.dylib').write_bytes(path.read_bytes())
            with zipfile.ZipFile(DIST / f'ZZPicker-{VERSION}-trollfools.zip', 'w', zipfile.ZIP_DEFLATED) as z:
                z.write(path, 'ZZPicker.dylib')
    source_archive()
    release_bundle()
    print('Artifacts: ' + str(DIST))

if __name__ == '__main__':
    main()
