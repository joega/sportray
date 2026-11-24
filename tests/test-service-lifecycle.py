#!/usr/bin/python3
"""Exercise real Quickshell owner lifetime without the desktop or network."""

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

# These replace helpers only inside each isolated config copy. No production
# injection switch, endpoint, notification helper or desktop shell is used.
SLEEPING_HELPER = '''import json, os, sys, time
from pathlib import Path
home = Path(os.environ["HOME"])
with (home / "helper-starts.jsonl").open("a") as output:
    output.write(json.dumps({"pid": os.getpid(), "kind": Path(__file__).name}) + "\\n")
time.sleep(30)
'''
SETTINGS_WRAPPER = '''import json, os, runpy, sys, time
from pathlib import Path
home = Path(os.environ["HOME"])
mode = json.loads((home / "helper-mode.json").read_text())
delay = mode.get(sys.argv[1], 0)
if delay:
    with (home / "helper-starts.jsonl").open("a") as output:
        output.write(json.dumps({"pid": os.getpid(), "kind": "settings-" + sys.argv[1]}) + "\\n")
    time.sleep(delay)
runpy.run_path(str(Path(__file__).with_name("settings-state-real.py")), run_name="__main__")
'''


class ServiceLifecycleTests(unittest.TestCase):
    def test_shared_workers_stop_and_settings_survive_reenable(self):
        self.exercise(stalled=False)

    def test_stalled_write_has_bounded_shutdown(self):
        self.exercise(stalled=True)

    def exercise(self, stalled):
        with tempfile.TemporaryDirectory(prefix="sportray-lifecycle-test-") as temporary:
            base = Path(temporary)
            home = base / "home"
            home.mkdir(mode=0o700)
            runtime = base / "runtime"
            runtime.mkdir(mode=0o700)
            config = base / "config"
            config.mkdir()
            for name in ("services", "model", "providers", "scripts"):
                shutil.copytree(ROOT / name, config / name)
            harness = (ROOT / "tests/runtime/service-lifecycle.qml").read_text()
            # The fixture is lintable in-tree, then relocates beside the copied
            # production services for this isolated real-Quickshell process.
            (config / "shell.qml").write_text(harness.replace(
                'import "../../services" as Services', 'import "services" as Services'))
            scripts = config / "scripts"
            for name in ("provider-transport-helper.py", "logo-image-helper.py"):
                (scripts / name).write_text(SLEEPING_HELPER)
            shutil.copy2(scripts / "settings-state-helper.py", scripts / "settings-state-real.py")
            (scripts / "settings-state-helper.py").write_text(SETTINGS_WRAPPER)
            (home / "control.json").write_text(json.dumps({"sequence": 0, "action": "inert"}))
            (home / "helper-mode.json").write_text("{}")
            environment = dict(os.environ)
            environment.update({
                "HOME": str(home), "XDG_RUNTIME_DIR": str(runtime),
                "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_CACHE_HOME": str(home / ".cache"),
                "XDG_STATE_HOME": str(home / ".local/state"),
                "QT_QPA_PLATFORM": "offscreen", "QT_QPA_PLATFORMTHEME": "",
                "QT_QUICK_CONTROLS_STYLE": "Basic", "QS_DISABLE_FILE_WATCHER": "1",
            })
            for name in ("DISPLAY", "WAYLAND_DISPLAY", "QS_CONFIG_NAME", "QS_MANIFEST"):
                environment.pop(name, None)
            process = subprocess.Popen(["/usr/bin/quickshell", "-n", "--no-color", "-p", str(config)],
                env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            self.transcript = bytearray()
            self.pending = b""
            self.markers = []
            self.sequence = 0
            self.tracked = {}
            try:
                with selectors.DefaultSelector() as selector:
                    selector.register(process.stdout, selectors.EVENT_READ)
                    self.selector = selector
                    self.process = process
                    self.home = home
                    self.wait_marker("inert")
                    self.assertFalse((home / ".local/state/omarchy/settings").exists())
                    self.assert_no_children()
                    self.command("acquire", "ready")
                    self.command("release-one", "one-retained")
                    self.command("work", "work-started")
                    self.wait_helpers({"provider-transport-helper.py", "logo-image-helper.py"})
                    self.mode(write=30 if stalled else 0.2)
                    start = time.monotonic()
                    self.command("release-stall" if stalled else "release-persist", "workers-stopped")
                    self.wait_marker("drained")
                    self.assertLess(time.monotonic() - start, 4.5)
                    self.assert_helpers_stopped()
                    self.assert_no_children()
                    state = json.loads((home / ".local/state/omarchy/settings/sportray.json").read_text())
                    self.assertEqual(state["ticker"]["speed"], "normal" if stalled else "fast")
                    if not stalled:
                        self.mode()
                        self.command("acquire", "ready")
                        self.command("release-one", "one-retained")
                        self.mode(write=0.2)
                        self.command("drain-reacquire", "reacquired")
                        self.mode(read=0.2, write=0.2)
                        self.command("release-read", "workers-stopped")
                        self.wait_marker("read-drained")
                        self.assert_helpers_stopped()
                        self.assert_no_children()
                        state = json.loads((home / ".local/state/omarchy/settings/sportray.json").read_text())
                        self.assertEqual(state["ticker"]["speed"], "normal")
                        self.mode()
                    self.command("rapid", "rapid-stopped")
                    self.assert_helpers_stopped()
                    self.assert_no_children()
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=2)
                    except subprocess.TimeoutExpired:
                        process.kill()
                process.wait(timeout=2)
                process.stdout.close()

    def mode(self, **values):
        (self.home / "helper-mode.json").write_text(json.dumps(values))

    def command(self, action, expected):
        self.sequence += 1
        path = self.home / "control.json"
        temporary = path.with_suffix(".next")
        temporary.write_text(json.dumps({"sequence": self.sequence, "action": action}))
        temporary.replace(path)
        self.wait_marker(expected)

    def read_output(self):
        if not self.selector.select(timeout=0.02):
            return
        chunk = os.read(self.process.stdout.fileno(), 65536)
        self.assertTrue(chunk, self.transcript.decode(errors="replace"))
        self.transcript.extend(chunk)
        self.assertLess(len(self.transcript), 1024 * 1024)
        self.pending += chunk
        while b"\n" in self.pending:
            line, self.pending = self.pending.split(b"\n", 1)
            self.assertNotIn(b"LIFECYCLE_TEST FAIL", line, self.transcript.decode(errors="replace"))
            for forbidden in (b"TypeError:", b"ReferenceError:", b"Binding loop detected", b"Error loading configuration"):
                self.assertNotIn(forbidden, line, self.transcript.decode(errors="replace"))
            marker = line.partition(b"LIFECYCLE_TEST ")[2].strip().decode()
            if marker:
                self.markers.append(marker)

    def wait_marker(self, expected):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if expected in self.markers:
                self.markers.remove(expected)
                return
            self.read_output()
        self.fail("Missing " + expected + ":\n" + self.transcript.decode(errors="replace"))

    def collect_helpers(self):
        log = self.home / "helper-starts.jsonl"
        entries = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        for entry in entries:
            pid = entry["pid"]
            if pid in self.tracked:
                continue
            try:
                stat = Path(f"/proc/{pid}/stat").read_bytes().rsplit(b")", 1)[1].split()
                self.tracked[pid] = stat[19]
            except FileNotFoundError:
                pass
        return entries

    def wait_helpers(self, kinds):
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            entries = self.collect_helpers()
            if kinds.issubset({entry["kind"] for entry in entries}):
                return
            self.read_output()
        self.fail("Fixture helpers did not start: " + str(entries))

    def assert_helpers_stopped(self):
        self.collect_helpers()
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            live = []
            for pid, start in self.tracked.items():
                try:
                    fields = Path(f"/proc/{pid}/stat").read_bytes().rsplit(b")", 1)[1].split()
                    if fields[19] == start:
                        live.append(pid)
                except FileNotFoundError:
                    pass
            if not live:
                return
            self.read_output()
        self.fail("Owned fixture helpers survive teardown: " + str(live))

    def assert_no_children(self):
        deadline = time.monotonic() + 2
        while time.monotonic() < deadline:
            children = Path(f"/proc/{self.process.pid}/task/{self.process.pid}/children").read_text().strip()
            if not children:
                return
            self.read_output()
        self.fail("Isolated shell retains child processes: " + children)


if __name__ == "__main__":
    unittest.main()
