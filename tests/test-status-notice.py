#!/usr/bin/python3
"""Exercise byte-exact notice components with real installed Omarchy tokens.

Only the offscreen capture host is isolated; no desktop, provider, preferences,
installed plugin, or shell reload is involved.
"""
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
spec = importlib.util.spec_from_file_location("sportray_status_staging", ROOT / "tests/test-ui-presentation.py")
staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(staging)
OWNED = ("components/StatusNotice.qml", "components/LeagueStatus.qml", "components/StandingsStatus.qml", "model/NoticePresentation.js")

class StatusNoticeTests(unittest.TestCase):
    def test_exact_source_native_four_layout_notice_actions(self):
        for case in staging.CASES:
            with self.subTest(case=case["name"]), tempfile.TemporaryDirectory(prefix="sportray-notice-test-") as temporary:
                config, env, captures = staging.stage(Path(temporary), case)
                evidence = {}
                for name in OWNED:
                    original = (ROOT / name).read_bytes()
                    copied = (config / "plugin" / name).read_bytes()
                    self.assertEqual(original, copied, name + " was rewritten for testing")
                    evidence[name] = hashlib.sha256(original).hexdigest()
                harness = (ROOT / "tests/runtime/status-notice.qml").read_text().replace('"../../', '"plugin/')
                (config / "shell.qml").write_text(harness)
                result = subprocess.run(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                    env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=25)
                transcript = result.stdout.decode(errors="replace")
                destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
                if destination:
                    output = Path(destination) / case["name"]
                    output.mkdir(parents=True, exist_ok=True)
                    (output / "notice.log").write_text(transcript)
                    (output / "source-evidence.json").write_text(json.dumps(evidence, indent=2))
                    for path in captures.iterdir(): shutil.copy2(path, output / path.name)
                self.assertEqual(result.returncode, 0, transcript)
                self.assertIn("STATUS_NOTICE_PASS " + case["name"], transcript)
                for bad in ("STATUS_NOTICE_FAIL", "TypeError:", "ReferenceError:", "Binding loop detected", "Unable to assign [undefined]", "Error loading configuration"):
                    self.assertNotIn(bad, transcript, transcript)
                for name in ("notices.png", "notices-expanded.png"):
                    data = (captures / name).read_bytes()
                    self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
                    self.assertEqual(int.from_bytes(data[16:20], "big"), case["width"])

if __name__ == "__main__": unittest.main()
