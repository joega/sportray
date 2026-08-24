Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: implement broadcast/event links (P2-8) as one bounded vertical slice.
The owner directed on 2026-08-24 that all candidate slices from
`competition.md` will be completed in sequence; the agreed order after this
unit is a second verified provider adapter (requires explicit terms/region/
reliability review before any implementation), then owner-controlled
release/publication follow-ups.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations
in `roadmap.md`. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The checkout is on `main`, clean, with the five recorded minimum
  competitive baseline capabilities implemented, P1-5 broader team discovery
  closed, and P1-6 calendar extensions closed (2026-08-24): the cache-only
  calendar now has the `C` route, `F` favorites filter, a `G` direct jump to
  the next cached day with games, and bounded explicit local-time row
  labels; 216 deterministic tests pass.
- Baseline gates at handoff time: `tests/run-js-tests.sh` (216 tests),
  `tests/test-summon-helper.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
  over all QML files (exit 0 with established warnings), and
  `git diff --check` pass. Actual Omarchy restarted into one healthy shell
  (PID 926785); the calendar `G` jump was exercised through real keyboard
  input and logged `cache-hit date-changed 2026-08-25` on every enabled
  league with no new requests; the fresh log was clean apart from the
  pre-existing unrelated portal registration warning.
- Game rows and the detail view already carry a labeled, guarded
  `SourceLinkButton` (`omarchy-launch-browser` with the reviewed ESPN/NHL
  canonical game link). Broadcast/event links must not weaken that
  attribution or the reviewed URL admission boundary.

Bounded outcome:

Broadcast/event links as one vertical slice: where an already-fetched
provider payload supplies safe attributable broadcast stream, VOD, or event
URLs, project them provider-neutrally through the existing reviewed URL
admission and render at most a small bounded set of labeled links beside
the existing source action. Verify the actual provider field shapes from
live payloads or recorded fixtures before parsing; keep provider parsing in
`providers/`; keep new logic in a pure fixture-tested model before any QML
wiring; preserve the labeled source action, row geometry, keyboard path,
and panel-height behavior. If the current payloads do not supply reliable
broadcast/event URLs, or the slice would require a new endpoint, stop and
record the blocker instead.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: restart/rescan as required by the changed boundary,
  confirm one healthy shell, exercise the changed link behavior through the
  real input path available, and inspect the fresh Quickshell log for
  Sportray errors, exceptions, or binding loops before claiming runtime
  success.

Known risks and stop conditions: ESPN remains an undocumented API; any new
request path or second provider adapter requires explicit terms/region/
reliability review before implementation; release metadata/tagging/pushing/
Marketplace remain owner-controlled and out of feature scope. Stop before
any second provider adapter, richer detail sections beyond this slice,
packaging, tagging, pushing, releasing, or Marketplace work; stop if the
slice would require a new upstream shell API, an unverified endpoint, or
scope beyond one vertical slice. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status, replace this file with the next
self-contained single-unit prompt (second verified provider adapter,
gated on an explicit provider review), and create one atomic Conventional
Commit-style commit only when all applicable gates pass. Request subagents
only for independent read-only reconnaissance; the main agent owns edits,
validation, handoff, and commit.
