Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
verify the direct physical ListView edge transitions for the Calendar week
stream on actual Omarchy, if and only if a supported host input path is
available.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and Quickshell
sources directly and record any material boundary deviation.

Verified current state:

- Source and installed plugin trees match commit
  `58a4d05f405b9fa29c924a0c264c0b431f9bde35`; installed origin remains
  `https://github.com/joega/sportray.git`.
- Actual Omarchy restart, rescan, summon, Calendar open, cache-hit, and one
  close/reopen pass succeeded. Known retained game/empty cells rendered with no
  calendar range curl; only an ordinary selected-day MLB curl was observed.
- The healthy retained cache was preserved: 308 manifest keys and 389 files,
  with 80 pre-existing files outside the manifest intentionally retained.
- The direct `MonthCalendar.weekList` `atYBeginning`/`atYEnd` callbacks remain
  unverified. This host has `wtype` only, AT-SPI reports `IsEnabled=false`, and
  PageUp/PageDown call `changeCalendarMonth()` directly rather than scrolling
  the ListView. Do not claim ListView edges from those keys.
- No provider, cache, polling, notification, settings, packaging, or remote
  state change is authorized for this unit.

Bounded outcome: obtain a supported pointer/axis or equivalent focused input
route that actually scrolls `MonthCalendar.weekList`, hit the physical start
and end edges once, and confirm each bounded month transition/recenter without
overflow, duplicate requests, or a second Quickshell process. If the supported
input route is unavailable, record the blocker and stop without a success
commit or a workaround such as `/dev/uinput`, synthetic PageUp/PageDown
substitution, or a plugin test hook.

Required checks on a pass: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, installed-checkout production validation,
and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
On actual Omarchy, restart/rescan as required, confirm one shell and ping
`ok`, inspect fresh Quickshell logs, and manually exercise the supported edge
route. Do not delete or replay the healthy cache. Preserve the known transient
post-rescan summon race and unrelated desktop-portal warning in the evidence.

Known risks: no supported pointer/axis injector is currently installed;
`wtype` cannot establish ListView-edge evidence; pre-fix cache orphans remain
outside the manifest; live selected-day polling can update the projection while
Calendar is open; and ESPN remains an undocumented API. Request subagents only
for independent read-only source or log inspection that materially benefits
from parallelism.

When the gate passes, update `roadmap.md` with milestone status, evidence,
decision log, and a dated handoff; replace this prompt with the next
self-contained single-unit prompt; rerun the required checks; and create one
atomic Conventional Commit. Do not push or change remote state.
