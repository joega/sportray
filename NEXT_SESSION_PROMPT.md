Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit. The baseball situation rich-detail slice is complete; no unit is
currently prepared, so the next unit requires explicit owner direction before
any implementation.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations
in `roadmap.md`. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-24):

- The checkout is on `main`, clean, with all five minimum competitive
  baseline capabilities closed plus the follow-up slices: standings
  (ESPN-backed and NHL), bounded rich game detail (outcome, per-period
  lines, team stats, labeled event links, live baseball situation section),
  icon-only ambient bar with status dots, pregame reminders, close-game
  alerts, wired per-league provider fallback chains (single verified
  candidate per league today), broader team discovery, calendar extensions,
  and the calendar week-strip overview. 220 deterministic tests pass.
- The game-detail drill-down now renders a bounded `SITUATION` section
  (count, outs, base-occupancy dots, optional last-play text) projected from
  the already fetched ESPN scoreboard snapshot through
  `parseGameDetailResponse` only; it hides when the sport has no situation
  data. Runtime detail games come from `parseScoreboardResponse`, so — as
  with lines and stats — the populated section is fixture-verified while
  runtime renders the hidden/null path; this wiring gap is recorded in the
  roadmap as a known cross-section follow-up, not a regression.
- Baseline gates at handoff time: `tests/run-js-tests.sh` (220 tests),
  `./tests/test-summon-helper.sh`, `git diff --check`, `omarchy plugin
  validate "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files (exit 0 with established
  warnings) all pass. Actual Omarchy restarted into one healthy shell
  (PID 971959); summon, the `c`/Escape calendar round-trip, and
  Down/Space/Return game-detail opening for a live MLB game were exercised
  through real keyboard input with screenshots, and the fresh log had normal
  provider/cache activity with no Sportray error, exception, or binding-loop
  warning.

Bounded outcome (only after explicit owner direction):

Implement exactly one owner-selected bounded vertical slice. Candidate
decisions live in `competition.md`; the remaining items are: (a) the gated
second verified provider adapter for live multi-provider fallback (P1-4
remainder), which may begin only after the owner provides an explicit
terms/region/reliability review for the candidate provider — if that review
is absent, do not implement it; (b) live verification of scoring-play
`competitions[].details` while a football game is in progress, before any
scoring-plays adapter; (c) optionally wiring the runtime detail path through
`parseGameDetailResponse` so the optional detail records reach the view —
this crosses fetch ownership and needs explicit owner approval; (d)
owner-controlled release/publication follow-ups, which stay outside feature
slices. Keep provider parsing in `providers/`, keep new logic in pure
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
the calendar shows only dates present in the five-entry per-league caches
and any wider window requires a verified wider source; pointer clicks on
calendar strip cells remain unexercised (no reliable injector); `wtype`
Return presses can land before the summoned panel takes keyboard focus, so
re-press or use Space and confirm via screenshot. Stop before packaging,
tagging, pushing, releasing, or Marketplace work. Do not weaken acceptance
gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and
create one atomic Conventional Commit-style commit only when all applicable
gates pass. Request subagents only for independent read-only reconnaissance;
the main agent owns edits, validation, handoff, and commit.
