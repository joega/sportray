#!/usr/bin/python3
"""Render production views with installed Omarchy UI, offscreen."""

import os
from pathlib import Path
import selectors
import shutil
import struct
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parent.parent
SHELL = Path("/usr/share/omarchy/shell")


class RenderedViewTests(unittest.TestCase):
    def test_detail_updates_focus_scroll_and_standings_states(self):
        self.assertTrue(SHELL.is_dir(), "installed Omarchy source is required")
        with tempfile.TemporaryDirectory(prefix="sportray-views-test-") as temporary:
            base = Path(temporary)
            home = base / "home"
            home.mkdir(mode=0o700)
            runtime = base / "runtime"
            runtime.mkdir(mode=0o700)
            config = base / "config"
            config.mkdir()
            for name in ("services", "model", "providers", "components", "fixtures", "scripts"):
                shutil.copytree(ROOT / name, config / name)
            # Quickshell's qs.* runtime imports are rooted at its config,
            # unlike qmllint's normal URI search. Expose the real host modules
            # there too so their singleton identities match native runtime.
            for name in ("Commons", "Ui"):
                (config / name).symlink_to(SHELL / name, target_is_directory=True)
            harness = (ROOT / "tests/runtime/rendered-views.qml").read_text()
            for name in ("components", "model", "fixtures"):
                harness = harness.replace('"../../' + name, '"' + name)
            (config / "shell.qml").write_text(harness)
            imports = base / "imports"
            imports.mkdir()
            (imports / "qs").symlink_to(SHELL, target_is_directory=True)
            binaries = base / "bin"
            binaries.mkdir()
            hyprctl = binaries / "hyprctl"
            hyprctl.write_text('#!/usr/bin/sh\nprintf \'{"int":0,"bool":false,"custom":"0 0 0 0"}\\n\'\n')
            hyprctl.chmod(0o700)
            captures = base / "captures"
            captures.mkdir()
            environment = dict(os.environ)
            environment.update({
                "HOME": str(home), "XDG_RUNTIME_DIR": str(runtime),
                "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_CACHE_HOME": str(home / ".cache"),
                "XDG_STATE_HOME": str(home / ".local/state"),
                "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software",
                "QML_IMPORT_PATH": str(imports), "QML_XHR_ALLOW_FILE_READ": "1",
                "QS_DISABLE_FILE_WATCHER": "1", "SPORTRAY_TEST_CAPTURE": str(captures),
                "PATH": str(binaries) + ":/usr/bin",
            })
            for name in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE",
                         "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
                environment.pop(name, None)
            process = subprocess.Popen(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            transcript = bytearray()
            try:
                passed = False
                with selectors.DefaultSelector() as selector:
                    selector.register(process.stdout, selectors.EVENT_READ)
                    deadline = time.monotonic() + 15
                    while time.monotonic() < deadline:
                        if not selector.select(timeout=0.05):
                            continue
                        chunk = os.read(process.stdout.fileno(), 65536)
                        if not chunk:
                            break
                        transcript.extend(chunk)
                        self.assertLess(len(transcript), 1024 * 1024)
                        self.assertNotIn(b"VIEWS_TEST FAIL", transcript, transcript.decode(errors="replace"))
                        for forbidden in (b"TypeError:", b"ReferenceError:", b"Binding loop detected", b"Error loading configuration", b"Unable to assign [undefined] to QColor"):
                            self.assertNotIn(forbidden, transcript, transcript.decode(errors="replace"))
                        if b"VIEWS_TEST PASS" in transcript:
                            passed = True
                            break
                self.assertTrue(passed, transcript.decode(errors="replace"))
                for name in ("detail-live", "detail-scored", "detail-missing"):
                    data = (captures / (name + ".png")).read_bytes()
                    self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
                    self.assertEqual(struct.unpack(">II", data[16:24]), (400, 360))
                destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
                if destination:
                    output = Path(destination)
                    output.mkdir(parents=True, exist_ok=True)
                    for capture in captures.iterdir():
                        shutil.copy2(capture, output / capture.name)
                    (output / "rendered-views.log").write_bytes(transcript)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()
                process.wait(timeout=2)
                process.stdout.close()


if __name__ == "__main__":
    unittest.main()
