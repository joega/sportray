Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: implement calendar extensions (P1-6 remainder) as one bounded vertical
slice. The owner directed on 2026-08-24 that all candidate slices from
`competition.md` will be completed in sequence; the agreed order after this
unit is broadcast/event links, then a second verified provider adapter
(requires explicit terms/region/reliability review), then owner-controlled
release/publication follow-ups.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations in
`roadmap.md`. Inspect `git status`, the current branch, and recent commits.
Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The checkout is on `main`, clean, with the five recorded minimum competitive
  baseline capabilities implemented and P1-5 broader team discovery closed
  (2026-08-24): the favorite picker discovers teams across all eight leagues
  from the bounded static catalogs via league-name queries, ranked matches, a
  48-character query clamp, and a 60-result search cap that never applies to
  unfiltered browsing; 213 deterministic tests pass.
- Baseline gates at handoff time: `tests/run-js-tests.sh` (213 tests),
  `tests/test-summon-helper.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
  over all 24 QML files (exit 0 with established warnings), and
  `git diff --check` pass. Actual Omarchy restarted into one healthy shell
  (PID 920442); the picker's league-name discovery was exercised through real
  keyboard input (typing `premier` rendered the Premier League catalog) and
  the fresh log was clean apart from the pre-existing unrelated portal
  registration warning.
- The calendar is a bounded day list (`components/` calendar route,
  `model/CalendarModel.js`, `fixtures/calendar/calendar.json`) projecting the
  already-fetched five-date caches with favorite-only filtering and an `F`
  keyboard shortcut; it never starts new requests.

Bounded outcome:

Calendar extensions as one vertical slice: add direct date jumps and/or
explicit local-time rendering choices inside the existing cache-only calendar
boundary. Keep the calendar projection-driven from the already-fetched
five-date caches with no new fetch ownership, no wider request window, and no
provider parsing in QML; keep new logic in a pure fixture-tested model before
any QML wiring; preserve the existing calendar route, filters, keyboard path,
and panel-height behavior. If a slice would require fetching dates outside the
existing caches or a new endpoint, stop and record the blocker instead.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: restart/rescan as required by the changed boundary,
  confirm one healthy shell, exercise the changed calendar behavior through
  the real input path available, and inspect the fresh Quickshell log for
  Sportray errors, exceptions, or binding loops before claiming runtime
  success.

Known risks and stop conditions: ESPN remains an undocumented API; any new
request path or second provider adapter requires explicit terms/region/
reliability review before implementation; release metadata/tagging/pushing/
Marketplace remain owner-controlled and out of feature scope. Stop before
broadcast/event links, any second provider adapter, packaging, tagging,
pushing, releasing, or Marketplace work; stop if the slice would require a new
upstream shell API, an unverified endpoint, or scope beyond one vertical
slice. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status, replace this file with the next
self-contained single-unit prompt (broadcast/event links), and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
