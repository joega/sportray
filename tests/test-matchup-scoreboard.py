#!/usr/bin/python3
"""Render the exact shared scoreboard at normal, narrow and larger text sizes."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("scoreboard_staging", ROOT / "tests/test-ui-presentation.py")
STAGING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(STAGING)
EXACT = ("MatchupScoreboard.qml", "PresentationTokens.qml", "TeamScheduleLink.qml")


class MatchupScoreboardTests(unittest.TestCase):
    def test_real_scoreboard_bounds_state_and_canonical_routes(self):
        cases = list(STAGING.CASES) + [{"name": "narrow-large", "theme": "catppuccin-latte", "width": 320, "fontSize": 16}]
        for case in cases:
            with self.subTest(case=case["name"]), tempfile.TemporaryDirectory(prefix="sp-matchup-") as temporary:
                base = Path(temporary)
                config, env, captures = STAGING.stage(base, case)
                evidence = {}
                for name in EXACT:
                    source = ROOT / "components" / name
                    target = config / "plugin/components" / name
                    shutil.copy2(source, target)
                    self.assertEqual(source.read_bytes(), target.read_bytes())
                    evidence[name] = hashlib.sha256(source.read_bytes()).hexdigest()
                harness = (ROOT / "tests/runtime/matchup-scoreboard.qml").read_text().replace('"../../', '"plugin/')
                (config / "shell.qml").write_text(harness)
                result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)], env=env,
                                        capture_output=True, timeout=30)
                transcript = (result.stdout + result.stderr).decode(errors="replace")
                destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
                if destination:
                    output = Path(destination) / case["name"]
                    output.mkdir(parents=True, exist_ok=True)
                    (output / "scoreboard.log").write_text(transcript)
                    (output / "source-evidence.json").write_text(json.dumps(evidence, indent=2))
                    for capture in captures.iterdir():
                        shutil.copy2(capture, output / capture.name)
                self.assertEqual(result.returncode, 0, transcript)
                self.assertIn("MATCHUP_SCOREBOARD_PASS", transcript, transcript)
                for forbidden in ("MATCHUP_SCOREBOARD_FAIL", "TypeError:", "ReferenceError:", "Binding loop detected", "Error loading configuration", "Unable to assign"):
                    self.assertNotIn(forbidden, transcript, transcript)
                for name, digest in evidence.items():
                    self.assertEqual(hashlib.sha256((ROOT / "components" / name).read_bytes()).hexdigest(), digest)


if __name__ == "__main__":
    unittest.main()
