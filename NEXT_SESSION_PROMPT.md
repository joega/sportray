Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit. The live scoring-play verification unit was selected by the owner and
attempted 2026-08-24 ~9:00 PM EDT but is blocked: no football game was in
progress (NFL preseason had concluded; CFB begins Sat Aug 29), and
completed-game scoreboards again carried no `competitions[].details`. The
next unit therefore requires explicit owner direction before implementation.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md` (see
the "Scoring-play live verification — BLOCKED 2026-08-24" entry), and
`competition.md`. `docs/upstream-contract.md` is intentionally absent in this
checkout; inspect installed Omarchy/Quickshell sources directly for any
host-boundary claim and record material deviations in `roadmap.md`. Inspect
`git status`, the current branch, and recent commits. Preserve unrelated user
changes, including the absence of `MARKETPLACE_SUBMISSION.md`; do not restore
or stage it.

Verified current state (2026-08-24):

- The checkout is on `main`, clean, with all five minimum competitive baseline
  capabilities closed plus follow-up slices: standings (ESPN-backed and NHL),
  bounded rich game detail (outcome, per-period lines, team stats, labeled
  event links, live baseball situation section), icon-only ambient bar with
  status dots, pregame reminders, close-game alerts, wired per-league provider
  fallback chains (single verified candidate per league today), broader team
  discovery, calendar extensions with the week-strip overview. 220
  deterministic tests pass.
- The game-detail drill-down renders bounded optional sections projected from
  the already fetched ESPN scoreboard snapshot through `parseGameDetailResponse`
  only; runtime detail games come from `parseScoreboardResponse`, so populated
  lines/stats/situation are fixture-verified while runtime renders the hidden/
  null path — a recorded cross-section follow-up, not a regression.
- Scoring plays (`competitions[].details`) remain unverified: two inspection
  windows on 2026-08-24 found no in-progress football game, and both the
  default and dated (`?dates=20260823`) NFL scoreboards showed zero
  `details` arrays for completed games.

Bounded outcome (only after explicit owner direction):

Implement exactly one owner-selected bounded vertical slice. Candidates:
(a) retry live verification of football scoring-play `competitions[].details`
during actual game minutes — realistic windows are CFB week 0 from Sat
Aug 29 and NFL week 1 from Thu Sep 10; do not attempt outside live minutes;
(b) optionally wiring the runtime detail path through `parseGameDetailResponse`
so the optional detail records reach the view — crosses fetch ownership and
needs explicit owner approval; (c) the gated second verified provider adapter
for live multi-provider fallback (P1-4 remainder) — may begin only after the
owner provides an explicit terms/region/reliability review for the candidate
provider; if absent, do not implement it; (d) owner-controlled release/
publication follow-ups for the unreleased `1.0.0-rc.8` candidate — outside
feature slices. Keep provider parsing in `providers/`, keep new logic in pure
fixture-tested models, and preserve normalized game identity, favorites,
settings schema-1, polling ownership, and the existing response/event bounds.
If the owner supplies no direction, record the still-pending decision in
`roadmap.md`, refresh this file, and stop without a success commit.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: restart/rescan as required by the changed boundary,
  confirm one healthy shell, exercise the changed behavior through the real
  input path available, and inspect the fresh Quickshell log for Sportray
  errors, exceptions, or binding loops before claiming runtime success.

Known risks and stop conditions: ESPN remains an undocumented API; any new
request path or provider requires explicit review before implementation;
`competitions[].details` may never appear on scoreboard payloads even during
live games, which would close the scoring-plays idea under the single-endpoint
boundary; the calendar shows only dates present in the five-entry per-league
caches; pointer clicks on calendar strip cells remain unexercised (no reliable
injector); `wtype` Return presses can land before the summoned panel takes
keyboard focus, so re-press or use Space and confirm via screenshot. Stop
before packaging, tagging, pushing, releasing, or Marketplace work. Do not
weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and
create one atomic Conventional Commit-style commit only when all applicable
gates pass. Request subagents only for independent read-only reconnaissance;
the main agent owns edits, validation, handoff, and commit.
