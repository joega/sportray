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

- The current tray presentation is complete: both horizontal and vertical
  branches use `BarIconButton`; an accent dot marks an upcoming favorite and an
  urgent dot marks a live favorite. Countdown labels are not rendered in the
  tray; bounded score/start details remain in the tooltip and panel.
- `BarPresentation.js` still returns the pure countdown projection for
  compatibility but does not promote its changing label into tray text. The
  full fixture-driven suite passes with 185 tests.
- The checkout passes `omarchy plugin validate "$PWD"`, real-import-path
  `qmllint`, and `git diff --check`. README and the latest roadmap handoff
  document the icon/status-indicator behavior.
- Actual Omarchy remains `4.0.0-1` with Quickshell `0.3.0`, revision
  `28771c7c74b42e20afca0b1b63980cb46515537c`. After the supported
  `omarchy-restart-shell` boundary, one instance (`p66hhg1akt`, PID 801169)
  loaded the linked plugin, `shell ping` returned `ok`, geometry showed a
  visible 27x26 Sportray slot, and a screenshot showed no countdown text. A
  rescan-only reload can retain the old active component until a shell restart;
  no Sportray QML/load/binding-loop error was observed.
- The external helper remains outside the plugin runtime path. It sends the
  exact summon IPC, accepts only `ok`, retries unsuccessful results at most
  five times with 250 ms spacing, never calls `hide`, and has a deterministic
  shell test. No repository or user-configured post-rescan summon caller is
  currently known.

Bounded outcome:

- If a real client caller now exists, integrate the existing helper at that
  caller without adding a host/plugin API or changing hide behavior.
- If installed Omarchy/Quickshell changed, inspect the new source and reproduce
  rescan, immediate summon, delayed summon, and hide before deciding whether
  the helper remains necessary.
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
