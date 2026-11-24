#!/usr/bin/python3
"""Render or open the separate Sportray visual prototype with illustrative data.

python3 tools/preview-ui.py /tmp/sportray-direction --logo-cache /path/to/logos.json
python3 tools/preview-ui.py --live --theme catppuccin
Never loads the installed plugin, requests sports data, or saves preferences.
"""
import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parent.parent
SHELL = Path('/usr/share/omarchy/shell')


def stage(base, output, args, width, font_size, theme, live=False):
    config = base / 'config'
    config.mkdir(parents=True)
    home, runtime, imports = base / 'home', base / 'runtime', base / 'imports/qs'
    home.mkdir(mode=0o700)
    runtime.mkdir(mode=0o700)
    imports.mkdir(parents=True)
    for name in ('Commons', 'Ui', 'services'):
        (imports / name).symlink_to(SHELL / name, target_is_directory=True)
        (config / name).symlink_to(SHELL / name, target_is_directory=True)
    data = config / 'tools/designreview'
    data.mkdir(parents=True)
    for path in (ROOT / 'tools/designreview').glob('*.qml'):
        shutil.copy2(path, data / path.name)
        assert path.read_bytes() == (data / path.name).read_bytes()
    (config / 'model').mkdir()
    shutil.copy2(ROOT / 'model/UiContrast.js', config / 'model/UiContrast.js')
    (config / 'shell.qml').write_text('import "tools/designreview" as Review\nReview.ReviewShell {}\n')
    sample = json.loads((ROOT / 'tools/readme/sample-state.json').read_text())
    # Four illustrative matchups exercise one feature and three compact rows.
    sample['games'] = sample['games'][:4]
    (data / 'sample-state.json').write_text(json.dumps(sample))
    (data / 'review.json').write_text(json.dumps({'capture': not live, 'width': width, 'fontSize': font_size}))
    shutil.copy2(args.logo_cache, data / 'logos.json')
    env = dict(os.environ)
    native_socket = env.get('WAYLAND_DISPLAY', '')
    if native_socket and not native_socket.startswith('/'):
        native_socket = str(Path(env.get('XDG_RUNTIME_DIR', '/run/user/' + str(os.getuid()))) / native_socket)
    env.update({'HOME': str(home), 'XDG_CONFIG_HOME': str(home / '.config'),
                'XDG_STATE_HOME': str(home / '.local/state'), 'XDG_CACHE_HOME': str(home / '.cache'),
                'XDG_DATA_HOME': str(home / '.local/share'), 'XDG_RUNTIME_DIR': str(runtime),
                'QML_IMPORT_PATH': str(imports.parent), 'QML_XHR_ALLOW_FILE_READ': '1',
                'QT_QPA_PLATFORMTHEME': '', 'QT_QUICK_CONTROLS_STYLE': 'Basic',
                'QS_DISABLE_FILE_WATCHER': '1', 'TZ': 'America/New_York',
                'SPORTRAY_REVIEW_OUTPUT': str(output)})
    for key in ('DISPLAY', 'WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE', 'DBUS_SESSION_BUS_ADDRESS', 'QS_CONFIG_NAME', 'QS_MANIFEST'):
        env.pop(key, None)
    if live:
        if not native_socket:
            raise RuntimeError('Live preview requires an active Wayland session')
        env.update({'QT_QPA_PLATFORM': 'wayland', 'WAYLAND_DISPLAY': native_socket})
    else:
        env.update({'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software'})
    theme_dir = data / 'theme'
    theme_dir.mkdir()
    shutil.copy2(SHELL.parent / 'themes' / theme / 'colors.toml', theme_dir / 'colors.toml')
    templates = base / 'templates'
    templates.mkdir()
    shutil.copy2(SHELL.parent / 'default/themed/shell.toml.tpl', templates / 'shell.toml.tpl')
    lines = (SHELL.parent / 'bin/omarchy-theme-set-templates').read_text().splitlines()
    for prefix, value in {'TEMPLATES_DIR=': templates, 'USER_TEMPLATES_DIR=': base / 'none', 'NEXT_THEME_DIR=': theme_dir}.items():
        assert sum(line.startswith(prefix) for line in lines) == 1
        lines = [prefix + '"' + str(value) + '"' if line.startswith(prefix) else line for line in lines]
    renderer = base / 'theme.sh'
    renderer.write_text('\n'.join(lines) + '\n')
    subprocess.run(['/bin/bash', str(renderer)], env=env, check=True, capture_output=True, timeout=15)
    return config, env


