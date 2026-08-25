Work in `/home/joeg/Projects/sportray` on one bounded work unit only: **Level
the Field C1 — Month grid vertical slice**.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, `competition.md`, and `LEVEL_THE_FIELD_SPRINT.md` in
full. `docs/upstream-contract.md` is intentionally absent in this checkout;
inspect installed/current Omarchy and Quickshell sources directly for every
host-boundary claim and record any material deviation in `roadmap.md`. Inspect
`git status`, the current branch, and recent commits. Preserve unrelated user
changes, including the absence of `MARKETPLACE_SUBMISSION.md`; do not restore
or stage it. Use subagents only for independent read-only reconnaissance or
test/log investigation that materially benefits from parallelism.

Verified starting state:

- `main` source is at committed detail presentation cleanup `ccfc099`; MLB
  StatsAPI fallback `cb53ded` remains committed.
- The deterministic baseline is 231 passing JavaScript tests. Summon-helper,
  `git diff --check`, actual-Omarchy plugin validation, and real-import-path
  QML lint passed at the last source-changing unit.
- Installed Omarchy `4.0.0-1` and Quickshell `0.3.0` revision
  `28771c7c74b42e20afca0b1b63980cb46515537` are the current host boundary.
- Calendar currently projects five date caches into `CalendarWeekStrip.qml`
  and reuses selected-day game rows. It supports All/Favorites, `C`, `F`, `G`,
  arrows, `[`/`]`, Today, detail routing, and bounded panel height.
- Unvisited dates currently lack completeness information and can look like
  verified empty dates. C1 must distinguish unknown from empty.
- The full sprint is documented in `LEVEL_THE_FIELD_SPRINT.md`. C1 intentionally
  precedes the separate calendar provider-reconnaissance and month-hydration
  units.
- Existing live-football evidence is still blocked until an actual event is in
  progress. ESPN/static MLB team-ID drift and runtime failover injection remain
  unresolved and are out of scope.

Concrete outcome: make Calendar visibly and behaviorally a conventional month
calendar without adding a new fetch owner. Implement one 42-cell month grid
for the selected month, including adjacent-month cells, previous/next month,
Today, selected-day state, today state, bounded cached game counts, favorite
markers, and explicit unknown-versus-known-empty presentation. Selecting any
valid cell must use the existing selected-date path, which fetches that day's
enabled leagues under the existing ownership and then renders the existing
selected-day rows below the grid.

Required behavior:

- Extend the provider-neutral pure calendar/date model; QML performs no date
  math, provider parsing, raw filtering, or URL construction.
- Build exactly 42 cells with stable local `YYYY-MM-DD` keys. Fixture-test
  ordinary months, a six-week month, leap day, year rollover, adjacent-month
  cells, invalid input, and local DST boundaries.
- Carry enough completeness state to render unqueried dates neutrally. Only a
  successfully complete cached snapshot may produce a known `No games` day.
  Do not infer empty from missing cache data.
- Replace Calendar's five-day strip with a focused month component. Reuse the
  existing selected-day row vocabulary, whole-row detail route, source action,
  All/Favorites filter, league admission, retry/error states, and local-time
  labels.
- Provide previous/next month and Today controls plus keyboard and Accessible
  routes. Left/Right move a day, Up/Down move a week while the grid owns focus,
  Enter/Space select, and PageUp/PageDown move a month. Preserve existing
  `C`, `F`, `G`, `T`, `[`/`]`, Escape ordering, and deterministic focus return
  unless a fixture-backed conflict requires a narrowly documented change.
- Keep the panel within the installed host's available-card-height contract on
  top, bottom, left, and right bars. Long selected-day content scrolls through
  existing ownership; the calendar must not expand off-screen.
- Retire `CalendarWeekStrip.qml` only if source inspection proves it has no
  remaining consumer. Do not perform unrelated cleanup.

Hard scope limits:

- No visible-month background hydration, range requests, new endpoint,
  schedule crawler, timer, Process, polling change, response-limit change, or
  cache widening. Those belong to C2/C3.
- No settings schema 2, watched games, followed/reordered leagues, scoring
  plays, leaders, broadcasts, provider fallback, team-ID reconciliation, new
  sport/league, packaging, tagging, pushing, release, or Marketplace work.
- Do not weaken the 2 MiB, 256-event, one-in-flight, future-schema, notification,
  privacy, or no-daemon boundaries.

Acceptance checks:

- Fixture-driven pure tests cover month geometry, completeness, filters,
  selected-day projection, keyboard routing, bounds, and malformed input.
- Source assertions prove Calendar adds no new network/process/timer owner and
  QML contains no provider parsing or date arithmetic.
- First open renders a genuine current-month 42-cell grid.
- Pointer, keyboard, assistive activation, previous/next month, Today,
  adjacent-month selection, All/Favorites, selected-day loading/empty/game
  states, detail open/back, and Escape order work on actual Omarchy.
- Run:
  - `./tests/run-js-tests.sh`
  - `./tests/test-summon-helper.sh`
  - `git diff --check`
  - `omarchy plugin validate "$PWD"`
  - `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
- Confirm exactly one Omarchy shell instance, shell ping, plugin discovery,
  summon behavior, and fresh logs with no Sportray error, QML-load failure,
  exception, binding-loop warning, late callback, or duplicate graph.

Stop condition: if a correct month grid cannot fit the verified host panel
height or requires new fetch ownership to avoid presenting false data, do not
fake completeness or broaden scope. Record the blocker and the smallest next
unit in `roadmap.md` and `LEVEL_THE_FIELD_SPRINT.md`, refresh this prompt, and
do not mark C1 complete.

At the end, update C1 status/evidence in `LEVEL_THE_FIELD_SPRINT.md`, append a
dated milestone/decision/risk/handoff entry to `roadmap.md`, reconcile
`competition.md` only if parity evidence changed, and replace this file with a
self-contained prompt for exactly C2 or the smallest blocker-resolution unit.
Commit the completed source unit atomically only after its gates pass. Do not
push or perform any release/Marketplace action.
