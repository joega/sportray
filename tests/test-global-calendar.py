#!/usr/bin/python3
"""Run global calendar ownership tests in Qt with a deterministic Io boundary.

This uses the production CalendarFetch and provider/parser code. Only Process Io
is replaced; no HTTP request, shell session, configuration or preference is used.
"""

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
RUNNER = Path("/usr/lib/qt6/bin/qmltestrunner")

PROCESS = '''import QtQuick
QtObject {
  objectName: "fixtureProcess"
  property bool running: false
  property var command: []
  property var stdout: null
  property int starts: 0
  property var commands: []
  property var signalsSent: []
  signal exited(int exitCode, int exitStatus)
  onRunningChanged: if (running) {
    starts++
    commands = commands.concat([command.slice()])
  }
  function signal(value) {
    signalsSent = signalsSent.concat([value])
    running = false
  }
  // Termination and exit are deliberately separate. This reproduces the real
  // period during which running=false but the old process can still deliver
  // final stdout/exited; a replacement must not use the shared slot yet.
  function finish(exitCode, output) {
    running = false
    if (stdout && output) stdout.read(output)
    exited(exitCode, 0)
  }
}
'''
SPLIT_PARSER = '''import QtQuick
QtObject {
  property string splitMarker: ""
  signal read(string chunk)
}
'''


class GlobalCalendarTests(unittest.TestCase):
    def test_real_service_lifecycle_with_deterministic_process_io(self):
        self.assertTrue(RUNNER.is_file(), "QtTest runner is required")
        self.assertEqual(len(re.findall(r"^\s*Process\s*\{",
            (ROOT / "services/CalendarFetch.qml").read_text(), re.MULTILINE)), 1,
            "Global and team calendars must share the existing single CalendarFetch Process")
        with tempfile.TemporaryDirectory(prefix="sportray-global-calendar-test-") as temporary:
            base = Path(temporary)
            imports = base / "imports"
            io = imports / "Quickshell/Io"
            io.mkdir(parents=True)
            (io / "qmldir").write_text("module Quickshell.Io\nProcess 1.0 Process.qml\nSplitParser 1.0 SplitParser.qml\n")
            (io / "Process.qml").write_text(PROCESS)
            (io / "SplitParser.qml").write_text(SPLIT_PARSER)
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
            command = [str(RUNNER), "-import", str(imports), "-input",
                       str(ROOT / "tests/qml/tst_GlobalCalendarFetch.qml"), "-platform", "offscreen"]
            result = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=45)
            transcript = result.stdout.decode(errors="replace")
            destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
            if destination:
                output = Path(destination)
                output.mkdir(parents=True, exist_ok=True)
                (output / "global-calendar-qt.log").write_text(transcript)
            self.assertEqual(result.returncode, 0, transcript)
            self.assertNotIn("FAIL!", transcript, transcript)
            self.assertNotIn("SKIP", transcript, transcript)
            totals = re.search(r"Totals:\s+(\d+) passed, 0 failed, 0 skipped", transcript)
            self.assertIsNotNone(totals, transcript)
            self.assertGreater(int(totals.group(1)), 2, "No service tests executed:\n" + transcript)


if __name__ == "__main__":
    unittest.main()
