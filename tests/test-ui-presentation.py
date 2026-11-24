#!/usr/bin/python3
"""Exercise native presentation in an isolated offscreen Qt window.

The desktop-only KeyboardPanel is replaced by the existing capture wrapper.
These checks prove rendered layout and input routing, not Wayland panel behavior.
"""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SHELL = Path("/usr/share/omarchy/shell")
CASES = (
    {"name": "light", "theme": "catppuccin-latte", "width": 400, "fontSize": 12},
    {"name": "dark", "theme": "catppuccin", "width": 400, "fontSize": 12},
    {"name": "narrow", "theme": "catppuccin-latte", "width": 320, "fontSize": 12},
    {"name": "scaled", "theme": "catppuccin", "width": 400, "fontSize": 16},
)


EXACT_COMPONENTS = tuple(Path("components") / name for name in (
    "UpcomingCalendar.qml", "AgendaGameRow.qml", "GameRow.qml", "GameActions.qml", "TeamScheduleLink.qml",
    "FollowingOverview.qml", "StatusNotice.qml", "LeagueStatus.qml", "StandingsStatus.qml", "NextGameCard.qml",
    "GameDetailView.qml", "StandingsRow.qml", "TicketStrip.qml", "TicketOverlay.qml"))


def stage(base, case):
    """Retain production views; expose private IDs only in disposable copies."""
    config = base / "config"
    config.mkdir()
    plugin = config / "plugin"
    plugin.mkdir()
    for name in ("model", "providers", "components", "services"):
        shutil.copytree(ROOT / name, plugin / name,
                        ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copy2(ROOT / "Panel.qml", plugin / "Panel.qml")
    # Render the committed former card only for the fixed-viewport density
    # comparison. It is never substituted for a production component.
    baseline_bytes = (ROOT / "tests/runtime/legacy-density-card.qml.fixture").read_bytes()
    assert hashlib.sha256(baseline_bytes).hexdigest() == "14859900dfcada7c98c56f64447e55d5ed2674ef5cc04d893510ef28d146a87b", \
        "Reviewed e78eddb card density baseline changed"
    baseline = baseline_bytes.decode()
    baseline = baseline.replace("import qs.Commons\n", "import qs.Commons as Commons\n", 1)
    baseline = re.sub(r"(?<![\w.])(Color|Style|Border)\.", r"Commons.\1.", baseline)
    (plugin / "components/LegacyDensityGameRow.qml").write_text(baseline)

    # All changed components execute exact production imports and bindings.
    # Legacy capture qualification is retained only outside this set: rewriting
    # a changed view's Color lookup previously concealed a desktop error.
    upcoming_path = Path("components/UpcomingCalendar.qml")
    for source in plugin.rglob("*.qml"):
        if source.relative_to(plugin) in EXACT_COMPONENTS or source.relative_to(plugin) == Path("Panel.qml"):
            continue
        text = source.read_text()
        if re.search(r"(?<![\w.])Color\.", text) and "import qs.Commons\n" in text:
            text = text.replace("import qs.Commons\n",
                                "import qs.Commons\nimport qs.Commons as TestCommons\n", 1)
            text = re.sub(r"(?<![\w.])Color\.", "TestCommons.Color.", text)
        source.write_text(text)
    production_upcoming = (ROOT / upcoming_path).read_bytes()
    staged_upcoming = (plugin / upcoming_path).read_bytes()
    assert staged_upcoming == production_upcoming, "UpcomingCalendar source was rewritten for testing"
    upcoming_source_hash = hashlib.sha256(production_upcoming).hexdigest()
    source_evidence = []
    for relative in EXACT_COMPONENTS:
        production, staged = (ROOT / relative).read_bytes(), (plugin / relative).read_bytes()
        assert production == staged, str(relative) + " source was rewritten for testing"
        source_evidence.append({"component": relative.as_posix(), "copiedByteForByte": True,
            "productionSha256": hashlib.sha256(production).hexdigest(),
            "stagedSha256": hashlib.sha256(staged).hexdigest()})
    panel = plugin / "Panel.qml"
    text = panel.read_text()
    marker = "  property var anchorItem: null"
    assert text.count(marker) == 1
    aliases = {"testHost": "panel", "testList": "resultList",
               "testDetail": "gameDetailView", "testHub": "settingsHub",
               "testClock": "panelClockTimer", "testCatcher": "keyCatcher",
               "testUtilityScroll": "utilityScroll", "testChrome": "scoreChrome",
               "testDates": "dateCarousel", "testLeaguePicker": "leaguePicker",
               "testSchedulePage": "upcomingPage", "testUpcomingCalendar": "upcomingCalendar",
               "testHeaderTitle": "headerTitle", "testScoreContent": "scoreContent",
               "testCalendarButton": "calendarButton", "testFollowingOverview": "followingOverview"}
    instrumentation = "\n".join("  property alias " + key + ": " + value
        for key, value in aliases.items()) + "\n"
    text = text.replace(marker, instrumentation + marker, 1)
    assert text.replace(instrumentation, "", 1).encode() == (ROOT / "Panel.qml").read_bytes(), \
        "Panel production source changed beyond documented test aliases"
    panel.write_text(text)
    harness = (ROOT / "tests/runtime/ui-presentation.qml").read_text()
    harness = harness.replace('"../.."', '"plugin"').replace('"../../', '"plugin/')
    (config / "shell.qml").write_text(harness)
    (config / "sample-state.json").write_bytes((ROOT / "tools/readme/sample-state.json").read_bytes())
    (config / "ui-case.json").write_text(json.dumps(case))
    imports = base / "imports/qs"
    imports.mkdir(parents=True)
    shutil.copytree(SHELL / "Ui", imports / "Ui")
    wrapper = (ROOT / "tools/readme/KeyboardPanel.qml").read_text()
    wrapper = wrapper.replace("function fittedContentWidth(value) { return value }",
                              "function fittedContentWidth(value) { return Math.min(value, root.parent.width) }")
    (imports / "Ui/KeyboardPanel.qml").write_text(wrapper)
    for name in ("Commons", "services"):
        (imports / name).symlink_to(SHELL / name, target_is_directory=True)
    for name in ("Commons", "Ui", "services"):
        (config / name).symlink_to(imports / name, target_is_directory=True)
    home, runtime, binaries, captures = (base / name for name in ("home", "runtime", "bin", "captures"))
    for directory in (home, runtime, binaries, captures):
        directory.mkdir(mode=0o700)
    (captures / "source-evidence.json").write_text(json.dumps({
        "components": source_evidence,
        "panelInstrumentation": {
            "component": "Panel.qml",
            "productionSha256": hashlib.sha256((ROOT / "Panel.qml").read_bytes()).hexdigest(),
            "stagedSha256": hashlib.sha256(panel.read_bytes()).hexdigest(),
            "changes": ["Private test-only ID aliases"],
            "preservedExceptAliases": True,
            "aliases": aliases,
        },
        "component": upcoming_path.as_posix(), "copiedByteForByte": True,
        "productionSha256": upcoming_source_hash,
        "stagedSha256": hashlib.sha256(staged_upcoming).hexdigest(),
    }, indent=2) + "\n")
    (binaries / "hyprctl").write_text('#!/bin/sh\nprintf \'{"int":0,"bool":false,"custom":"0 0 0 0"}\\n\'\n')
    (binaries / "omarchy-launch-browser").write_text(
        '#!/bin/sh\nprintf \'%s\\n\' "$1" >> "$SPORTRAY_TEST_BROWSER_LOG"\n')
    for executable in binaries.iterdir():
        executable.chmod(0o700)
    env = dict(os.environ)
    env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_STATE_HOME": str(home / ".local/state"),
                "XDG_DATA_HOME": str(home / ".local/share"),
                "XDG_CACHE_HOME": str(home / ".cache"), "XDG_RUNTIME_DIR": str(runtime),
                "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QT_QUICK_BACKEND": "software",
                "QML_IMPORT_PATH": str(imports.parent), "QS_DISABLE_FILE_WATCHER": "1",
                "QML_XHR_ALLOW_FILE_READ": "1", "TZ": "America/New_York",
                "SPORTRAY_TEST_CAPTURE": str(captures),
                "SPORTRAY_TEST_BROWSER_LOG": str(base / "browser.log"),
                "PATH": str(binaries) + ":/usr/bin"})
    for key in ("DISPLAY", "WAYLAND_DISPLAY", "HYPRLAND_INSTANCE_SIGNATURE",
                "DBUS_SESSION_BUS_ADDRESS", "QS_CONFIG_NAME", "QS_MANIFEST"):
        env.pop(key, None)
    theme = config / "theme"
    theme.mkdir()
    shutil.copy2(SHELL.parent / "themes" / case["theme"] / "colors.toml", theme / "colors.toml")
    templates = base / "templates"
    templates.mkdir()
    shutil.copy2(SHELL.parent / "default/themed/shell.toml.tpl", templates / "shell.toml.tpl")
    lines = (SHELL.parent / "bin/omarchy-theme-set-templates").read_text().splitlines()
    for prefix, value in {"TEMPLATES_DIR=": templates, "USER_TEMPLATES_DIR=": base / "none",
                          "NEXT_THEME_DIR=": theme}.items():
        assert sum(line.startswith(prefix) for line in lines) == 1
        lines = [prefix + '"' + str(value) + '"' if line.startswith(prefix) else line for line in lines]
    renderer = base / "render-theme.sh"
    renderer.write_text("\n".join(lines) + "\n")
    subprocess.run(["/usr/bin/bash", str(renderer)], env=env, check=True,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    return config, env, captures


class UiPresentationTests(unittest.TestCase):
    def test_native_flow_pointer_routing_and_adaptive_layout(self):
        self.assertTrue(SHELL.is_dir(), "installed Omarchy UI modules required")
        cases = [case for case in CASES if not os.environ.get("SPORTRAY_UI_CASE")
                 or case["name"] == os.environ["SPORTRAY_UI_CASE"]]
        self.assertTrue(cases, "Unknown SPORTRAY_UI_CASE")
        for case in cases:
            with self.subTest(case=case["name"]), tempfile.TemporaryDirectory(prefix="sportray-ui-test-") as temporary:
                base = Path(temporary)
                config, env, captures = stage(base, case)
                try:
                    result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                                            env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=150)
                    transcript = result.stdout.decode(errors="replace")
                except subprocess.TimeoutExpired as error:
                    transcript = (error.stdout or b"").decode(errors="replace")
                    self.fail("UI test timed out:\n" + transcript)
                destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
                if destination:
                    output = Path(destination) / ("ui-" + case["name"])
                    output.mkdir(parents=True, exist_ok=True)
                    for capture in captures.iterdir():
                        shutil.copy2(capture, output / capture.name)
                    (output / "ui-presentation.log").write_text(transcript)
                evidence = json.loads((captures / "source-evidence.json").read_text())
                self.assertTrue(evidence["panelInstrumentation"]["preservedExceptAliases"])
                self.assertEqual(evidence["panelInstrumentation"]["productionSha256"],
                    hashlib.sha256((ROOT / "Panel.qml").read_bytes()).hexdigest(),
                    "Panel changed during the run")
                self.assertEqual(len(evidence["components"]), len(EXACT_COMPONENTS))
                for item in evidence["components"]:
                    self.assertTrue(item["copiedByteForByte"], item["component"])
                    self.assertEqual(item["productionSha256"], item["stagedSha256"], item["component"])
                    self.assertEqual(item["productionSha256"],
                        hashlib.sha256((ROOT / item["component"]).read_bytes()).hexdigest(),
                        item["component"] + " changed during the run")
                self.assertTrue(evidence["copiedByteForByte"])
                self.assertEqual(evidence["productionSha256"], evidence["stagedSha256"])
                self.assertEqual(result.returncode, 0, transcript)
                for forbidden in ("UI_PRESENTATION_FAIL", "TypeError:", "ReferenceError:",
                                  "Binding loop detected", "Error loading configuration", "Unable to assign [undefined]"):
                    self.assertNotIn(forbidden, transcript, transcript)
                self.assertIn("UI_PRESENTATION_PASS " + case["name"], transcript, transcript)
                self.assertEqual((base / "browser.log").read_text().splitlines(),
                                 ["https://www.nhl.com/gamecenter/2026020001"])
                for name in ("following", "detail", "standings", "settings", "upcoming", "calendar-global"):
                    data = (captures / (name + ".png")).read_bytes()
                    self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
                    self.assertEqual(int.from_bytes(data[16:20], "big"), case["width"])
                    self.assertEqual(int.from_bytes(data[20:24], "big"), 640)


if __name__ == "__main__":
    unittest.main()
