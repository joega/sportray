Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement the shared settings schema-2 migration foundation (S1).

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, and `LEVEL_THE_FIELD_SPRINT.md`. If
`docs/upstream-contract.md` is absent, inspect the installed/current Omarchy
and Quickshell sources directly and record material boundary deviations.

Verified current state:

- C1-C5 calendar work is complete, including durable per-day cache storage and
  explicitly accepted NHL-only low-frequency rolling hydration.
- `CalendarFetch.qml` remains the sole schedule owner; unsupported leagues are
  explicitly unknown to background hydration.
- Watches and followed leagues are already present in the current schema-1
  implementation and UI, but the shared schema-2 migration foundation is not
  yet implemented.
- L3 pointer/direct-Accessible runtime verification is separately blocked:
  this Wayland host has keyboard `wtype` but no supported pointer injector or
  AT-SPI event-driving client. Do not reopen that gate in this unit.
- Current settings/state persistence repairs owner-only permissions, uses
  atomic FileView writes, preserves future schemas opaquely, and has actual
  Omarchy restart evidence for schema 1. Preserve those boundaries.

Bounded outcome: upgrade the pure settings/state projection from schema 1 to
schema 2, migrate valid schema-1 state deterministically while preserving
enabled leagues, canonical favorites, followed leagues, notifications,
transition dedupe, and watches, and add bounded empty `watchedGames` state for
later watch work. Do not add UI or alter provider/polling behavior.

Required checks: add fixture-driven coverage for valid schema 1 migration,
valid schema 2, missing/invalid fields, future-schema opacity, corrupt JSON,
permission-safe persistence projection, and external reload. Run
`./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file. On actual Omarchy, use one
supported shell, copy a schema-1 fixture into the real state path, restart
through supported commands, verify schema-2 persistence and restart recovery,
inspect fresh Quickshell logs, then restore the original runtime state.

Known stop conditions: future-schema preservation or permission guarantees
would be weakened, migration would discard a compatible value, a second shell
would be needed, or scope expands into watch UI, providers, polling,
notifications, calendar fetch/hydration/cache, or host APIs. Restore temporary
runtime state. Update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and this
prompt with dated evidence; create one atomic Conventional Commit only after
all gates pass. Do not push, tag, release, publish, or perform Marketplace
work.
