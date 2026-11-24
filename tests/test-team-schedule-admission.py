#!/usr/bin/python3
"""Exercise the real FetchService with deterministic I/O and no settings owner."""
import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SUPPORT = runpy.run_path(str(ROOT / "tests/test-upcoming-calendar.py"))

class TeamScheduleAdmissionTests(unittest.TestCase):
    def test_transient_team_admission_uses_real_service_and_fake_process_io(self):
        with tempfile.TemporaryDirectory(prefix="sp-team-") as temporary:
            base = Path(temporary)
            imports = base / "imports"
            io = imports / "Quickshell/Io"
            io.mkdir(parents=True)
            process = SUPPORT["PROCESS"].replace('  property bool running: false', '''  property bool stdinEnabled: false
  property var writes: []
  function write(value) { writes = writes.concat([value]) }
  signal started()
  property bool running: false''')
            (io / "Process.qml").write_text(process)
            (io / "SplitParser.qml").write_text(SUPPORT["SPLIT_PARSER"])
            (io / "StdioCollector.qml").write_text('''import QtQuick
QtObject {
  property bool waitForEnd: false
  property string text: ""
  function read(chunk) { text += chunk }
}
''')
            (io / "qmldir").write_text("module Quickshell.Io\nProcess 1.0 Process.qml\nSplitParser 1.0 SplitParser.qml\nStdioCollector 1.0 StdioCollector.qml\n")
            (imports / "Quickshell/qmldir").write_text("module Quickshell\nsingleton Quickshell 1.0 Quickshell.qml\n")
            (imports / "Quickshell/Quickshell.qml").write_text('''pragma Singleton
import QtQuick
QtObject { function env(name) { return name === "HOME" ? "/fixture-home" : "" } }
''')
            home, runtime = base / "home", base / "runtime"
            home.mkdir(mode=0o700); runtime.mkdir(mode=0o700)
            env = dict(os.environ)
            env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_STATE_HOME": str(home / ".local/state"), "XDG_CACHE_HOME": str(home / ".cache"),
                "XDG_RUNTIME_DIR": str(runtime), "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software", "TZ": "America/New_York",
                "QML_IMPORT_PATH": str(imports), "QML_XHR_ALLOW_FILE_READ": "1"})
            for key in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
                env.pop(key, None)
            result = subprocess.run(["/usr/lib/qt6/bin/qmltestrunner", "-import", str(imports), "-input",
                str(ROOT / "tests/qml/tst_TeamScheduleAdmission.qml"), "-platform", "offscreen"],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45)
            transcript = result.stdout.decode(errors="replace")
            if os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR"):
                destination = Path(os.environ["SPORTRAY_TEST_ARTIFACT_DIR"])
                destination.mkdir(parents=True, exist_ok=True)
                (destination / "team-schedule-admission.log").write_text(transcript)
            self.assertEqual(result.returncode, 0, transcript)
            self.assertNotIn("FAIL!", transcript)
            self.assertNotIn("SKIP", transcript)
            self.assertRegex(transcript, r"Totals:\s+\d+ passed, 0 failed, 0 skipped")

if __name__ == "__main__": unittest.main()
