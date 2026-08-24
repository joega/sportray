Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
perform one read-only consistency audit across `README.md`, `roadmap.md`
acceptance evidence, and the private competition backlog after the wired
provider-fallback unit, then present remaining candidate product slices for
owner direction. Do not implement any new feature in this unit.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff. `docs/upstream-contract.md` is intentionally absent in this
checkout; inspect installed Omarchy/Quickshell sources directly for any
host-boundary claim and record material deviations in `roadmap.md`. Inspect
`git status`, the current branch, and recent commits. Preserve unrelated user
changes, including the absence of `MARKETPLACE_SUBMISSION.md`; do not restore
or stage it.

Verified current state:

- The checkout is on `main`, clean, with all five recorded minimum competitive
  baseline capabilities implemented: standings (ESPN + NHL), bounded rich game
  detail drill-down (outcome + per-period lines), compact/full ambient bar
  modes with live-favorite rotation and countdown projection, wired per-league
  provider fallback chains, and opt-in pregame reminders plus close-game
  alerts.
- The provider-fallback wiring landed in `services/LeagueFetch.qml` via
  `providers/LeagueCatalog.js` `providerChain(leagueId)` and the accepted pure
  `model/ProviderFallbackPolicy.js`; health state is caller-owned and
  in-memory only. The deterministic suite passes with 210 tests; plugin
  validation, real-import-path QML lint (exit 0 with established warnings),
  and `git diff --check` pass; actual Omarchy runtime was verified with one
  healthy shell (`rtdjemiakt`, PID 904383), ping `ok`, toggle/hide exit 0,
  and a clean fresh log.
- Production chains are single-candidate today (`nhl` → NHL adapter, every
  other league → ESPN adapter); live multi-provider fallback is intentionally
  unexercised because no second verified adapter exists.
- Do not push or change remote state.

Bounded outcome:

Audit only — no source or behavior changes:

1. Verify each README behavior claim added during the baseline slices
   (standings, detail drill-down, calendar/filter, ambient bar presentation,
   notification preferences incl. pregame/close alerts, response bounds,
   provider fallback) matches the current sources and recorded acceptance
   evidence; correct only directly contradictory wording.
2. Reconcile the private competition backlog: mark closed gaps, list open ones
   (for example broader discovery refinements, specialist sport adapters,
   multi-provider chains requiring new verified adapters).
3. Produce a short owner-facing decision list of candidate next product
   slices with scope notes, so the next implementation unit has an explicit
   owner-selected outcome.

Required checks:

- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files if
  any documentation correction touches claims tied to those gates; otherwise
  rerun them once to record the unchanged baseline.
- No shell restart, rescan, or fresh log claim is required for a read-only
  audit unless a documentation correction changes a runtime-behavior claim
  that was never verified; in that case verify it on actual Omarchy before
  recording it.

Known risks and stop conditions: ESPN remains an undocumented API; live
multi-provider fallback cannot be exercised until a second verified adapter
exists; release metadata/tagging remain owner-controlled. Stop before any
feature implementation, settings schema change, endpoint addition, packaging,
tagging, pushing, release, or Marketplace work. If the audit finds a
contradiction that would require source changes to resolve, document the
finding and stop instead of expanding scope.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt reflecting the
owner's selected direction (or a blocked/decision-pending prompt if no
direction was given), and create one atomic Conventional Commit-style commit
only when all applicable gates pass. Request subagents only for independent
read-only reconnaissance; the main agent owns edits, validation, handoff, and
commit.
