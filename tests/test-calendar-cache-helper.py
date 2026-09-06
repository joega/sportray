#!/usr/bin/python3
"""Fixture-driven hostile-path coverage for the calendar cache helper."""

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "scripts" / "calendar-cache-helper.py"
FIXTURE = json.loads((ROOT / "fixtures" / "calendar-cache-helper" / "cases.json").read_text())


class CalendarCacheHelperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary.name) / "home"
        self.home.mkdir(mode=0o700)
        self.cache_dir = self.home / ".cache" / "sportray" / "calendar"
        self.day_name = "nhl:2026-09-06.json"
        self.day = self.cache_dir / self.day_name
        self.environment = {"HOME": str(self.home), "PATH": os.environ.get("PATH", "")}

    def tearDown(self):
        self.temporary.cleanup()

    def helper(self, *args, data=None):
        return subprocess.run(["/usr/bin/python3", "-I", "-S", str(HELPER), *args],
            env=self.environment, input=data, text=False, capture_output=True, check=False)

    def install(self, data, mode=0o600):
        self.cache_dir.mkdir(parents=True, mode=0o700, exist_ok=True)
        self.day.write_bytes(data)
        self.day.chmod(mode)

    def test_fixture_cases(self):
        missing = self.helper("read", "manifest.json")
        self.assertEqual(missing.returncode, 2)
        self.assertEqual(stat.S_IMODE(self.cache_dir.stat().st_mode), 0o700)

        self.install(FIXTURE["normal"].encode())
        normal = self.helper("read", self.day_name)
        self.assertEqual(normal.returncode, 0)
        self.assertEqual(normal.stdout.decode(), FIXTURE["normal"])

        self.install(b"not json")
        malformed = self.helper("read", self.day_name)
        self.assertEqual(malformed.returncode, 0)
        self.assertEqual(malformed.stdout, b"not json")

        self.install(b"x" * FIXTURE["oversizedBytes"])
        self.assertEqual(self.helper("read", self.day_name).returncode, 4)

    def test_rejects_hostile_files_without_touching_targets(self):
        self.cache_dir.mkdir(parents=True, mode=0o700, exist_ok=True)
        target = self.home / "victim"
        target.write_text(FIXTURE["normal"])
        self.day.symlink_to(target)
        self.assertEqual(self.helper("read", self.day_name).returncode, 4)
        self.assertEqual(self.helper("write", self.day_name, data=FIXTURE["write"].encode() + b"\0").returncode, 4)
        self.assertEqual(self.helper("remove", self.day_name).returncode, 4)
        self.assertEqual(target.read_text(), FIXTURE["normal"])

        self.day.unlink()
        os.mkfifo(self.day, 0o600)
        self.assertEqual(self.helper("read", self.day_name).returncode, 4)
        self.assertEqual(self.helper("write", self.day_name, data=FIXTURE["write"].encode() + b"\0").returncode, 4)
        self.assertEqual(self.helper("remove", self.day_name).returncode, 4)

        self.day.unlink()
        self.install(FIXTURE["normal"].encode())
        os.link(self.day, self.cache_dir / "second-link")
        self.assertEqual(self.helper("read", self.day_name).returncode, 4)
        self.assertEqual(self.helper("remove", self.day_name).returncode, 4)

    def test_private_atomic_write_and_descriptor_bound_removal(self):
        completed = self.helper("write", self.day_name, data=FIXTURE["write"].encode() + b"\0")
        self.assertEqual(completed.returncode, 0, completed.stderr.decode())
        self.assertEqual(self.day.read_text(), FIXTURE["write"])
        info = self.day.stat()
        self.assertTrue(stat.S_ISREG(info.st_mode))
        self.assertEqual(info.st_nlink, 1)
        self.assertEqual(stat.S_IMODE(info.st_mode), 0o600)
        self.assertEqual(list(self.cache_dir.glob(".*.tmp")), [])

        self.assertEqual(self.helper("remove", self.day_name).returncode, 0)
        self.assertFalse(self.day.exists())
        self.assertEqual(self.helper("remove", self.day_name).returncode, 2)

        rejected = self.helper("write", self.day_name,
            data=b"x" * FIXTURE["oversizedBytes"] + b"\0")
        self.assertEqual(rejected.returncode, 4)

    def test_rejects_cache_parent_symlink_and_invalid_names(self):
        target = self.home / "target-cache"
        target.mkdir(mode=0o700)
        (self.home / ".cache").symlink_to(target, target_is_directory=True)
        self.assertEqual(self.helper("read", "manifest.json").returncode, 4)
        self.assertEqual(self.helper("read", "../victim").returncode, 4)


if __name__ == "__main__":
    unittest.main()
