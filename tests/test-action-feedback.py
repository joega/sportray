#!/usr/bin/python3
"""Run the real SettingsStore with deterministic process/file-watcher boundaries."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent

class ActionFeedbackTests(unittest.TestCase):
    def test_real_settings_store_feedback_and_guarded_undo(self):
        with tempfile.TemporaryDirectory(prefix="sp-feedback-") as temporary:
            base = Path(temporary)
            imports = base / "imports"
            io = imports / "Quickshell/Io"
            io.mkdir(parents=True)
            (imports / "Quickshell/qmldir").write_text("module Quickshell\nsingleton Quickshell 1.0 Quickshell.qml\n")
            (imports / "Quickshell/Quickshell.qml").write_text('''pragma Singleton
import QtQuick
QtObject { function env(name) { return name === "HOME" ? "/fixture-home" : "" } }
''')
            (io / "qmldir").write_text("module Quickshell.Io\nProcess 1.0 Process.qml\nStdioCollector 1.0 StdioCollector.qml\nFileView 1.0 FileView.qml\n")
            (io / "Process.qml").write_text('''import QtQuick
QtObject {
  objectName: "fixtureProcess"
  property bool running: false
  property var command: []
  property var stdout: null
  property int starts: 0
  signal exited(int exitCode, int exitStatus)
  onRunningChanged: if (running) { if (stdout) stdout.text = ""; starts++ }
  function finish(code, text) { running = false; if (stdout) stdout.text = text; exited(code, 0) }
}
''')
            (io / "StdioCollector.qml").write_text('''import QtQuick
QtObject { property bool waitForEnd: false; property string text: "" }
''')
            (io / "FileView.qml").write_text('''import QtQuick
QtObject {
  objectName: "fixtureFileView"
  property string path: ""
  property bool preload: true
  property bool watchChanges: false
  property bool printErrors: true
  signal fileChanged()
}
''')
            home, runtime = base / "home", base / "runtime"
            home.mkdir(mode=0o700); runtime.mkdir(mode=0o700)
            env = dict(os.environ)
            env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_STATE_HOME": str(home / ".local/state"), "XDG_CACHE_HOME": str(home / ".cache"),
                "XDG_RUNTIME_DIR": str(runtime), "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software",
                "QML_IMPORT_PATH": str(imports), "QML_XHR_ALLOW_FILE_READ": "1"})
            for key in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE", "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
                env.pop(key, None)
            result = subprocess.run(["/usr/lib/qt6/bin/qmltestrunner", "-import", str(imports), "-input",
                str(ROOT / "tests/qml/tst_ActionFeedback.qml"), "-platform", "offscreen"],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
            transcript = result.stdout.decode(errors="replace")
            if os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR"):
                destination = Path(os.environ["SPORTRAY_TEST_ARTIFACT_DIR"])
                destination.mkdir(parents=True, exist_ok=True)
                (destination / "action-feedback.log").write_text(transcript)
            self.assertEqual(result.returncode, 0, transcript)
            self.assertNotIn("FAIL!", transcript)
            self.assertNotIn("SKIP", transcript)
            self.assertRegex(transcript, r"Totals:\s+\d+ passed, 0 failed, 0 skipped")

if __name__ == "__main__": unittest.main()
