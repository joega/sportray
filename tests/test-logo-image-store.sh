#!/usr/bin/env bash
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
QML_TEST_RUNNER=${QML_TEST_RUNNER:-/usr/lib/qt6/bin/qmltestrunner}
IMPORT_DIR=$(mktemp -d)
trap 'rm -rf "$IMPORT_DIR"' EXIT

# Quickshell.Io is built into the shell executable, not a loadable QtTest
# plugin. Fixture its process/file-watcher boundaries; load the actual services
# and run their bindings, callbacks, queues and transitions in the real Qt engine.
# FileView notifications are driven explicitly, not claimed as filesystem proof.
mkdir -p "$IMPORT_DIR/Quickshell/Io"
# Rendering tests use the actual Qt Text and component logic, with only the
# host palette/font tokens replaced. This is not an Omarchy theme acceptance.
mkdir -p "$IMPORT_DIR/qs/Commons"
cat > "$IMPORT_DIR/qs/Commons/qmldir" <<'QMLDIR'
module qs.Commons
singleton Color 1.0 Color.qml
singleton Style 1.0 Style.qml
QMLDIR
cat > "$IMPORT_DIR/qs/Commons/Color.qml" <<'QML'
pragma Singleton
import QtQuick
QtObject {
  readonly property color muted: "#666666"
  readonly property color urgent: "#bb2222"
  readonly property var popups: ({text: "#222222"})
}
QML
cat > "$IMPORT_DIR/qs/Commons/Style.qml" <<'QML'
pragma Singleton
import QtQuick
QtObject {
  readonly property var font: ({family: "sans-serif", bodySmall: 14})
}
QML
cat > "$IMPORT_DIR/Quickshell/qmldir" <<'QMLDIR'
module Quickshell
singleton Quickshell 1.0 Quickshell.qml
QMLDIR
cat > "$IMPORT_DIR/Quickshell/Quickshell.qml" <<'QML'
pragma Singleton
import QtQuick
QtObject {
  function env(name) { return name === "HOME" ? "/fixture-home" : "" }
}
QML
cat > "$IMPORT_DIR/Quickshell/Io/qmldir" <<'QMLDIR'
module Quickshell.Io
Process 1.0 Process.qml
SplitParser 1.0 SplitParser.qml
StdioCollector 1.0 StdioCollector.qml
FileView 1.0 FileView.qml
QMLDIR
cat > "$IMPORT_DIR/Quickshell/Io/Process.qml" <<'QML'
import QtQuick
QtObject {
  objectName: "fixtureProcess"
  property bool running: false
  property var command: []
  property var stdout: null
  property int starts: 0
  property var commands: []
  signal exited(int exitCode, int exitStatus)
  onRunningChanged: if (running) {
    if (stdout && "text" in stdout) stdout.text = ""
    starts += 1
    commands = commands.concat([command.slice()])
  }
  function finish(exitCode, output) {
    running = false
    if (stdout && output) stdout.read(output)
    exited(exitCode, 0)
  }
}
QML
cat > "$IMPORT_DIR/Quickshell/Io/SplitParser.qml" <<'QML'
import QtQuick
QtObject {
  property string splitMarker: ""
  signal read(string chunk)
}
QML
cat > "$IMPORT_DIR/Quickshell/Io/StdioCollector.qml" <<'QML'
import QtQuick
QtObject {
  property bool waitForEnd: false
  property string text: ""
  function read(chunk) { text += chunk }
}
QML
cat > "$IMPORT_DIR/Quickshell/Io/FileView.qml" <<'QML'
import QtQuick
QtObject {
  objectName: "fixtureFileView"
  property string path: ""
  property bool preload: true
  property bool watchChanges: false
  property bool blockWrites: false
  property bool printErrors: true
  signal fileChanged()
}
QML

QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  "$QML_TEST_RUNNER" -import "$IMPORT_DIR" -input "$ROOT_DIR/tests/qml" -platform offscreen
