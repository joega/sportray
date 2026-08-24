Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: a second verified provider adapter for live multi-provider fallback
(P1-4 remainder). This unit is GATED: it may begin only after the owner
provides an explicit provider review covering terms, region availability,
reliability, and response shape for the candidate provider (for example an
MLB or NHL alternative source). If that review is absent at session start,
do not implement; instead record the blocker in `roadmap.md`, refresh this
file with the smallest resolving prompt, and stop without a success commit.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations
in `roadmap.md`. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-24):

- The checkout is on `main`, clean, with the five minimum competitive
  baseline capabilities, P1-5 broader team discovery, P1-6 calendar
  extensions, and P2-8 broadcast/event links all closed: the game-details
  drill-down renders at most two labeled event links (ESPN Highlights video
  page, ESPN Preview article) admitted from the already-fetched snapshot
  through the reviewed HTTPS/espn.com host boundary, beside the unchanged
  labeled source action; 217 deterministic tests pass.
- Per-league provider fallback chains are wired with cooldown, last-good
  retention, isolation, and exhaustion handling, but every production chain
  is single-candidate because each league has exactly one verified adapter.
- Baseline gates at handoff time: `tests/run-js-tests.sh` (217 tests),
  `tests/test-summon-helper.sh`, `git diff --check`, `omarchy plugin
  validate "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files (exit 0 with established
  warnings) all pass. Actual Omarchy restarted into one healthy shell; the
  Preview link was exercised through real keyboard input and opened
  `https://www.espn.com/mlb/preview/_/gameId/401816657` via the guarded
  launcher; the fresh log had normal provider/cache activity and no Sportray
  error, exception, or binding-loop warning.

Bounded outcome (only when the owner review is supplied):

One verified second provider adapter as one vertical slice: record the
owner's terms/region/reliability findings, verify the candidate provider's
actual response shape from live payloads or recorded fixtures before
parsing, add the adapter inside `providers/`, extend exactly one league's
`providerChain()` with the new candidate, and prove live fallback behavior
with fixture-driven tests (primary failure → second candidate → last-good
retention → cooldown exhaustion beside a healthy sibling). Keep provider
parsing in `providers/`, keep new logic in pure fixture-tested models, and
preserve normalized game identity, favorites, settings schema-1, polling
ownership, and the response/event bounds. If the candidate provider cannot
be verified against the review, stop and record the blocker.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: restart/rescan as required by the changed boundary,
  confirm one healthy shell, exercise the changed fallback behavior through
  the real input path available (or, if failure injection is not possible
  live, say so explicitly rather than claiming it), and inspect the fresh
  Quickshell log for Sportray errors, exceptions, or binding loops before
  claiming runtime success.

Known risks and stop conditions: ESPN remains an undocumented API; any new
request path or provider requires explicit terms/region/reliability review
before implementation; release metadata/tagging/pushing/Marketplace remain
owner-controlled and out of feature scope. Stop before richer detail
sections, packaging, tagging, pushing, releasing, or Marketplace work; stop
if the slice would require a new upstream shell API, an unverified endpoint,
or scope beyond one vertical slice. Do not weaken acceptance gates to
finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status, replace this file with the next
self-contained single-unit prompt (owner-controlled release/publication
follow-ups or the next agreed slice), and create one atomic Conventional
Commit-style commit only when all applicable gates pass. Request subagents
only for independent read-only reconnaissance; the main agent owns edits,
validation, handoff, and commit.
