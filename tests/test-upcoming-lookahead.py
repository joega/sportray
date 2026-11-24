#!/usr/bin/python3
"""Exercise the real LeagueFetch lookahead with the shared deterministic Io stub."""

import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SUPPORT = runpy.run_path(str(ROOT / "tests/test-upcoming-calendar.py"))


class UpcomingLookaheadTests(unittest.TestCase):
    def test_lookahead_yields_and_resumes_without_resetting_the_hop_bound(self):
        with tempfile.TemporaryDirectory(prefix="sportray-lookahead-test-") as temporary:
            base = Path(temporary)
            imports = base / "imports"
            io = imports / "Quickshell/Io"
            io.mkdir(parents=True)
            (io / "qmldir").write_text("module Quickshell.Io\nProcess 1.0 Process.qml\nSplitParser 1.0 SplitParser.qml\n")
            (io / "Process.qml").write_text(SUPPORT["PROCESS"])
            (io / "SplitParser.qml").write_text(SUPPORT["SPLIT_PARSER"])
            home, runtime = base / "home", base / "runtime"
            home.mkdir(mode=0o700)
            runtime.mkdir(mode=0o700)
            env = dict(os.environ)
            env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
                        "XDG_STATE_HOME": str(home / ".local/state"),
                        "XDG_CACHE_HOME": str(home / ".cache"), "XDG_RUNTIME_DIR": str(runtime),
                        "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                        "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software",
                        "QML_IMPORT_PATH": str(imports), "QML_XHR_ALLOW_FILE_READ": "1"})
            for key in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE",
                        "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
                env.pop(key, None)
            result = subprocess.run([str(SUPPORT["RUNNER"]), "-import", str(imports), "-input",
                str(ROOT / "tests/qml/tst_UpcomingLookahead.qml"), "-platform", "offscreen"],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45)
            transcript = result.stdout.decode(errors="replace")
            destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
            if destination:
                output = Path(destination)
                output.mkdir(parents=True, exist_ok=True)
                (output / "upcoming-lookahead-qt.log").write_text(transcript)
            self.assertEqual(result.returncode, 0, transcript)
            self.assertIn("8 passed, 0 failed, 0 skipped", transcript)


if __name__ == "__main__":
    unittest.main()
