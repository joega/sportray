#!/usr/bin/python3
"""Capture native README examples without loading or changing the installed plugin.

Usage: python3 tools/capture-readme.py [output-directory] [--logo-cache path]
Uses installed Omarchy controls and a stock theme in an isolated HOME.
Sample data is illustrative. Only logo assets use the bounded production helper.
The capture-only layer wrapper does not establish desktop/runtime acceptance.
"""
import argparse
import base64
import json
import os
import re
import runpy
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def capture(output, logo_cache=None, theme_name="catppuccin-latte"):
    shell = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell"
    with tempfile.TemporaryDirectory(prefix="sportray-readme-") as temporary:
        base = Path(temporary)
        config = base / "config"
        config.mkdir()
        home = base / "home"
        home.mkdir(mode=0o700)
        runtime = base / "runtime"
        runtime.mkdir(mode=0o700)
        env = dict(os.environ)
        env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_STATE_HOME": str(home / ".local/state"), "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_CACHE_HOME": str(home / ".cache"), "XDG_RUNTIME_DIR": str(runtime),
            "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
            "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software",
            "QS_DISABLE_FILE_WATCHER": "1", "QML_XHR_ALLOW_FILE_READ": "1",
            "SPORTRAY_SCREENSHOT_DIR": str(output), "TZ": "America/New_York"})
        for key in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE",
                    "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
            env.pop(key, None)
        for name in ("model", "providers", "components", "services"):
            shutil.copytree(ROOT / name, config / "plugin" / name,
                ignore=shutil.ignore_patterns("__pycache__"))
        def capture_imports(text):
            # Standalone instantiation adds a different QML context chain.
            # Qualify the same native palette singleton only in staged copies;
            # retain every control, palette value, dimension and layout.
            if re.search(r"(?<![\w.])Color\.", text) and "import qs.Commons\n" in text:
                text = text.replace("import qs.Commons\n", "import qs.Commons\nimport qs.Commons as CaptureCommons\n", 1)
                text = re.sub(r"(?<![\w.])Color\.", "CaptureCommons.Color.", text)
            return text
        for staged in (config / "plugin").rglob("*.qml"):
            staged.write_text(capture_imports(staged.read_text()))
        strip = config / "plugin/components/TicketStrip.qml"
        ticker = strip.read_text()
        marker = "  property var games: []"
        assert ticker.count(marker) == 1
        strip.write_text(ticker.replace(marker, "  property alias captureContentWidth: gameRow.implicitWidth\n"
            "  property alias captureControlWidth: controls.width\n"
            + marker, 1))
        panel = capture_imports((ROOT / "Panel.qml").read_text())
        marker = "  property var anchorItem: null"
        assert panel.count(marker) == 1
        panel = panel.replace(marker, "\n".join([
            "  property alias capturePanel: panel", "  property alias captureHub: settingsHub",
            "  property alias captureList: resultList", "  property alias captureDetail: gameDetailView",
            "  property alias captureClock: panelClockTimer", marker]), 1)
        (config / "plugin/Panel.qml").write_text(panel)
        gallery = (ROOT / "tools/readme/gallery.qml").read_text()
        gallery = gallery.replace('"../.."', '"plugin"').replace('"../../', '"plugin/')
        (config / "shell.qml").write_text(gallery)
        sample = json.loads((ROOT / "tools/readme/sample-state.json").read_text())
        (config / "sample-state.json").write_text(json.dumps(sample))
        logos = {}
        if logo_cache:
            with logo_cache.open("rb") as stream:
                raw = stream.read(8 * 1024 * 1024 + 1)
            assert len(raw) <= 8 * 1024 * 1024
            logos = json.loads(raw)
        else:
            for url in sample["logoUrls"]:
                result = subprocess.run(["/usr/bin/python3", "-I", "-S",
                    str(ROOT / "scripts/logo-image-helper.py"), url], env=env,
                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
                if result.returncode != 0:
                    raise RuntimeError("Logo capture failed; supply --logo-cache for offline capture: " + url)
                value = result.stdout.decode().strip()
                assert len(value) <= 350000 and value.startswith("data:image/")
                logos[url] = value
        policy = runpy.run_path(str(ROOT / "scripts/logo-image-helper.py"))
        assert isinstance(logos, dict) and set(logos) == set(sample["logoUrls"])
        for url, value in logos.items():
            policy["validate_url"](url)
            assert isinstance(value, str) and len(value) <= 350000
            match = re.fullmatch(r"data:(image/(?:png|jpeg|webp));base64,([A-Za-z0-9+/=]+)", value)
            assert match is not None
            raster = base64.b64decode(match[2], validate=True)
            assert len(raster) <= policy["MAX_BYTES"]
            assert policy["validate_image"](raster) == match[1]
        (config / "logos.json").write_text(json.dumps(logos))
        output.mkdir(parents=True, exist_ok=True)
        imports = base / "imports/qs"
        imports.mkdir(parents=True)
        shutil.copytree(shell / "Ui", imports / "Ui")
        shutil.copy2(ROOT / "tools/readme/KeyboardPanel.qml", imports / "Ui/KeyboardPanel.qml")
        for name in ("Commons", "services"):
            (imports / name).symlink_to(shell / name, target_is_directory=True)
        for name in ("Commons", "Ui", "services"):
            (config / name).symlink_to(imports / name, target_is_directory=True)
        env["QML_IMPORT_PATH"] = str(imports.parent)
        binaries = base / "bin"
        binaries.mkdir()
        (binaries / "hyprctl").write_text('#!/usr/bin/sh\nprintf \'{"int":0,"bool":false,"custom":"0 0 0 0"}\\n\'\n')
        (binaries / "hyprctl").chmod(0o700)
        env["PATH"] = str(binaries) + ":/usr/bin"
        theme = config / "theme"
        theme.mkdir()
        shutil.copy2(shell.parent / "themes" / theme_name / "colors.toml", theme / "colors.toml")
        templates = base / "templates"
        templates.mkdir()
        shutil.copy2(shell.parent / "default/themed/shell.toml.tpl", templates / "shell.toml.tpl")
        renderer = (shell.parent / "bin/omarchy-theme-set-templates").read_text()
        replacements = {"TEMPLATES_DIR=": str(templates), "USER_TEMPLATES_DIR=": str(base / "no-user-templates"), "NEXT_THEME_DIR=": str(theme)}
        lines = renderer.splitlines()
        for prefix, value in replacements.items():
            assert sum(line.startswith(prefix) for line in lines) == 1
            lines = [prefix + '"' + value + '"' if line.startswith(prefix) else line for line in lines]
        staged_renderer = base / "render-theme.sh"
        staged_renderer.write_text("\n".join(lines) + "\n")
        subprocess.run(["/usr/bin/bash", str(staged_renderer)], env=env, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
        assert (theme / "shell.toml").exists() and "{{" not in (theme / "shell.toml").read_text()
        try:
            result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
        except subprocess.TimeoutExpired as error:
            log = (error.stdout or b"").decode(errors="replace")
            (output / "capture.log").write_text(log)
            raise RuntimeError("Capture timed out:\n" + log) from error
        log = result.stdout.decode(errors="replace")
        (output / "capture.log").write_text(log)
        errors = ("SPORTRAY_CAPTURE_FAIL", "TypeError:", "ReferenceError:", "Binding loop detected",
            "Error loading configuration", "Unable to assign [undefined]")
        if result.returncode or "SPORTRAY_CAPTURE_PASS" not in log or any(e in log for e in errors):
            raise RuntimeError(log)
        if output == (ROOT / "screenshots").resolve():
            shutil.copy2(output / "preview.png", ROOT / "preview.png")
            (output / "preview.png").unlink()
        print("Captured seven native feature views and the 1340×820 preview in " + str(output))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=Path, default=ROOT / "screenshots")
    parser.add_argument("--logo-cache", type=Path)
    parser.add_argument("--theme", choices=("catppuccin-latte", "catppuccin"), default="catppuccin-latte")
    args = parser.parse_args()
    capture(args.output.resolve(), args.logo_cache, args.theme)
