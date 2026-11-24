#!/usr/bin/python3
"""Verify exact-source setup guidance, explicit league routes, and bounded team layout."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
ROOT=Path(__file__).resolve().parent.parent
SPEC=importlib.util.spec_from_file_location('sportray_setup_staging',ROOT/'tests/test-ui-presentation.py')
staging=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(staging)
EXACT=('components/TeamPicker.qml','components/SportsSettings.qml','components/SettingsHub.qml')
class SetupPresentationTests(unittest.TestCase):
    def test_four_layout_setup_guidance_preserves_preferences_and_keyboard_ownership(self):
        cases=[case for case in staging.CASES if not os.environ.get('SPORTRAY_SETUP_CASE') or case['name']==os.environ['SPORTRAY_SETUP_CASE']]
        self.assertTrue(cases)
        for case in cases:
            with self.subTest(case=case['name']),tempfile.TemporaryDirectory(prefix='sp-setup-') as temporary:
                config,env,captures=staging.stage(Path(temporary),case)
                evidence={}
                for name in EXACT:
                    source=(ROOT/name).read_bytes();target=config/'plugin'/name;target.write_bytes(source)
                    self.assertEqual(source,target.read_bytes());evidence[name]=hashlib.sha256(source).hexdigest()
                harness=(ROOT/'tests/runtime/setup-presentation.qml').read_text().replace('"../../','"plugin/')
                (config/'shell.qml').write_text(harness)
                result=subprocess.run(['/usr/bin/quickshell','-n','--no-color','-p',str(config)],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=35)
                transcript=result.stdout.decode(errors='replace')
                if os.environ.get('SPORTRAY_TEST_ARTIFACT_DIR'):
                    output=Path(os.environ['SPORTRAY_TEST_ARTIFACT_DIR'])/case['name'];output.mkdir(parents=True,exist_ok=True)
                    (output/'setup.log').write_text(transcript);(output/'source-evidence.json').write_text(json.dumps(evidence,indent=2))
                    for path in captures.iterdir():shutil.copy2(path,output/path.name)
                self.assertEqual(result.returncode,0,transcript)
                self.assertIn('SETUP_PRESENTATION_PASS '+case['name'],transcript)
                for bad in ['SETUP_PRESENTATION_FAIL','TypeError:','ReferenceError:','Binding loop detected','Error loading configuration','Unable to assign [undefined]']:
                    self.assertNotIn(bad,transcript,transcript)
                for name,digest in evidence.items():self.assertEqual(hashlib.sha256((ROOT/name).read_bytes()).hexdigest(),digest,'Source changed during native acceptance')
if __name__=='__main__':unittest.main()
