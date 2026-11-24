#!/usr/bin/python3
"""Render compact game cards and test their exact-production native interactions."""
import argparse
import base64
import runpy
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("sportray_ui_staging", ROOT / "tests/test-ui-presentation.py")
staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(staging)
COMPONENTS = ("GameRow.qml", "GameActions.qml", "TeamScheduleLink.qml", "GameDetailView.qml", "StandingsRow.qml")


def fixture():
    sample = json.loads((ROOT / "tools/readme/sample-state.json").read_text())
    live = json.loads(json.dumps(next(g for g in sample["games"] if g["league"] == "nfl")))
    scheduled = json.loads(json.dumps(next(g for g in sample["games"] if g["league"] == "nba")))
    final = json.loads(json.dumps(live))
    final.update({"id": "nfl:card-final", "providerGameId": "card-final", "status": "final", "statusDetail": "Final", "clock": None})
    long = json.loads(json.dumps(scheduled))
    long.update({"id": "nba:card-long", "providerGameId": "card-long", "odds": {"details": "A deliberately long pregame bookmaker line that must wrap without hiding either the local start time or the game action"}})
    for g in (live, scheduled, final, long):
        g["presentation"] = {"isFavorite": True, "awayIsFavorite": True, "homeIsFavorite": False,
                             "showLeagueContext": True, "leagueLabel": g["league"].upper()}
    detail = json.loads(json.dumps(next(g for g in sample["games"] if g["league"] == "mlb")))
    detail["lines"] = {side: [{"period": i, "value": i % 2} for i in range(1, 13)] for side in ("away", "home")}
    detail["stats"] = {side: [{"key": "fixture-" + str(i), "label": "Fixture team stat " + str(i), "value": str(i)} for i in range(8)] for side in ("away", "home")}
    detail["situation"]["lastPlay"] = "A long play description that must remain fully readable while inspecting the game, including the throw to second and the next batter's preparation."
    return {"now": sample["now"], "games": [live, scheduled, final, long], "detail": detail,
            "standing": sample["standings"]["rows"][0]}


def run(output, logo_cache=None):
    output.mkdir(parents=True, exist_ok=True)
    baseline_bytes = (ROOT / "tests/runtime/legacy-density-card.qml.fixture").read_bytes()
    assert hashlib.sha256(baseline_bytes).hexdigest() == "14859900dfcada7c98c56f64447e55d5ed2674ef5cc04d893510ef28d146a87b"
    baseline = baseline_bytes.decode()
    # Baseline is the committed former layout; qualification only makes its
    # singleton lookup explicit in this isolated capture host.
    baseline = baseline.replace("import qs.Commons\n", "import qs.Commons as Commons\n", 1)
    baseline = re.sub(r"(?<![\w.])(Color|Style|Border)\.", r"Commons.\1.", baseline)
    for case in staging.CASES:
        with tempfile.TemporaryDirectory(prefix="sportray-cards-") as temporary:
            base = Path(temporary)
            config, env, captures = staging.stage(base, case)
            evidence = {}
            for name in COMPONENTS:
                source = ROOT / "components" / name
                destination = config / "plugin/components" / name
                shutil.copy2(source, destination)
                assert source.read_bytes() == destination.read_bytes()
                evidence[name] = hashlib.sha256(source.read_bytes()).hexdigest()
            (config / "plugin/components/BaselineGameRow.qml").write_text(baseline)
            (config / "cards-fixture.json").write_text(json.dumps(fixture()))
            logos = {}
            if logo_cache:
                raw = logo_cache.read_bytes()
                assert len(raw) <= 8 * 1024 * 1024
                logos = json.loads(raw)
                policy = runpy.run_path(str(ROOT / "scripts/logo-image-helper.py"))
                assert isinstance(logos, dict)
                for url, value in logos.items():
                    policy["validate_url"](url)
                    assert isinstance(value, str) and len(value) <= 350000
                    match = re.fullmatch(r"data:(image/(?:png|jpeg|webp));base64,([A-Za-z0-9+/=]+)", value)
                    assert match is not None
                    raster = base64.b64decode(match[2], validate=True)
                    assert len(raster) <= policy["MAX_BYTES"] and policy["validate_image"](raster) == match[1]
            (config / "logos.json").write_text(json.dumps(logos))
            harness = (ROOT / "tools/cards/cards.qml").read_text().replace('"../../', '"plugin/')
            (config / "shell.qml").write_text(harness)
            target = output / case["name"]
            target.mkdir(exist_ok=True)
            log_path = target / "cards.log"
            try:
                with log_path.open("wb") as log:
                    result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)], env=env,
                                            stdout=log, stderr=subprocess.STDOUT, timeout=40)
            except subprocess.TimeoutExpired as error:
                raise RuntimeError(case["name"] + ": native checks timed out:\n" + log_path.read_text()) from error
            text = log_path.read_text()
            (target / "source-evidence.json").write_text(json.dumps(evidence, indent=2) + "\n")
            for capture in captures.iterdir():
                shutil.copy2(capture, target / capture.name)
            failures = ("CARDS_FAIL", "TypeError:", "ReferenceError:", "Binding loop detected",
                        "Error loading configuration", "Unable to assign [undefined]")
            if result.returncode or "CARDS_PASS" not in text or any(item in text for item in failures):
                raise RuntimeError(case["name"] + ":\n" + text)
            browser = (base / "browser.log").read_text().splitlines()
            assert browser == [fixture()["games"][0]["link"], fixture()["games"][2]["link"]], browser
            metrics = next(line.split("CARDS_METRICS ", 1)[1] for line in text.splitlines() if "CARDS_METRICS " in line)
            print(case["name"] + ": " + metrics)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", nargs="?", type=Path, default=Path("/tmp/sportray-card-review"))
    parser.add_argument("--logo-cache", type=Path)
    args = parser.parse_args()
    run(args.output.resolve(), args.logo_cache)
