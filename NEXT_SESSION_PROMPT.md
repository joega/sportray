Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: implement the owner-selected candidate product slice from the decision
list recorded in `competition.md`. The owner has not yet selected a direction;
if none is supplied at session start, ask for it and stop without implementing
anything if no answer is given.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations in
`roadmap.md`. Inspect `git status`, the current branch, and recent commits.
Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The checkout is on `main`, clean, with all five recorded minimum competitive
  baseline capabilities implemented and audited on 2026-08-24: standings
  (ESPN + verified NHL adapter), bounded rich game detail drill-down (outcome +
  per-period lines), icon-only ambient bar with status dots, live-favorite
  rotation, and countdown projection, wired per-league provider fallback
  chains (single verified candidate each), opt-in pregame reminders, and
  close-game alerts. A read-only consistency audit found no README/roadmap/
  backlog contradictions; `competition.md` backlog statuses are reconciled.
- Baseline gates at audit time: 210 deterministic tests pass;
  `tests/test-summon-helper.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
  (exit 0 with established warnings), and `git diff --check` pass.
- Owner-facing candidate slices pending direction (see `competition.md`
  "Recommended next slices — awaiting owner direction"): broader team
  discovery; a second verified provider adapter enabling live multi-provider
  fallback; richer detail sections (scoring plays/leaders/situation) from
  already normalized data only; calendar extensions (date jumps/local-time)
  within the cache-only boundary; broadcast/event links; release/publication
  follow-ups are separate owner-controlled steps outside feature work.

Bounded outcome:

Exactly one of:

1. If the owner selects a slice: implement that one slice as a single bounded
   vertical slice under the existing guardrails (provider parsing stays in
   `providers/`, pure models fixture-tested before QML wiring, bounded
   inputs/outputs, no settings schema change unless the slice explicitly
   requires one, no new endpoints without a live-verified provider contract).
2. If the owner gives no direction: record the still-pending decision in a
   dated roadmap handoff, refresh this prompt unchanged in substance, and
   stop without implementing anything.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: rescan/restart as required by the changed boundary,
  confirm one healthy shell, exercise the changed behavior through the real
  input path available, and inspect the fresh Quickshell log for Sportray
  errors, exceptions, or binding loops before claiming runtime success.

Known risks and stop conditions: ESPN remains an undocumented API; any second
provider adapter requires explicit terms/region/reliability review before
implementation; release metadata/tagging/pushing/Marketplace remain
owner-controlled and out of feature scope. Stop before packaging, tagging,
pushing, releasing, or Marketplace work; stop if the slice would require a new
upstream shell API, an unverified endpoint, or scope beyond one vertical
slice. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
