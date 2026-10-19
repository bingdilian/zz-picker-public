#!/usr/bin/env python3
"""Run native controller/panel regressions on an ephemeral iOS simulator."""
import json
import shutil
from pathlib import Path
import plistlib
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build' / 'ui-tests'
BUNDLE = 'local.zzpicker.uitests'

def call(*args):
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()

def main():
    BUILD.mkdir(parents=True, exist_ok=True)
    sdk = call('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path')
    runtimes = [r['identifier'] for r in json.loads(call('xcrun', 'simctl', 'list', 'runtimes', '-j'))['runtimes'] if r.get('isAvailable') and '.iOS-' in r['identifier']]
    if not runtimes:
        raise SystemExit('An installed iOS simulator runtime is required')
    app = BUILD / 'ZZPickerUITests.app'
    app.mkdir(exist_ok=True)
    info = {'CFBundleIdentifier': BUNDLE, 'CFBundleName': 'ZZPicker UI Tests', 'CFBundleExecutable': 'ZZPickerUITests', 'CFBundlePackageType': 'APPL', 'CFBundleVersion': '1', 'CFBundleShortVersionString': '1.0', 'MinimumOSVersion': '15.0', 'UIDeviceFamily': [1], 'UILaunchScreen': {}, 'UIApplicationSceneManifest': {'UIApplicationSupportsMultipleScenes': False, 'UISceneConfigurations': {'UIWindowSceneSessionRoleApplication': [{'UISceneConfigurationName': 'Tests', 'UISceneDelegateClassName': 'TestScene'}]}}}
    (app / 'Info.plist').write_bytes(plistlib.dumps(info))
    subprocess.run(['xcrun', '--sdk', 'iphonesimulator', 'clang', '-target', 'arm64-apple-ios15.0-simulator', '-isysroot', sdk, '-fobjc-arc', '-fmodules', '-Wall', '-Wextra', '-Werror', '-Ibuild', '-Isrc', '-framework', 'Foundation', '-framework', 'UIKit', '-framework', 'WebKit', '-framework', 'JavaScriptCore', 'tests/ui.m', *[str(p) for p in sorted((ROOT / 'src').glob('*.m'))], '-o', str(app / 'ZZPickerUITests')], cwd=ROOT, check=True)
    subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True, capture_output=True)
    device = call('xcrun', 'simctl', 'create', 'ZZPicker UI Tests', 'com.apple.CoreSimulator.SimDeviceType.iPhone-13-Pro-Max', runtimes[-1])
    try:
        call('xcrun', 'simctl', 'boot', device)
        with (BUILD / 'boot.log').open('w') as log:
            subprocess.run(['xcrun', 'simctl', 'bootstatus', device, '-b'], check=True, stdout=log, stderr=log)
        call('xcrun', 'simctl', 'install', device, str(app))
        call('xcrun', 'simctl', 'launch', device, BUNDLE)
        container = Path(call('xcrun', 'simctl', 'get_app_container', device, BUNDLE, 'data'))
        result = container / 'Documents' / 'ui-result.json'
        deadline = time.monotonic() + 30
        while not result.exists() and time.monotonic() < deadline:
            time.sleep(0.2)
        if not result.exists():
            raise RuntimeError('Native UI tests did not produce a result')
        for screenshot in (container / 'Documents').glob('ui-*.png'):
            shutil.copyfile(screenshot, BUILD / screenshot.name)
        data = json.loads(result.read_text())
        (BUILD / 'result.json').write_text(json.dumps(data, ensure_ascii=False, indent=2))
        print(json.dumps(data, ensure_ascii=False))
        if data['failures']:
            raise SystemExit(1)
    finally:
        subprocess.run(['xcrun', 'simctl', 'shutdown', device], capture_output=True)
        subprocess.run(['xcrun', 'simctl', 'delete', device], capture_output=True)

if __name__ == '__main__':
    main()
