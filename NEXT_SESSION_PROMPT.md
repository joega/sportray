Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: diagnose and remove the recorded `NotificationService` `games`
binding-loop warning on the `enabled-leagues-changed` path, while preserving
notification ownership, dedupe, favorite gating, and settings behavior.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md` (see
the "Runtime detail wiring + sport-aware scoring labels — 2026-08-24" handoff
and its binding-loop risk note), and `competition.md`.
`docs/upstream-contract.md` is intentionally absent in this checkout; inspect
installed Omarchy/Quickshell sources directly for any host-boundary claim and
record material deviations in `roadmap.md`. Inspect `git status`, the current
branch, and recent commits. Preserve unrelated user changes, including the
absence of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state (2026-08-24, after commits `3bdee00` and `4fa30b5`):

- `main` is clean and 2 commits ahead of `origin/main`. 222 deterministic
  tests pass; plugin validation, real-import-path `qmllint`, summon-helper
  tests, and `git diff --check` pass.
- The runtime game-detail path now carries the fixture-verified optional
  lines/stats/situation records (live-verified on an MLB drill-down), and the
  scoring header uses sport-aware Inning/Quarter/Half/Period labels.
- The binding loop: the installed shell logs `WARN scene: QML
  NotificationService at .../services/SportrayService.qml[65:3]: Binding loop
  detected for property "games"` pointing at `SportrayService.qml:68`
  (`games: root.selectedDateKey === root.todayDateKey ?
  fetchService.games : []`). It fired on `enabled-leagues-changed` events at
  2026-08-24 20:45, 20:57, and 21:24 EDT (instance started 20:23). It did not
  appear in fresh startup logs or during the detail-route exercise. Suspected
  mechanism: evaluating the `games` binding reaches `settingsStore` (e.g. a
  dedupe/state write or settings read inside `NotificationService`), which
  re-notifies `FetchService` bindings and re-evaluates the same `games`
  binding. Confirm the actual cycle from source before changing anything.

Bounded outcome:

One vertical slice: identify the exact cycle, break it at the smallest boundary
(e.g. pass a bounded, already-projected value into `NotificationService`, or
gate the write that re-enters the binding), and keep the singleton ownership
topology from `MonitorOwnership` intact. Keep any new decision logic in a pure
fixture-tested model under `model/` if behavior changes; do not change
notification text, dedupe fingerprints, schema-1 settings, provider parsing,
or polling cadence. If the cycle cannot be reproduced or confirmed from
source, record the evidence and stop without a speculative refactor.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: `omarchy-shell shell rescanPlugins` alone may NOT reload
  the linked plugin's singleton/fetch service (observed 2026-08-24); use
  `omarchy-restart-shell` for a definitive load. Confirm one healthy
  Quickshell instance and `shell ping` → `ok`. Exercise a settings change
  (toggle an enabled league or a notification preference) while games are
  loaded — that is the path that reproduced the warning — and inspect the
  fresh log: the binding-loop warning must be gone with no new Sportray
  error or exception.

Known risks and stop conditions: the loop involves the shared
`SportrayService` singleton, so a wrong fix could duplicate per-monitor state
or break notification dedupe — preserve the source-topology assertions in the
test suite. Do not "fix" it by disabling the warning or weakening the
notification gates. Gated owner-directed alternatives for later units: (a)
live scoring-play `competitions[].details` verification during real football
minutes (CFB week 0 from Sat Aug 29, NFL week 1 from Thu Sep 10; never outside
live minutes), and (b) a second verified provider adapter for multi-provider
fallback, which requires the owner's explicit terms/region/reliability review
of the candidate provider first. Stop before packaging, tagging, pushing,
releasing, or Marketplace work. Do not weaken acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status when the slice maps to a backlog line,
replace this file with the next self-contained single-unit prompt, and
create one atomic Conventional Commit-style commit only when all applicable
gates pass. Request subagents only for independent read-only reconnaissance;
the main agent owns edits, validation, handoff, and commit.
