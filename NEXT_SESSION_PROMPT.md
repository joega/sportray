Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
verify the direct physical ListView edge transitions for the Calendar week
stream on actual Omarchy, if and only if a supported host input path is
available.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and Quickshell
sources directly and record any material boundary deviation.

Verified current state:

- The source tree contains the completed bar-attached layout treatment. It
  measures dynamic panel content height, right-anchors header actions, hides
  inactive calendar tab-strip geometry, uses a reactive right-edge anchor proxy
  for horizontal right-section panels, and sets `KeyboardPanel.borderSpec` to
  `Border.none()` so the themed card has no popup outline. The installed
  `KeyboardPanel` and `Border` sources were inspected; this uses supported host
  properties and is not a compositor window-rule change.
- Source gates pass with 260 deterministic tests, summon-helper tests, plugin
  validation, real-import-path QML lint with established warnings, and
  `git diff --check`. The installed normal Git checkout remains at product
  commit `58a4d05f405b9fa29c924a0c264c0b431f9bde35`; its local geometry copy
  now also contains the borderless override for runtime inspection.
- The live panel was restarted and resummoned after the source change. One
  Quickshell instance remained healthy, shell ping returned `ok`, and a `grim`
  screenshot confirmed no outer panel outline. Bright orange lines visible in
  that screenshot are tiled terminal-window borders; the inner game-row border
  is an intentional control border. The panel was left open for inspection.
- Actual Omarchy cache-hit evidence remains valid: Calendar opened with known
  game/empty cells, close/reopen produced no calendar range curl, the selected
  day remained usable, one Quickshell process remained, and shell ping returned
  `ok`. The healthy cache was preserved, including pre-existing orphan files.
- Direct `MonthCalendar.weekList` `atYBeginning`/`atYEnd` callbacks remain
  unverified. This host has `wtype` only, AT-SPI reports `IsEnabled=false`, and
  PageUp/PageDown call `changeCalendarMonth()` directly rather than scrolling
  the ListView. Do not claim ListView edges from those keys.
- No provider, cache, polling, notification, settings, packaging, or remote
  state change is authorized for this unit.

Bounded outcome: if a supported pointer/axis or equivalent focused input route
is available, use it to scroll `MonthCalendar.weekList`, hit the physical start
and end edges once, and confirm each bounded month transition/recenter without
overflow, duplicate requests, or a second Quickshell process. If the supported
input route is unavailable, record the blocker and stop without a success
commit or a workaround such as `/dev/uinput`, synthetic PageUp/PageDown
substitution, or a plugin test hook. Do not delete, clear, or replay cache data.

Required checks on a pass: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, installed-checkout production validation,
and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
On actual Omarchy, restart/rescan only as authorized and required, confirm one
shell and ping `ok`, inspect fresh Quickshell logs, and manually exercise the
supported edge route. Preserve the known transient post-rescan summon race and
unrelated desktop-portal warning in the evidence.

Known risks: no supported pointer/axis injector may be installed;
`wtype` cannot establish ListView-edge evidence; pre-fix cache orphans remain
outside the manifest; live selected-day polling can update the projection while
Calendar is open; and ESPN remains an undocumented API. Request subagents only
for independent read-only source or log inspection that materially benefits
from parallelism.

When the gate passes, update `roadmap.md` with milestone status, evidence,
decision log, and a dated handoff; replace this prompt with the next
self-contained single-unit prompt; rerun the required checks; and create one
atomic Conventional Commit only when the complete accepted unit gate passes.
Do not push or change remote state.
