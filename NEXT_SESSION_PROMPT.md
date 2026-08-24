Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
wire the accepted pure `ProviderFallbackPolicy` contract into the existing
per-league fetch boundary so per-league provider fallback decisions flow
through `services/LeagueFetch.qml` and the shared scheduler, without changing
endpoints, request paths, polling cadence bounds, the settings schema, or any
QML view.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and
the latest handoff. `docs/upstream-contract.md` is intentionally absent in
this checkout; inspect the installed Omarchy and Quickshell sources directly
for any host-boundary claim and record any material deviation in `roadmap.md`
and later the README. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The checkout is on `main`, clean, with `HEAD` at or beyond the 2026-08-24
  provider-fallback chain policy handoff; `origin/main` lags locally. Do not
  push or change remote state.
- `model/ProviderFallbackPolicy.js` is implemented, fixture-covered, and
  accepted: ordered unique candidates (max four, first is primary), failure
  threshold 3, 15-minute cooldown retry, deterministic
  `primary`/`current`/`fallback`/`exhausted`/`invalid` results, and pure
  `recordFailure`/`recordSuccess` helpers. It has no consumer yet.
- The deterministic suite passes with 205 tests; plugin validation,
  real-import-path QML lint (exit 0 with established warnings), and
  `git diff --check` all pass as of that handoff.
- Per-league fetch ownership lives in `services/LeagueFetch.qml` and the
  shared scheduler; providers live only in `providers/`. Provider parsing
  must stay out of QML per the architecture guardrails. The existing
  last-good snapshot and isolated league-failure behavior must be preserved.

Bounded outcome:

Give each league a caller-owned fallback chain (league id plus ordered
provider candidate list) and a caller-owned health state store; evaluate
`ProviderFallbackPolicy.evaluate` before each per-league request, record
failures/successes through the pure helpers after responses, honor
`exhausted` as the existing unavailable/stale state with its last-good
snapshot intact, and keep all provider parsing inside `providers/`. Add
fixture-driven tests for the wired decisions (stay on healthy primary,
fallback after recorded failures, cooldown retry, exhausted isolation beside
a healthy sibling league) without weakening or skipping an existing gate.
Do not add settings fields, timers, endpoints, leagues, packaging, or new
QML views in this unit.

Required checks:

- Run `./tests/run-js-tests.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files.
- Because this unit changes a service/QML boundary, rescan the linked plugin
  on actual Omarchy (or use the supported `omarchy restart shell` if rescan
  leaves a stale widget), confirm one Quickshell instance and shell ping `ok`,
  exercise toggle/hide, and inspect a fresh log for no Sportray exception,
  QML load failure, binding-loop warning, or fetch-path regression.

Known risks and stop conditions: ESPN remains an undocumented API; the
installed host may require a full shell restart to load edited QML; pointer
injection remains unavailable, so runtime claims should use keyboard/IPC
evidence only. Stop before changing request paths or endpoints, adding
leagues or settings persistence, altering documented polling cadence bounds,
packaging, tagging, pushing, release, or Marketplace work. If the wiring
cannot preserve the existing last-good/isolation behavior, stop and document
the blocker instead of expanding scope.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit only when all applicable gates pass.
Request subagents only for independent read-only reconnaissance; the main
agent owns edits, validation, handoff, and commit.
