#!/usr/bin/python3
"""Exercise the installed real Quickshell Io boundary in an isolated test home."""

import json
import os
from pathlib import Path
import selectors
import shutil
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parent.parent


class SettingsStoreRuntimeTests(unittest.TestCase):
    def test_metadata_watcher_never_loads_contents_and_reloads_helper(self):
        with tempfile.TemporaryDirectory(prefix="sportray-settings-test-") as temporary:
            isolated = Path(temporary)
            fixture_home = isolated / "home"
            state_dir = fixture_home / ".local/state/omarchy/settings"
            # Parent exists, state file does not. No owner state is copied.
            state_dir.mkdir(parents=True, mode=0o700)
            state_file = state_dir / "sportray.json"
            runtime_dir = isolated / "runtime"
            runtime_dir.mkdir(mode=0o700)
            config_dir = isolated / "config"
            (config_dir / "services").mkdir(parents=True)
            (config_dir / "scripts").mkdir()
            shutil.copy2(ROOT / "tests/runtime/settings-store.qml", config_dir / "shell.qml")
            shutil.copy2(ROOT / "services/SettingsStore.qml", config_dir / "services/SettingsStore.qml")
            shutil.copy2(ROOT / "scripts/settings-state-helper.py",
                config_dir / "scripts/settings-state-helper.py")
            shutil.copytree(ROOT / "model", config_dir / "model")
            environment = dict(os.environ)
            environment.update({
                "HOME": str(fixture_home), "XDG_RUNTIME_DIR": str(runtime_dir),
                "XDG_CONFIG_HOME": str(fixture_home / ".config"),
                "XDG_CACHE_HOME": str(fixture_home / ".cache"),
                "XDG_STATE_HOME": str(fixture_home / ".local/state"),
                "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QS_DISABLE_FILE_WATCHER": "1",
            })
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "QS_CONFIG_NAME", "QS_MANIFEST"):
                environment.pop(name, None)
            command = ["/usr/bin/quickshell", "-n", "--no-color", "-p",
                str(config_dir)]
            process = subprocess.Popen(command, env=environment,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            try:
                self.observe(process, state_file, environment)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()
                process.wait(timeout=2)
                process.stdout.close()

    def observe(self, process, state_file, environment):
        transcript = bytearray()
        pending = b""
        stages = []
        deadline = time.monotonic() + 12
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            while time.monotonic() < deadline:
                if not selector.select(timeout=0.1):
                    continue
                chunk = os.read(process.stdout.fileno(), 65536)
                if not chunk:
                    break
                transcript.extend(chunk)
                self.assertLess(len(transcript), 1024 * 1024, "test output exceeded cap")
                pending += chunk
                while b"\n" in pending:
                    line, pending = pending.split(b"\n", 1)
                    self.assertNotIn(b"SETTINGS_TEST FAIL", line, transcript.decode(errors="replace"))
                    marker = line.partition(b"SETTINGS_TEST ")[2].strip().decode()
                    if marker not in ("created", "atomic", "changed", "PASS"):
                        continue
                    stages.append(marker)
                    if marker == "PASS":
                        self.assertEqual(stages, ["created", "atomic", "changed", "PASS"])
                        return
                    previous = state_file.read_bytes()
                    state = json.loads(previous)
                    state["ticker"]["speed"] = {
                        "created": "slow", "atomic": "fast", "changed": "normal"
                    }[marker]
                    raw = json.dumps(state) + "\n"
                    if marker == "atomic":
                        # Slow -> fast has equal length. Do not truncate and
                        # briefly expose an empty document to the live watcher.
                        payload = raw.encode()
                        self.assertEqual(len(payload), len(previous))
                        fd = os.open(state_file, os.O_WRONLY)
                        try:
                            self.assertEqual(os.pwrite(fd, payload, 0), len(payload))
                            os.fsync(fd)
                        finally:
                            os.close(fd)
                    else:
                        # Exercise real descriptor-bound atomic publication.
                        result = subprocess.run(["/usr/bin/python3", "-I", "-S",
                            str(ROOT / "scripts/settings-state-helper.py"),
                            "write", "--data", raw], env=environment, timeout=2,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                        self.assertEqual(result.returncode, 0)
        self.fail("real SettingsStore test incomplete:\n" + transcript.decode(errors="replace"))


if __name__ == "__main__":
    unittest.main()
