#!/usr/bin/python3
"""Verify exact-production compact cards, action routes and team navigation.

Requires the installed Omarchy Qt UI modules and the public e78eddb baseline
commit. Rendering is offscreen with isolated HOME and no provider or desktop I/O.
"""
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("sportray_cards", ROOT / "tools/cards/capture.py")
CARDS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CARDS)


class GameCardPresentationTests(unittest.TestCase):
    def test_native_cards_actions_and_context(self):
        destination = os.environ.get("SPORTRAY_TEST_ARTIFACT_DIR")
        if destination:
            CARDS.run(Path(destination) / "cards")
        else:
            with tempfile.TemporaryDirectory(prefix="sportray-card-artifacts-") as temporary:
                CARDS.run(Path(temporary))


if __name__ == "__main__":
    unittest.main()
