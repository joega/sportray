#!/usr/bin/python3
"""Exercise exact native agenda layout and canonical focus without desktop/network I/O."""
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
SPEC = importlib.util.spec_from_file_location("sportray_agenda_staging", ROOT / "tests/test-ui-presentation.py")
staging = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(staging)
EXACT = ("components/UpcomingCalendar.qml", "components/AgendaGameRow.qml", "components/NextGameCard.qml",
         "components/MatchupScoreboard.qml", "components/PresentationTokens.qml", "model/AgendaPresentation.js")

def fixture():
    sample = json.loads((ROOT / "tools/readme/sample-state.json").read_text())
    game = next(g for g in sample["games"] if g["league"] == "nhl")
    entries = []
    for index, day in enumerate(["2026-11-25", "2026-11-27", "2026-11-30", "2026-12-02", "2026-12-07", "2026-12-15", "2026-12-28"]):
        item = json.loads(json.dumps(game))
        item.update(id="nhl:agenda-"+str(index), providerGameId="agenda-"+str(index), status="scheduled",
                    startTime=day+"T23:30:00Z", awayScore=None, homeScore=None)
        if index == 5: item["awayTeam"]["shortName"] = "A very long opponent name that must wrap without crossing the time column"
        entries.append({"game": item, "dateKey": day, "timeKnown": index != 2})
    global_entries = []
    for index, source in enumerate(sample["games"][:4]):
        item = json.loads(json.dumps(source))
        item.update(id=item["league"]+":global-agenda-"+str(index), startTime="2026-11-24T23:30:00Z")
        if index == 3: item.update(status="scheduled", awayScore=None, homeScore=None)
        global_entries.append({"game":item,"dateKey":"2026-11-24","timeKnown":index!=3})
    return {"team": entries, "global": global_entries}

class AgendaPresentationTests(unittest.TestCase):
    def test_native_layouts_preserve_grouped_agenda_actions_and_context(self):
        layouts = list(staging.CASES) + [dict(staging.CASES[2], name="narrow-large", fontSize=16)]
        cases = [case for case in layouts if not os.environ.get("SPORTRAY_AGENDA_CASE") or case["name"] == os.environ["SPORTRAY_AGENDA_CASE"]]
        self.assertTrue(cases)
        for case in cases:
            with self.subTest(case=case["name"]), tempfile.TemporaryDirectory(prefix="sp-agenda-") as temporary:
                config, env, captures = staging.stage(Path(temporary),case)
                evidence = {}
                for name in EXACT:
                    original = (ROOT/name).read_bytes()
                    target = config/"plugin"/name
                    target.write_bytes(original)
                    self.assertEqual(original,target.read_bytes())
                    evidence[name] = hashlib.sha256(original).hexdigest()
                (config/"agenda-fixture.json").write_text(json.dumps(fixture()))
                harness = (ROOT/"tests/runtime/agenda-presentation.qml").read_text().replace('"../../','"plugin/')
                (config/"shell.qml").write_text(harness)
                result = subprocess.run(["/usr/bin/quickshell","-n","--no-color","-p",str(config)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=35)
                transcript = result.stdout.decode(errors="replace")
                destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
                if destination:
                    output=Path(destination)/case["name"];output.mkdir(parents=True,exist_ok=True)
                    (output/"agenda.log").write_text(transcript)
                    (output/"agenda-source-evidence.json").write_text(json.dumps(evidence,indent=2))
                    for path in captures.iterdir():shutil.copy2(path,output/path.name)
                self.assertEqual(result.returncode,0,transcript)
                self.assertIn("AGENDA_PRESENTATION_PASS "+case["name"],transcript)
                for bad in ["AGENDA_PRESENTATION_FAIL","TypeError:","ReferenceError:","Binding loop detected","Error loading configuration","Unable to assign [undefined]"]:
                    self.assertNotIn(bad,transcript,transcript)
                for name,digest in evidence.items():
                    self.assertEqual(hashlib.sha256((ROOT/name).read_bytes()).hexdigest(),digest,
                                     "Production source changed during agenda acceptance: "+name)

if __name__ == "__main__":unittest.main()
