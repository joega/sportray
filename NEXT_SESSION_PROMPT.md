Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: revisit the post-rescan Sportray summon mitigation only after either a
concrete existing client caller is introduced or an installed Omarchy/
Quickshell update changes the widget-registration/readiness contract.

Before any edit, read `AGENTS.md`, `README.md`, the intentionally absent
`docs/upstream-contract.md`, `roadmap.md`, and the latest handoff. Inspect git
status, branch, recent commits, the helper, its test, `manifest.json`,
`BarWidget.qml`, and the installed widget registry, bar-slot, rescan, and IPC
sources. Preserve unrelated changes and do not rely on prior chat history.

Verified current state:

- Omarchy is `4.0.0-1`; Quickshell is `0.3.0`, revision
  `28771c7c74b42e20afca0b1b63980cb46515537c`.
- The installed host still creates bar-widget entry-point components
  asynchronously, exposes live `ModuleSlot.activeItem` only after loading,
  and has no summon readiness queue or retry. The retained log contains the
  host warning `summon: no live bar widget for:
  io.github.joega.sportray`.
- No existing repository or user-configured post-rescan summon caller was
  found. Normal README usage remains explicit `toggle`/`hide` IPC.
- `scripts/summon-sportray-after-rescan.sh` is an external helper. It sends
  exactly `omarchy-shell shell summon io.github.joega.sportray '{}'`, accepts
  only stdout `ok`, retries only unsuccessful results, uses five total
  attempts with 250 ms spacing, and exits nonzero after the bound. It never
  calls rescan or hide and is outside the plugin manifest/runtime path.
- `tests/test-summon-helper.sh` covers exact arguments, success after retry,
  the five-attempt bound, concise failure, and no hide call. The complete JS
  suite remains at 185 tests. No Sportray production QML, providers,
  polling, settings, or new IPC route changed.
- Actual Omarchy instance `g8bgirc9kt` (PID 761056) passed rescan, helper
  summon, normal hide, delayed summon, delayed hide, enabled-plugin listing,
  and visible `133x26` right-section geometry. The fresh log had normal
  Sportray activity without an exception, QML load failure, binding-loop
  warning, or rotation error. This does not prove an upstream host fix.

Bounded outcome:

- If a concrete client caller now exists, integrate the existing helper at
  that caller without adding a host/plugin API or changing hide behavior.
- If the installed host changed, inspect the new source and reproduce rescan,
  immediate summon, delayed summon, and hide before deciding whether the
  helper remains necessary.
- If neither prerequisite exists, record that fact in `roadmap.md` and stop
  without speculative runtime changes or repeated race testing.

Required checks if the unit reopens:

- Run `bash -n scripts/summon-sportray-after-rescan.sh
  tests/test-summon-helper.sh` and `tests/test-summon-helper.sh`; use
  `shellcheck` too if it is installed.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command
  over every QML file, and `git diff --check`.
- On actual Omarchy, confirm one running shell, rescan followed by the
  bounded helper or the new caller, delayed summon/hide, live geometry, and a
  fresh Quickshell log. Do not claim an upstream fix from one timing-sensitive
  success.
- Do not add a plugin-side timer/retry, new IPC route, provider field,
  setting, polling cadence, or unverified upstream API. Keep the workaround
  outside Sportray's runtime path unless a concrete caller integration is
  proven necessary.

Stop condition: stop when the prerequisite is absent and the blocker is
recorded, or when one concrete caller/host change has been verified with all
gates, roadmap evidence, this prompt, and one atomic Conventional Commit.
Never push, tag, publish, or change remote state. Request subagents only for
independent read-only upstream/runtime reconnaissance; do not delegate edits
to shared source, roadmap, or handoff files.
