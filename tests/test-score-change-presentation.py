#!/usr/bin/python3
"""Verify exact production score-update rendering and animation in native Qt."""
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
spec = importlib.util.spec_from_file_location("sportray_score_staging", ROOT / "tests/test-ui-presentation.py")
staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(staging)

class ScoreChangeTests(unittest.TestCase):
    def test_exact_score_changes_across_native_layouts(self):
        selected = os.environ.get("SPORTRAY_SCORE_CASE")
        cases = [case for case in staging.CASES if not selected or case["name"] == selected]
        self.assertTrue(cases, "Unknown score case")
        for case in cases:
            with self.subTest(case=case["name"]), tempfile.TemporaryDirectory(prefix="sp-score-") as temporary:
                base = Path(temporary)
                config, env, captures = staging.stage(base,case)
                evidence=[]
                for relative in ["components/GameRow.qml","model/ScoreChangePresentation.js"]:
                    production = (ROOT / relative).read_bytes()
                    self.assertEqual((config / "plugin" / relative).read_bytes(),production)
                    evidence.append({"component":relative,"sha256":hashlib.sha256(production).hexdigest(),"copiedByteForByte":True})
                (captures / "score-source-evidence.json").write_text(json.dumps(evidence,indent=2))
                source = (ROOT / "tests/runtime/score-change.qml").read_text()
                source = source.replace('"../../components"','"plugin/components"').replace('"../../model/','"plugin/model/')
                (config / "shell.qml").write_text(source)
                timed_out = False
                try:
                    result = subprocess.run(["/usr/bin/quickshell","-n","--no-color","-p",str(config)],
                        env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=20)
                    transcript = result.stdout.decode(errors="replace")
                except subprocess.TimeoutExpired as error:
                    timed_out = True
                    transcript = (error.stdout or b"").decode(errors="replace")
                if os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR"):
                    output=Path(os.environ["SPORTRAY_TEST_ARTIFACT_DIR"])/("score-"+case["name"])
                    output.mkdir(parents=True,exist_ok=True)
                    for path in captures.iterdir(): shutil.copy2(path,output/path.name)
                    (output/"score.log").write_text(transcript)
                self.assertFalse(timed_out,transcript)
                self.assertEqual(result.returncode,0,transcript)
                self.assertIn("SCORE_CHANGE_PASS "+case["name"],transcript,transcript)
                for forbidden in ["SCORE_CHANGE_FAIL","TypeError:","ReferenceError:","Binding loop detected","Error loading configuration","Unable to assign"]:
                    self.assertNotIn(forbidden,transcript,transcript)
                for name in ["score-baseline","score-away-update","score-home-update","score-reduced-motion"]:
                    image=(captures/(name+".png")).read_bytes()
                    self.assertEqual(image[:8],b"\x89PNG\r\n\x1a\n")
                    self.assertEqual(int.from_bytes(image[16:20],"big"),case["width"])

if __name__ == "__main__": unittest.main()
