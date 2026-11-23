#!/usr/bin/env bash
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
QML_TEST_RUNNER=${QML_TEST_RUNNER:-/usr/lib/qt6/bin/qmltestrunner}
IMPORT_DIR=$(mktemp -d)
trap 'rm -rf "$IMPORT_DIR"' EXIT

# Quickshell.Io is built into the shell executable, not a loadable QtTest
# plugin. Replace only that process boundary; load the actual store and run
# its bindings, deferred callbacks, queues and cache in the real Qt engine.
mkdir -p "$IMPORT_DIR/Quickshell/Io"
cat > "$IMPORT_DIR/Quickshell/Io/qmldir" <<'QMLDIR'
module Quickshell.Io
Process 1.0 Process.qml
SplitParser 1.0 SplitParser.qml
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

QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  "$QML_TEST_RUNNER" -import "$IMPORT_DIR" -input "$ROOT_DIR/tests/qml" -platform offscreen
