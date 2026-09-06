#!/usr/bin/python3
"""Fixture-driven hostile-path coverage for the descriptor-bound state helper."""

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "scripts" / "settings-state-helper.py"
FIXTURE = json.loads((ROOT / "fixtures" / "settings-state-helper" / "cases.json").read_text())


class SettingsStateHelperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary.name) / "home"
        self.home.mkdir(mode=0o700)
        self.state_dir = self.home / ".local" / "state" / "omarchy" / "settings"
        self.state = self.state_dir / "sportray.json"
        self.environment = {"HOME": str(self.home), "PATH": os.environ.get("PATH", "")}

    def tearDown(self):
        self.temporary.cleanup()

    def helper(self, *args):
        return subprocess.run(["/usr/bin/python3", str(HELPER), *args], env=self.environment,
            text=True, capture_output=True, check=False)

    def install(self, data, mode=0o600):
        self.state_dir.mkdir(parents=True, mode=0o700, exist_ok=True)
        self.state.write_bytes(data)
        self.state.chmod(mode)

    def test_fixture_cases(self):
        normal = self.helper("read")
        self.assertEqual(normal.returncode, 2)
        self.assertTrue(self.state_dir.is_dir())
        self.assertEqual(stat.S_IMODE(self.state_dir.stat().st_mode), 0o700)

        self.install(FIXTURE["normal"].encode())
        normal = self.helper("read")
        self.assertEqual(normal.returncode, 0)
        self.assertEqual(normal.stdout, FIXTURE["normal"])

        self.install(FIXTURE["malformed"].encode())
        malformed = self.helper("read")
        self.assertEqual(malformed.returncode, 0)
        self.assertEqual(malformed.stdout, FIXTURE["malformed"])

        self.install(b"x" * FIXTURE["oversizedBytes"])
        oversized = self.helper("read")
        self.assertEqual(oversized.returncode, 4)

    def test_rejects_symlink_fifo_and_hardlink(self):
        self.state_dir.mkdir(parents=True, mode=0o700, exist_ok=True)
        target = self.home / "target"
        target.write_text(FIXTURE["normal"])
        self.state.symlink_to(target)
        self.assertEqual(self.helper("read").returncode, 4)
        self.assertEqual(self.helper("write", "--data", FIXTURE["write"]).returncode, 4)
        self.assertEqual(target.read_text(), FIXTURE["normal"])

        self.state.unlink()
        os.mkfifo(self.state, 0o600)
        self.assertEqual(self.helper("read").returncode, 4)
        self.assertEqual(self.helper("write", "--data", FIXTURE["write"]).returncode, 4)

        self.state.unlink()
        self.install(FIXTURE["normal"].encode())
        os.link(self.state, self.state_dir / "second-link")
        self.assertEqual(self.helper("read").returncode, 4)

    def test_write_is_private_atomic_and_descriptor_bound(self):
        completed = self.helper("write", "--data", FIXTURE["write"])
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(self.state.read_text(), FIXTURE["write"])
        info = self.state.stat()
        self.assertTrue(stat.S_ISREG(info.st_mode))
        self.assertEqual(info.st_nlink, 1)
        self.assertEqual(stat.S_IMODE(info.st_mode), 0o600)
        self.assertEqual(list(self.state_dir.glob(".sportray.*.tmp")), [])

        rejected = self.helper("write", "--data", "x" * FIXTURE["oversizedBytes"])
        self.assertEqual(rejected.returncode, 4)
        self.assertEqual(self.state.read_text(), FIXTURE["write"])


if __name__ == "__main__":
    unittest.main()
