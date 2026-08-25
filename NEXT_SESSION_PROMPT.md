Work in `/home/joeg/Projects/sportray` on one bounded work unit only.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed/current Omarchy and
Quickshell sources directly for any host-boundary claim and record material
deviations in `roadmap.md`. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Current verified state after the 2026-08-25 detail presentation cleanup:

- `main` contains committed MLB StatsAPI fallback `cb53ded` (`feat: add MLB
  StatsAPI fallback`). The adapter is fixture-verified for scheduled, live,
  final, administrative, malformed, and empty/offseason states. MLB's chain is
  `['espn', 'mlb-stats']`; all other provider chains are unchanged.
- The deterministic suite has 231 passing tests. Summon-helper checks, plugin
  validation, real-import-path QML lint, and `git diff --check` pass.
- `model/Formatters.js` now owns bounded detail-status and detail-timing
  presentation formatters. `components/GameDetailView.qml` uses them so
  duplicate labels such as `Scheduled · Scheduled` collapse to `Scheduled`,
  missing status detail has no trailing `· —`, and absent timing renders as
  `Timing unavailable` or a clean partial start/end label. No provider,
  normalized field, polling, settings, notification, or routing behavior
  changed. The route fixture and deterministic tests cover the new cases.
- Installed Omarchy `4.0.0-1` and Quickshell `0.3.0` revision
  `28771c7c74b42e20afca0b1b63980cb46515537` were inspected directly. The
  current `Panel.settings`, `KeyboardPanel`, `Process`, `SplitParser`, and
  `StdioCollector` contracts remain the verified host boundaries; no material
  upstream deviation was found.
- Actual Omarchy verification after the QML change used one shell instance
  (`hpznhufckt`, PID 1119365): `shell ping` and the summon helper returned `ok`.
  The real keyboard path opened the BOS at MIA details card and the inspected
  render showed one `Scheduled` label and a single start-time line. The fresh
  log had normal polling and no Sportray exception, QML-load error, or
  binding-loop warning; the unrelated portal registration warning remains.
- At 2026-08-25 14:53:54 EDT, ESPN NFL returned 16 events all in `post` state,
  and ESPN college football returned 25 events all in `pre` state. No event was
  in progress, so `competitions[].details`, `weather`, and `leaders` were not
  inspected. No raw payload was stored.
- A follow-up read-only check at 2026-08-25 15:12:41 EDT returned the same
  bounded state: 16 NFL `post` events, 25 college-football `pre` events, and
  zero events in state `in`. No live field shape was inferred or recorded.
- A third read-only check at 2026-08-25 16:23:31 EDT again returned 16 NFL
  `post` events and 25 college-football `pre` events, with zero events in
  state `in`. No `details`, weather, or leaders fields were inspected and no
  raw payload was retained.
- Live fallback selection remains fixture-verified only. ESPN/static MLB
  team-id drift for ATL, DET, LAA, MIA, MIL, MIN, PHI, SF, STL, and TB remains
  unresolved and must not be changed. The owner's current MLB favorite is
  `mlb:2` (BOS).

Bounded outcome: during the next actual live-football minutes, beginning with
the first CFB week-0 game from 2026-08-29 or NFL week 1 from 2026-09-10,
perform one read-only observation of the documented ESPN NFL and
college-football scoreboard payloads. Proceed only if at least one event has
status state `in`.
For each live event, inspect bounded shape summaries for:

- `competitions[].details`;
- `competitions[].weather`;
- `competitions[].leaders`, only when a group contains athlete entries.

Do not add or modify providers, parsing, endpoints, polling, settings,
notifications, catalogs, fixtures, QML, normalized fields, release state, or
team-id mappings. Do not store raw provider payloads. If no NFL or college
football game is live, record the missed window in `roadmap.md` and
`competition.md` if applicable, then stop without inferring field behavior.

Required checks after the observation:

- `./tests/run-js-tests.sh`
- `./tests/test-summon-helper.sh`
- `git diff --check`
- `omarchy plugin validate "$PWD"`
- `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file

At the end, append a dated evidence/handoff entry to `roadmap.md`, update the
matching `competition.md` backlog line if applicable, and replace this prompt
with the next self-contained single-unit prompt. A pure observation creates no
success commit; a source-changing unit is out of scope. Stop before provider
fallback injection, MLB/static-catalog drift reconciliation, packaging,
tagging, pushing, release, or Marketplace work.
