#!/usr/bin/python3
"""Render and exercise the illustrative team-calendar concept, without desktop I/O.

Usage: python3 tools/calendar/capture.py [output-directory]
The existing native test stager supplies an isolated HOME, palette and imports.
No production service, provider request, settings write or installed plugin runs.
"""
import argparse
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("sportray_ui_staging", ROOT / "tests/test-ui-presentation.py")
staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(staging)


def fixture():
    sample = json.loads((ROOT / "tools/readme/sample-state.json").read_text())
    nfl = next(game for game in sample["games"] if game["league"] == "nfl")
    nhl = next(game for game in sample["games"] if game["league"] == "nhl")
    def entry(template, day, index, time_known=True):
        game = json.loads(json.dumps(template))
        game.update({"id": game["league"] + ":calendar-demo-" + str(index),
                     "providerGameId": "calendar-demo-" + str(index),
                     "status": "scheduled", "startTime": day + "T18:00:00Z",
                     "awayScore": None, "homeScore": None})
        return {"game": game, "dateKey": day, "timeKnown": time_known}
    result = {"today": "2026-11-24", "teamOptions": [
        {"value": "", "label": "All followed leagues"},
        {"value": "nfl:2", "label": "Buffalo Bills · NFL"},
        {"value": "nhl:6", "label": "Boston Bruins · NHL"}],
        "states": {
            "nfl:2": {"teamId": "nfl:2", "loading": False, "hasData": True,
                      "partial": False, "errorSummary": "", "coverageStart": "2026-11-24",
                      "coverageEnd": "2026-12-28", "entries": [entry(nfl, day, i, i != 1)
                        for i, day in enumerate(("2026-12-06", "2026-12-13", "2026-12-16", "2026-12-20", "2026-12-23", "2026-12-27"))]},
            "nhl:6": {"teamId": "nhl:6", "loading": False, "hasData": True,
                      "partial": False, "errorSummary": "", "coverageStart": "2026-11-24",
                      "coverageEnd": "2026-12-28", "entries": [entry(nhl, day, i)
                        for i, day in enumerate(("2026-11-25", "2026-11-27", "2026-12-01", "2026-12-04"))]}}}
    result["states"][""] = {"teamId": "", "dateKey": "2026-11-24", "loading": False,
        "hasData": True, "partial": False, "stale": False, "errorSummary": "",
        "entries": [entry(nhl, "2026-11-24", 50), entry(nfl, "2026-11-24", 51)],
        "daySummaries": [{"dateKey": "2026-11-24", "count": 2, "loaded": True, "complete": True},
                         {"dateKey": "2026-11-25", "count": 3, "loaded": True, "complete": False}]}
    return result


def run(output):
    output.mkdir(parents=True, exist_ok=True)
    for case in staging.CASES:
        with tempfile.TemporaryDirectory(prefix="sportray-calendar-concept-") as temporary:
            base = Path(temporary)
            config, env, captures = staging.stage(base, case)
            harness = (ROOT / "tools/calendar/calendar.qml").read_text().replace('"../../', '"plugin/')
            (config / "shell.qml").write_text(harness)
            (config / "calendar-fixture.json").write_text(json.dumps(fixture()))
            result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                                    env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
            text = result.stdout.decode(errors="replace")
            target = output / case["name"]
            target.mkdir(exist_ok=True)
            (target / "calendar.log").write_text(text)
            for capture in captures.iterdir():
                shutil.copy2(capture, target / capture.name)
            errors = ("CALENDAR_CONCEPT_FAIL", "TypeError:", "ReferenceError:", "Binding loop detected",
                      "Error loading configuration", "Unable to assign [undefined]")
            if result.returncode or "CALENDAR_CONCEPT_PASS" not in text or any(error in text for error in errors):
                raise RuntimeError(case["name"] + ":\n" + text)
            print(case["name"] + ": native calendar input/render checks passed")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=Path, default=Path("/tmp/sportray-calendar-concept-review"))
    run(parser.parse_args().output.resolve())
