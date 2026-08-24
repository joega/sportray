Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
design and implement one bounded full-calendar view for the panel — the
owner-requested calendar with followed-team and league filtering — as its own
vertical slice, starting from a pure provider-neutral calendar model before
any QML.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff in this file. `docs/upstream-contract.md` is intentionally
absent in this checkout; inspect the installed Omarchy and Quickshell sources
directly for any host-boundary claim and record any material deviation in
`roadmap.md` and later the README. Inspect `git status`, the current branch,
and recent commits. Preserve unrelated user changes, including the deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`, clean, with `HEAD` at or beyond the
  2026-08-24 game-detail drill-down remount commit; `origin/main` may lag
  locally by documentation commits. Do not push or change remote state.
- The local game-detail drill-down is remounted and runtime-verified:
  whole-row activation of valid loaded game rows opens `GameDetailView`
  (participants, status/timing, venue, optional outcome, optional bounded
  lines, neutral `—` placeholders), Back/Escape return to the scores route
  before panel close, and the nested guarded ESPN/NHL.com source action is
  retained. The complete deterministic suite passes with 194 tests; plugin
  validation, real-import-path QML lint, and `git diff --check` pass.
- Existing reusable boundaries: `LeagueCatalog.js` (enabled leagues),
  `DateModel.js` (local date keys/carousel), `DateCachePolicy.js`,
  `NextEventModel.js`/`LookaheadPolicy.js` (bounded next-game lookup),
  `FavoritePresentation.js`, and the shared `SportrayService` fetch graph.
  ESPN's date-range scoreboard route and the NHL schedule route are the only
  verified multi-date provider shapes.

Bounded outcome:

Deliver the smallest useful calendar slice: one pure, fixture-driven calendar
model that projects an already-fetched, bounded date window of normalized
games into a day-grid or day-list projection with followed-team and
enabled-league filters, then mount it in the existing panel behind a minimal
entry point (for example a header action) without adding a new polling owner
or a second fetch graph. Reuse the existing date caches and lookahead/schedule
routes only; if richer multi-date data would require new provider endpoints or
a new polling contract, stop and document instead. Keep provider parsing out
of QML, preserve the detail drill-down, standings, settings, notification, and
ambient-bar behavior unchanged, and render missing data as neutral states.

Required checks:

- Extend fixture coverage for the calendar projection: date-window bounds,
  followed-team filtering, league filtering, empty days, malformed input, and
  the no-new-fetch ownership boundary.
- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files.
- Because QML changes, rescan and, if the widget stays stale, use the
  supported `omarchy restart shell` on actual Omarchy after gates pass;
  confirm one running shell and `shell ping ok`, manually exercise the
  calendar open/filter/back route if interaction permits, inspect the fresh
  log for no Sportray exception, QML load failure, or binding-loop warning,
  and record exactly what was and was not exercised.

Known risks and stop conditions: ESPN is an undocumented API; multi-date data
beyond the existing five-date cache and bounded lookahead is not verified, so
the calendar must fail closed to available snapshots. Stop before new provider
endpoints, per-game fetches, box-score or specialist sections, provider
fallback, packaging, tagging, pushing, release, or Marketplace work. If the
calendar cannot remain a small existing-panel extension, stop and document the
blocker instead of expanding scope.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
