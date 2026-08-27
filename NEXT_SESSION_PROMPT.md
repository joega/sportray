Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
verify direct physical `MonthCalendar.weekList` edge transitions on actual
Omarchy, if and only if a supported pointer/axis or equivalent focused input
route is available.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and
Quickshell sources directly and record any material boundary deviation.

Verified current state:

- The calendar startup projection fix is complete. `FetchService.qml` exposes
  disk-cache readiness and increments `calendarStatesRevision` whenever the
  existing `refreshCalendarStates()` path rebuilds calendar state.
- `Panel.qml` consumes that revision, refreshes the existing projection when
  Calendar opens, and passes cache-loading state to `MonthCalendar.qml`.
  `MonthCalendar.qml` shows `Loading...` while the durable cache is not ready,
  retains the existing rehydration progress notice, and reserves `Unknown`
  for dates not verified after loading or a partial refresh.
- No second fetch owner, provider parser, timer, or cache owner was added. The
  existing range request path now computes the durable 30-days-past through
  30-days-future window, excludes cached dates, and submits only missing
  contiguous ranges. A completely empty 61-day window is split into 42 and 19
  days before the existing seven-day provider chunking. Provider admission,
  selected-day-only leagues, durable cache bounds, and notification/settings
  ownership are unchanged.
- The deterministic JavaScript suite passes with 261 tests. The notification
  helper test now stubs the installed helper's direct `busctl` dependency;
  this is test-boundary maintenance only and does not change plugin runtime
  behavior. Summon-helper tests, `git diff --check`, source and installed
  plugin validation, and all-file real-import-path QML lint pass with the
  established standalone warnings.
- Actual Omarchy remains healthy with one Quickshell instance and shell ping
  `ok`. Fresh logs show normal provider/cache activity, no Sportray error,
  exception, binding-loop, or QML-load warning, and retained calendar coverage
  of `305/305`. The installed normal Git checkout is at `58a4d05` with local
  geometry edits plus the prior calendar logic; it has not been changed for
  this source unit. Do not overwrite those local geometry edits.
- The current calendar cache is healthy. Existing pre-fix orphan files outside
  the manifest remain intentionally preserved and must not be deleted, cleared,
  or replayed.
- Direct `weekList` `atYBeginning` and `atYEnd` callbacks remain unverified.
  This host has no supported pointer/axis injector, AT-SPI reports
  `IsEnabled=false`, and `wtype` provides keyboard input only. PageUp/PageDown
  are handled by Sportray's month command and do not establish ListView-edge
  evidence. A trial `wtype c` input landed in the terminal, not the widget.

Bounded outcome: if a supported input route is available, scroll the calendar
week stream to its physical beginning and end once, confirm each bounded month
transition/recenter, and verify there is no overflow, duplicate request, or
second Quickshell process. If no supported route is available, record the
blocker and stop without a success commit or a workaround such as
`/dev/uinput`, synthetic PageUp/PageDown substitution, or a plugin test hook.

Required checks on a pass: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, installed-checkout production validation,
and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
On actual Omarchy, restart/rescan only as authorized and required, confirm one
shell and ping `ok`, inspect fresh Quickshell logs, and manually exercise the
supported edge route. Preserve the known transient post-rescan summon race
and unrelated desktop-portal warning in the evidence.

Known risks: no supported pointer/axis injector may be installed; the healthy
cache contains pre-fix orphan files outside the manifest; the deliberately
incomplete-cache live burst has not been run; live selected-day polling can
update the projection while Calendar is open; and ESPN remains an undocumented
API. Request subagents only for independent read-only source or log inspection
that materially benefits from parallelism.

When the gate passes, update `roadmap.md` with milestone status, evidence,
decision log, and a dated handoff; replace this prompt with the next
self-contained single-unit prompt; rerun the required checks; and create one
atomic Conventional Commit only when the complete accepted unit gate passes.
If the input route is unavailable, update the roadmap handoff and this prompt
with the blocker and do not create a success commit. Do not push or change
remote state.
