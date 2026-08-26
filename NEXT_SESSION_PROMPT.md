Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
investigate the remaining L3 host-input verification gate after C5.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, and `LEVEL_THE_FIELD_SPRINT.md`. If
`docs/upstream-contract.md` is absent, inspect the installed/current Omarchy
and Quickshell sources directly and record material boundary deviations.

Verified current state:

- C1-C3 calendar work and C4 persistent day-cache storage are complete.
- `CalendarDiskCache` owns only normalized complete calendar snapshots. It uses
  a versioned manifest and atomic per-league/per-day JSON files under
  `~/.cache/sportray/calendar/`, retaining 30 days past and 30 days future,
  with 488 files and 8 MiB serialized-data caps plus cleanup.
- Live data takes precedence over disk fallback. Provider parsing, polling,
  notifications, watches, settings schema, calendar-fetch ownership, and host
  APIs are unchanged.
- On actual Omarchy 4.0.0-1 / Quickshell 0.3.0, a clean supported restart
  created matching per-league day files and a manifest; a second restart
  retained them. Repository gates and real-import-path QML lint pass.
- L3 interaction verification remains separately blocked because this host has
  no supported pointer or direct accessibility-event injector. Do not reopen
  that gate in this unit.

Verified current state: C5 is complete with explicit owner acceptance of
NHL-only partial coverage. `ChunkPolicy.planRolling` admits only NHL and
plans a bounded 30-day window in seven-day chunks. `CalendarFetch.qml` remains
the sole schedule owner, uses one Process and one low-frequency 15-minute
Timer, waits for durable cache readiness, prioritizes visible-month work, and
preserves generation cancellation. Partial/failed chunks never become
complete or empty. Unsupported leagues remain explicitly unknown to
background hydration. Polling, notifications, watches, provider fallback,
settings/schema, cache ownership, and host APIs were not changed.

Repository gates and actual Omarchy restart/rescan/summon/ping passed. Fresh
logs showed one shell, normal NHL polling, and no QML exception, binding loop,
duplicate graph, or second shell. The full timer interval was not waited out.
L3 pointer/accessibility verification remains blocked because this host has no
supported pointer or direct accessibility-event injector.

Bounded outcome: only if a supported host input injector is available, verify
the existing calendar and followed-league pointer/accessibility interactions
without changing product behavior. Otherwise record the host limitation and
stop. Do not reopen C5 or add providers, endpoints, owners, timers, polling,
notifications, schema changes, or host APIs.

Required checks if code changes: run `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file. On actual Omarchy, use one
supported shell, inspect fresh Quickshell logs, and exercise only the changed
interaction.
Update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and this prompt with dated
evidence; create one atomic Conventional Commit only if the unit’s gate passes.

Known stop conditions: no supported injector, need for a second shell, or any
scope expansion affecting provider, polling, notification, watch, calendar
fetch, hydration, cache, or settings ownership. Restore temporary runtime
state. Do not push, tag, release, publish, or perform Marketplace work.
