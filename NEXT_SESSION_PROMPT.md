Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: revisit the external post-rescan Sportray summon helper only after a
concrete existing client caller is introduced or an installed Omarchy/
Quickshell update changes the widget-registration/readiness contract.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and the latest handoff. The
`docs/upstream-contract.md` path is intentionally absent from this checkout;
verify current Omarchy/Quickshell boundaries against installed sources instead.
Inspect `git status`, the current branch, recent commits, the latest handoff,
`scripts/summon-sportray-after-rescan.sh`, its test, `manifest.json`, and
`BarWidget.qml`. Preserve unrelated changes and do not rely on prior chat
history.

Verified current state:

- The scoreboard game-card footer now renders status/start metadata on one
  line and `At <venue>` on a separate bounded two-line text item. Its card
  height measures the complete footer column, while the ESPN/NHL.com source
  action remains in a separate trailing column centered across the footer.
  The change is limited to `components/GameRow.qml` and its source/layout
  assertions; providers, normalized models, polling, settings, notifications,
  and runtime IPC are unchanged.
- The full fixture-driven suite passes with 185 tests. The checkout passes
  `omarchy plugin validate "$PWD"`, real-import-path `qmllint`, helper tests,
  and `git diff --check`.
- Actual Omarchy remains `4.0.0-1` with Quickshell `0.3.0`, revision
  `28771c7c74b42e20afca0b1b63980cb46515537`. After the supported shell restart,
  one instance (`c0240dfe8c8e8a421e1f8db23a03fc60`, PID 806461) loaded the
  linked plugin, `shell ping` returned `ok`, and a screenshot showed
  `At LoanDepot Park` fully visible with `ESPN` still separate. The fresh log
  has normal provider/cache activity and no Sportray exception, QML/load, or
  binding-loop warning. A rescan-only reload can retain the old active
  component until a shell restart.
- The external helper remains outside the plugin runtime path. It sends the
  exact summon IPC, accepts only `ok`, retries unsuccessful results at most
  five times with 250 ms spacing, never calls `hide`, and has deterministic
  shell coverage. No repository or user-configured post-rescan summon caller
  is currently known.

Bounded outcome:

- If a real client caller now exists, integrate the existing helper at that
  caller without adding a host/plugin API or changing hide behavior.
- If installed Omarchy/Quickshell changed, inspect the new source and
  reproduce rescan, immediate summon, delayed summon, and hide before deciding
  whether the helper remains necessary.
- If neither prerequisite exists, record the unchanged blocker in
  `roadmap.md` and stop without speculative runtime changes, repeated race
  testing, or a success commit.

Required checks if the unit reopens:

- Run `bash -n scripts/summon-sportray-after-rescan.sh`,
  `tests/test-summon-helper.sh`, and `shellcheck` if installed.
- Run `NODE_BIN=/home/joeg/.local/share/mise/installs/node/26.7.0/bin/node
  tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command
  over every QML file, and `git diff --check`.
- On actual Omarchy, confirm one running shell, rescan plus the bounded helper
  or the new caller, delayed summon/hide, live geometry, and a fresh Quickshell
  log. Do not claim an upstream fix from one timing-sensitive success.
- Do not add a plugin-side timer/retry, new IPC route, provider field,
  settings field, polling cadence, or unverified upstream API. Keep the helper
  outside Sportray’s runtime path unless a concrete caller integration is
  proven necessary.

Stop when the prerequisite is absent and the blocker is recorded, or when one
concrete caller/host change is verified with all gates. Before finishing,
update `roadmap.md`, replace this prompt with the next self-contained prompt,
and create one atomic Conventional Commit-style commit only when the gate
passes. Never push, tag, publish, or change remote state. Request subagents
only for independent read-only upstream/runtime reconnaissance; do not
delegate edits to shared source, roadmap, or handoff files.
