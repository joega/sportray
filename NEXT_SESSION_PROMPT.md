Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
wait for explicit owner direction before changing Calendar behavior. If no
new owner direction is present, perform no Calendar implementation work and
stop.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and
Quickshell sources directly and record any material boundary deviation.

Verified current state:

- Production Calendar is disabled by the shared readonly
  `SportrayService.calendarFeatureEnabled: false` flag.
- `Panel.qml` hides the Calendar header action and guards the Calendar route
  and `C` shortcut. `FetchService.qml` and `CalendarFetch.qml` reject calendar
  scheduling, startup rehydration, and rolling-background work while disabled.
- Daily date navigation, favorite-team score polling, standings, notifications,
  settings, and selected-day lookahead remain supported.
- Calendar source, policies, and durable cache files remain in-tree for a
  future redesign. Do not delete, clear, or replay the existing cache.
- README and CHANGELOG accurately state that Calendar is temporarily disabled
  in production. The deterministic suite passes with 262 tests. Repository
  validation, plugin validation, and real-import-path QML lint pass.
- Actual Omarchy confirmed one healthy Quickshell process, shell ping `ok`,
  normal daily league refreshes, and no Calendar range/rehydration activity.
  The installed checkout has preserved local geometry edits. Do not overwrite
  them.

Bounded outcome: unless the owner provides explicit Calendar re-enable or
redesign requirements in the current request, make no Calendar source,
provider, cache, settings, or UI changes. If an unrelated owner-directed unit
is supplied, keep the production Calendar flag false and avoid touching its
implementation.

Required checks for any unrelated source change: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, installed-checkout production validation,
and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Do not push or change remote state.

Known risks: Calendar remains intentionally dormant; a future redesign needs
new provider/cache and interaction acceptance evidence; the installed checkout
is locally modified; and ESPN remains an undocumented API. Request subagents
only for independent read-only work that materially benefits from parallelism.

When an owner-directed unit is complete, update `roadmap.md` with evidence and
a dated handoff, replace this prompt with the next self-contained prompt, rerun
the required checks, and create one atomic Conventional Commit only when its
gate passes. If no owner direction exists, leave the source unchanged and do
not create a commit.
