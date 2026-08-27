Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
runtime-verify the calendar open cache-hit on actual Omarchy so a complete
retained month does not refetch or stall the UI.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and
Quickshell sources directly and record any material boundary deviation.

Verified current state:

- Calendar open previously always called `requestMonth()`, ignoring the durable
  cache except for display. In-memory windows were capped at 3, so five
  admitted leagues evicted NHL/NFL and the next open refetched. Each chunk
  rebuilt three month grids, persisted disk, and recentered the ListView.
- Source now treats complete retained coverage as a cache hit in
  `requestCalendarMonth()` and per-league `beginMonthPlan()`. Persist runs only
  from the calendar owner. Month grids compute only while Calendar is open.
  The week ListView uses a stable integer model and recenters only when the
  center month changes. `MAX_CACHE_WINDOWS` is 24.
- Startup rehydration is unchanged and still skips when coverage is complete.
  MLB and both NCAA leagues remain selected-day-only.
- The complete suite has 260 tests; helper, diff, source validator, and
  all-file real-import-path QML lint pass. Live Omarchy confirmation of
  zero-curl Calendar open is not claimed yet.
- The healthy retained admitted cache remains intact (~308 manifest keys).
  Pre-fix out-of-window orphan files are ignored by the manifest; do not
  delete healthy cache data or replay current-month rehydration merely to
  obtain progress UI.
- ListView-edge verification remains blocked: this host has `wtype` only,
  AT-SPI `IsEnabled=false`, and PageUp/PageDown call `changeCalendarMonth()`
  directly. Do not use that gap to weaken the edge gate.

Bounded outcome: fast-forward the installed checkout to the source performance
commit without changing its GitHub `origin`, restart/rescan as the installed
lifecycle requires, then open the installed Sportray Calendar through the
supported keyboard route. Confirm known-game/known-empty cells appear from
cache, no calendar range curl burst starts, and the panel stays usable. Close
and reopen Calendar once; still no extra range fetch. Inspect fresh logs and
verify no new out-of-window cache write. Do not modify provider profiles,
rehydration ownership, endpoints, limits, polling, notifications, settings,
packaging, release, or remote state.

Required checks: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, production validation of the installed
checkout, and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every
QML file. Confirm the installed/source runtime trees match before any runtime
claim. If a concrete defect requires a fix, implement only that defect, commit
it after its gate passes, fast-forward the installed checkout without changing
its configured GitHub origin, restart/rescan as the installed lifecycle
requires, and repeat the runtime check.

Stop if the installed lifecycle cannot load the performance commit or the
keyboard Calendar route is unavailable; record the blocker without weakening
the gate or creating a success commit. On pass, update `roadmap.md` and its
dated handoff, replace this file with the next single-unit prompt, and create
one atomic Conventional Commit.

Known risks: widget registration can race immediately after rescan; live
selected-day polling still rebuilds calendar projection while Calendar is
open; pre-fix ignored cache orphans remain outside the manifest; the healthy
cache makes rehydration progress transient; PageUp/PageDown is not edge
evidence; and ESPN is an undocumented API. Request subagents only for
independent read-only source or log inspection that materially benefits from
parallelism.
