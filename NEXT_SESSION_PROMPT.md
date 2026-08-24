Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
perform one read-only consistency audit of the calendar feature's README
claims, fixture evidence, and current source after the keyboard-reachable
filter unit, reconciling only directly contradictory statements. Do not add
features, providers, or interaction surfaces in this unit.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and
the latest handoff in this file. `docs/upstream-contract.md` is intentionally
absent in this checkout; inspect the installed Omarchy and Quickshell sources
directly for any host-boundary claim and record any material deviation in
`roadmap.md` and later the README. Inspect `git status`, the current branch,
and recent commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`, with `HEAD` at or beyond the
  2026-08-24 keyboard-reachable calendar filter commit; `origin/main` lags
  locally. Do not push or change remote state.
- The calendar slice and its keyboard filter route are implemented and
  runtime-verified: pure `model/CalendarModel.js` (bounded five-day window,
  enabled-league and favorites-only filters, 64-game per-day bound,
  fail-closed), `LeagueFetch.calendarSnapshot()` over the existing
  `dateCache`, `FetchService.calendarStates`, the `C` calendar toggle, and the
  `F` filter shortcut through `KeyboardRoutingPolicy.calendarFilterAction`
  into `Panel.toggleCalendarFilter()`. The deterministic suite passes with 200
  tests; plugin validation, real-import-path QML lint, `git diff --check`, and
  an actual-Omarchy keyboard exercise (open, filter to Favorites, filter back,
  Escape chain, clean log) all pass on 2026-08-24 with one Quickshell
  instance.
- Known limitations recorded in the handoff: pointer clicks remain unexercised
  (no reliable injector), and the settings-open/detail-open `f` rejection is
  covered only by the fixture path. The calendar shows only dates present in
  the five-entry per-league caches.

Bounded outcome:

Audit the README's calendar/keyboard behavior text, the roadmap acceptance
evidence for the calendar and filter units, and the current
`model/KeyboardRoutingPolicy.js`, `model/CalendarModel.js`, `Panel.qml`,
`services/LeagueFetch.qml`, and `services/FetchService.qml` sources for
contradictions (wrong key names, stale filter descriptions, incorrect bounds,
or claims the source no longer supports). Fix only directly contradictory
documentation or evidence statements. If nothing is contradictory, record the
clean audit and stop without edits beyond the handoff files.

Required checks:

- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files if
  any file changed; rerun them even for a documentation-only outcome.
- No QML behavior change is expected, so no shell restart is required unless
  the audit finds a source defect; if it does, stop and document the defect
  instead of fixing it in this unit.

Known risks and stop conditions: ESPN remains an undocumented API; the
installed host may require `omarchy restart shell` to load edited QML; pointer
injection remains unavailable. Stop before new calendar features, month-grid
rendering, per-game fetches, provider endpoints, settings persistence for the
filter, packaging, tagging, pushing, release, or Marketplace work.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
