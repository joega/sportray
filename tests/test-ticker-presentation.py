#!/usr/bin/python3
"""Exercise exact production ticker rendering, motion and pointer routing in Qt.

The host is offscreen. This does not prove compositor edge-space reservation;
that separate live check belongs to the installed TicketOverlay.
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
spec = importlib.util.spec_from_file_location('sportray_ui_staging', ROOT / 'tests/test-ui-presentation.py')
staging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(staging)
EXACT = ('components/TicketStrip.qml', 'components/TicketOverlay.qml', 'model/TicketPresentation.js')


class TickerPresentationTests(unittest.TestCase):
    def test_exact_ticker_motion_and_pointer_routes_across_native_layouts(self):
        selected = os.environ.get('SPORTRAY_TICKER_CASE')
        cases = [case for case in staging.CASES if not selected or case['name'] == selected]
        self.assertTrue(cases, 'Unknown ticker case: ' + str(selected))
        for case in cases:
            with self.subTest(case=case['name']), tempfile.TemporaryDirectory(prefix='sportray-ticker-ui-') as tmp:
                base = Path(tmp)
                config, env, captures = staging.stage(base, case)
                evidence = []
                for name in EXACT:
                    source = ROOT / name
                    target = config / 'plugin' / name
                    # Preserve this entire component unchanged; no theme/import rewriting.
                    target.write_bytes(source.read_bytes())
                    digest = hashlib.sha256(source.read_bytes()).hexdigest()
                    self.assertEqual(target.read_bytes(), source.read_bytes())
                    evidence.append({'component': name, 'productionSha256': digest,
                                     'stagedSha256': hashlib.sha256(target.read_bytes()).hexdigest()})
                (captures / 'ticker-source-evidence.json').write_text(json.dumps(evidence, indent=2) + '\n')
                text = (ROOT / 'tests/runtime/ticker-presentation.qml').read_text()
                (config / 'shell.qml').write_text(text.replace('"../../components"', '"plugin/components"'))
                browser_log = base / 'browser.log'
                browser_log.write_text('')
                env['SPORTRAY_TICKER_BROWSER_LOG'] = str(browser_log)
                result = subprocess.run(['/usr/bin/quickshell', '-n', '--no-color', '-p', str(config)],
                                        env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=35)
                transcript = result.stdout.decode(errors='replace')
                destination = os.environ.get('SPORTRAY_TEST_ARTIFACT_DIR')
                if destination:
                    out = Path(destination) / ('ticker-' + case['name'])
                    out.mkdir(parents=True, exist_ok=True)
                    for p in captures.iterdir():
                        shutil.copy2(p, out / p.name)
                    (out / 'ticker.log').write_text(transcript)
                self.assertEqual(result.returncode, 0, transcript)
                self.assertIn('TICKER_PRESENTATION_PASS ' + case['name'], transcript)
                for token in ('TICKER_PRESENTATION_FAIL', 'TypeError:', 'ReferenceError:',
                              'Binding loop detected', 'Error loading configuration', 'Unable to assign [undefined]'):
                    self.assertNotIn(token, transcript, transcript)
                self.assertEqual(browser_log.read_text().splitlines(), ['https://www.nhl.com/gamecenter/2026020001'])
                for name in ('ticker-ready', 'ticker-paused', 'ticker-static', 'ticker-offline'):
                    image = (captures / (name + '.png')).read_bytes()
                    self.assertEqual(image[:8], b'\x89PNG\r\n\x1a\n')
                    self.assertEqual(int.from_bytes(image[16:20], 'big'), case['width'])


if __name__ == '__main__':
    unittest.main()
