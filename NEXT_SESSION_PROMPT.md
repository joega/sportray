Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
remount the local game-detail drill-down as one small existing-route extension
that renders the materially richer `GameDetailModel` projection (participants,
status/timing, venue, source action, optional outcome, optional lines) with
neutral placeholders for nulls.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff in this file. Read `docs/upstream-contract.md` when it is
present; it is intentionally absent in this checkout, so inspect the installed
Omarchy and Quickshell sources directly for any host-boundary claim and record
any material deviation in `roadmap.md` and later the README. Inspect
`git status`, the current branch, and recent commits. Preserve unrelated user
changes, including any deletion of `MARKETPLACE_SUBMISSION.md`; do not restore
or stage it.

Verified current state:

- The current checkout is on `main`, clean, with `HEAD` at or beyond
  `f43ef34`; `origin/main` may lag locally by documentation commits. Do not
  push or change remote state.
- The shallow game-detail route was deliberately removed in `e9b6344`;
  `components/GameDetailView.qml` and `model/GameDetailModel.js` remain as
  unwired groundwork, and `fixtures/game-detail-route/route.json` records the
  removed route. Whole-row activation currently opens the guarded provider
  source page (`open-source`) only when a safe link exists.
- The 2026-08-24 optional-lines unit added a bounded provider-neutral `lines`
  projection (`{away:[{period,value}],home:[...]}` or `null`, max 12 entries,
  periods 1–99, values ≤ 9,999, equal-length sides, fail-closed) plus the
  earlier optional bounded `outcome`. ESPN's live scoreboard payloads carry
  competitor `linescores`; extraction happens inside
  `EspnProvider.parseGameDetailResponse` only. NHL detail remains sparse.
- The complete deterministic suite passes with 191 tests; plugin validation,
  real-import-path QML lint, and `git diff --check` pass.

Bounded outcome:

Restore the smallest detail drill-down that presents richer content than the
score row: wire `GameDetailView.qml` through `Panel.qml` local state, route
valid loaded game rows to it (keyboard, pointer, assistive), keep Back/Escape
returning to the scores route before panel close, render optional outcome and
lines sections with neutral null placeholders, and retain the nested guarded
source action. Do not fetch any second endpoint, do not add box-score,
play-by-play, or sport-specific sections, do not add provider fallback or
calendar views, and do not change provider parsing, normalized shapes,
polling, settings, or notification behavior.

Required checks:

- Extend fixture/source coverage for the restored route: row action routing,
  sparse/null placeholders, lines rendering bounds, back/close behavior, and
  preservation of the source action.
- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files.
- Because QML changes this time, rescan/restart the linked plugin on actual
  Omarchy after gates pass, confirm one running shell and `shell ping ok`,
  manually exercise the detail open/back route if interaction permits, inspect
  the fresh log for no Sportray exception, QML load failure, or binding-loop
  warning, and record exactly what was and was not exercised. A stale widget
  after rescan recovers via the supported `omarchy restart shell`.

Known risks and stop conditions: ESPN is an undocumented API; pre-event games
project `lines: null` and NHL detail stays sparse — represent both as neutral
placeholders without implying box-score depth. Stop before calendar/schedule
views (the owner separately requested a future full-calendar view with
followed-team/league filtering; design it only in its own later unit),
provider fallback, specialist sections, packaging, tagging, pushing, release,
or Marketplace work. If remounting cannot remain a small existing-route
extension, stop and document the blocker instead of expanding scope.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