def validate_log(log):
    for error in ('DESIGN_PREVIEW_FAIL', 'TypeError:', 'ReferenceError:', 'Binding loop detected', 'Error loading configuration', 'Unable to assign'):
        if error in log:
            raise RuntimeError(log)


def assets(args, base):
    urls = json.loads((ROOT / 'tools/readme/sample-state.json').read_text())['logoUrls']
    if args.logo_cache:
        raw = args.logo_cache.read_bytes()
        if len(raw) > 8 * 1024 * 1024:
            raise ValueError('Logo cache exceeds the bounded capture limit')
        logos = json.loads(raw)
    else:
        logos = {}
        for url in urls:
            value = subprocess.check_output(['/usr/bin/python3', '-I', '-S', str(ROOT / 'scripts/logo-image-helper.py'), url], timeout=15).decode().strip()
            logos[url] = value
    policy = runpy.run_path(str(ROOT / 'scripts/logo-image-helper.py'))
    assert set(logos) == set(urls)
    for url, value in logos.items():
        policy['validate_url'](url)
        assert isinstance(value, str) and len(value) <= 350000
        match = re.fullmatch(r'data:(image/(?:png|jpeg|webp));base64,([A-Za-z0-9+/=]+)', value)
        assert match
        raster = base64.b64decode(match[2], validate=True)
        assert len(raster) <= policy['MAX_BYTES']
        assert policy['validate_image'](raster) == match[1]
    args.logo_cache = base / 'logos.json'
    args.logo_cache.write_text(json.dumps(logos))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', nargs='?', type=Path, default=Path('/tmp/sportray-direction'))
    parser.add_argument('--logo-cache', type=Path)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--theme', choices=('catppuccin-latte', 'catppuccin'), default='catppuccin-latte')
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    # A live preview keeps this private staging directory for its lifetime.
    base = Path(tempfile.mkdtemp(prefix='spr-ui-'))
    assets(args, base)
    if args.live:
        config, env = stage(base / 'live', output, args, 420, 12, args.theme, live=True)
        log_path = base / 'live.log'
        with log_path.open('wb') as log:
            process = subprocess.Popen(['/usr/bin/quickshell', '-n', '--no-color', '-p', str(config)], env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        for _ in range(50):
            transcript = log_path.read_text(errors='replace')
            validate_log(transcript)
            if 'DESIGN_PREVIEW_READY' in transcript:
                break
            if process.poll() is not None:
                raise RuntimeError('Preview exited before becoming ready:\n' + transcript)
            time.sleep(.1)
        else:
            process.terminate()
            raise RuntimeError('Preview did not become ready:\n' + transcript)
        print(json.dumps({'pid': process.pid, 'config': str(config), 'log': str(log_path)}))
        return
    cases = [('light', 420, 12, 'catppuccin-latte'), ('dark', 420, 12, 'catppuccin'),
             ('narrow', 320, 12, 'catppuccin-latte'), ('large-text', 420, 16, 'catppuccin'),
             ('narrow-large', 320, 16, 'catppuccin-latte')]
    def render(case):
        name, width, size, theme = case
        destination = output / name
        destination.mkdir(exist_ok=True)
        config, env = stage(base / name, destination, args, width, size, theme)
        result = subprocess.run(['/usr/bin/quickshell', '-n', '--no-color', '-p', str(config)], env=env, capture_output=True, timeout=30)
        transcript = (result.stdout + result.stderr).decode(errors='replace')
        (destination / 'render.log').write_text(transcript)
        validate_log(transcript)
        assert result.returncode == 0 and 'DESIGN_PREVIEW_PASS' in transcript, transcript
        return name
    try:
        with ThreadPoolExecutor(max_workers=3) as pool:
            for name in pool.map(render, cases):
                print('Rendered and checked ' + name, flush=True)
        evidence = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in (ROOT / 'tools/designreview').glob('*.qml')}
        (output / 'source-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
        print('Review images: ' + str(output))
    finally:
        shutil.rmtree(base)


if __name__ == '__main__':
    main()
