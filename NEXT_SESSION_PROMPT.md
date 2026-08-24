Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
make the panel's calendar filter controls keyboard-reachable through the
existing panel cursor model — the All games/Favorites header toggle currently
requires a pointer — without changing the pure calendar model, provider
boundaries, or adding any new interaction surface.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff in this file. `docs/upstream-contract.md` is intentionally
absent in this checkout; inspect the installed Omarchy and Quickshell sources
directly for any host-boundary claim and record any material deviation in
`roadmap.md` and later the README. Inspect `git status`, the current branch,
and recent commits. Preserve unrelated user changes, including the deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`, clean, with `HEAD` at or beyond the
  2026-08-24 full-calendar day-list slice commit; `origin/main` may lag
  locally. Do not push or change remote state.
- The calendar slice is implemented and runtime-verified: pure
  `model/CalendarModel.js` (bounded five-day window over the existing
  per-league date caches, enabled-league and favorites-only filters, 64-game
  per-day bound, fail-closed malformed input), `LeagueFetch.calendarSnapshot()`
  reading only the existing `dateCache`, `FetchService.calendarStates`, and a
  panel header Calendar/Scores toggle plus All games/Favorites filter button
  with the `C` shortcut and Escape order detail → settings → calendar → panel
  close. The deterministic suite passes with 199 tests; plugin validation,
  real-import-path QML lint, `git diff --check`, and an actual-Omarchy
  keyboard exercise (open, day list, detail drill-down, Escape chain, clean
  log) all pass.
- Known limitation recorded in the handoff: the header filter button is
  outside the panel keyboard cursor model (`PanelKeyCatcher` routes arrows to
  the tab strip or result rows only), so the filter was exercised by fixtures
  but not at runtime; no pointer injector exists on this machine.

Bounded outcome:

Decide and implement the smallest keyboard route to the calendar filter: for
example, extend the panel's existing text-key or cursor routing so the
favorites filter can be toggled without a pointer, or fold the filter into an
already keyboard-reachable control. Keep the change inside `Panel.qml`'s
existing routing policy (and `model/KeyboardRoutingPolicy.js` if a pure
decision is needed), preserve the pure calendar model, detail drill-down,
standings, settings, notification, and ambient-bar behavior, and add
fixture-driven coverage for the new routing decision. Do not add new mouse
hover/scroll semantics, a second filter surface, settings persistence for the
filter, or provider work.

Required checks:

- Extend deterministic fixture/source coverage for the chosen routing
  decision and keep the existing 199-test calendar coverage green.
- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files.
- Because QML changes, use the supported `omarchy restart shell` on actual
  Omarchy after gates pass; confirm one running shell and `shell ping ok`,
  exercise the new keyboard route and the calendar open/filter/back chain,
  and inspect the fresh log for no Sportray exception, QML load failure, or
  binding-loop warning. Record exactly what was and was not exercised.

Known risks and stop conditions: header-button focus interacts with the
installed `PanelKeyCatcher` contract, so inspect
`/usr/share/omarchy/shell` panel sources before changing routing; stop before
adding new upstream API expectations, a second IPC route, provider endpoints,
month-grid rendering, per-game fetches, packaging, tagging, pushing, release,
or Marketplace work. If the smallest route would require a host-side change,
stop and document the blocker instead.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
