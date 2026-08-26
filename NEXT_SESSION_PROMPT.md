Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
complete **C5 — bounded background calendar hydration** after the persistent
per-day cache unit.

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

Bounded outcome: design and implement only a low-frequency, bounded startup
hydration path for missing calendar coverage if the existing verified provider
contracts support it. Prefer existing calendar-fetch ownership and existing
request admission; do not add a second fetch owner, provider endpoint, or
unbounded 60-day request burst. Seed at most the documented rolling window,
respect current freshness/backoff/cancellation behavior, and keep unknown,
partial, malformed, and offline states honest. If no verified provider-safe
hydration path exists, document the blocker and stop without speculative API
work.

Required checks: run `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file. On actual Omarchy, use one
supported shell, inspect fresh Quickshell logs, and verify that hydration is
low-frequency and does not duplicate polling or calendar-fetch ownership.
Update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and this prompt with dated
evidence; create one atomic Conventional Commit only if the unit’s gate passes.

Known stop conditions: stop if a provider range contract is unverified, if
hydration would slam remote services, if persistence/FileView readiness is
unsupported, or if implementation would widen host APIs or change provider,
polling, notification, watch, calendar-fetch, or schema ownership. Restore any
temporary runtime state. Do not push, tag, release, publish, or perform
Marketplace work.
