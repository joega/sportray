Work in `/home/joeg/Projects/sportray` on one bounded work unit only.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed/current Omarchy and
Quickshell sources directly for any host-boundary claim and record material
deviations in `roadmap.md`. Inspect `git status`, the current branch, and recent
commits. Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Current verified state after the 2026-08-25 MLB StatsAPI second-candidate unit:

- `main` has the completed local adapter changes but they are not yet committed
  in this work unit. The MLB owner review gate is resolved: MLB terms framing
  accepted, MLB selected as the first second-candidate league, and explicit
  team-id translation accepted.
- `providers/MlbStatsProvider.js` parses the key-free MLB schedule route,
  translates all 30 MLB StatsAPI team ids to the current ESPN id space, rejects
  unknown ids, and handles scheduled, live, final, administrative, malformed,
  and empty/offseason responses. `LeagueCatalog.providerChain('mlb')` is
  `['espn', 'mlb-stats']`; all other chains are unchanged.
- `LeagueFetch.qml` has only the new provider URL/parser branches. Response
  admission remains 2 MiB transport, bounded streamed text, and 256 events;
  lookahead remains on ESPN. The shared game-link boundary admits `mlb.com`.
- The deterministic suite passes with 230 tests. Summon-helper tests, plugin
  validation, real-import-path QML lint, and diff check pass. Actual Omarchy
  restart/ping/toggle/hide passed with one shell and a clean fresh Sportray log.
- No forced ESPN failure was injected, so live fallback selection remains
  fixture-verified rather than runtime-claimed. No owner enabled-league or
  favorite setting was changed; the current MLB favorite is `mlb:2` (BOS).
- A pre-existing live-provider drift was observed: current ESPN scoreboard and
  team-catalog endpoints assign different ids from the checked-in static MLB
  `EspnTeamCatalog` for ATL, DET, LAA, MIA, MIL, MIN, PHI, SF, STL, and TB.
  The adapter targets the current live ESPN id space. Do not reconcile that
  drift, migrate persisted favorites, or alter the static catalog in this unit.

Bounded outcome: perform one observational football-payload verification during
actual live football minutes only. Fetch only the documented ESPN NFL and
college-football scoreboard endpoints while at least one event has status `in`.
Record field names and bounded shape summaries for:

- `competitions[].details` (scoring-play candidate);
- `competitions[].weather`; and
- `competitions[].leaders`, only if any group contains athlete entries.

Do not add an adapter, provider field, endpoint, fetch path, fixture, QML view,
timer, setting, notification, or catalog migration during this observational
unit. If `details` is absent during live play, close the scoring-play idea under
the current single-endpoint boundary. If weather or leaders are absent or
empty, record that exact result. Do not store raw provider payloads in the
repository. If no football game is live, record the missed window and stop.

Timing: CFB week 0 begins Sat Aug 29, 2026; NFL week 1 begins Thu Sep 10, 2026.
Outside live-football minutes, do not infer a different feature direction. If
the owner explicitly selects another `competition.md` slice, stop and obtain
that direction before editing.

Required checks for the observational outcome, rerun to record the unchanged
baseline:

- `./tests/run-js-tests.sh`
- `./tests/test-summon-helper.sh`
- `git diff --check`
- `omarchy plugin validate "$PWD"`
- `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file

No repository QML/service source should change in this unit. If an owner later
authorizes a different unit that changes QML/service code, use the actual
Omarchy restart boundary, confirm one shell and `shell ping` -> `ok`, exercise
the changed behavior, and inspect a fresh log. Do not toggle the owner's
enabled leagues or favorites for testing.

At the end, append a dated evidence/handoff entry to `roadmap.md`, update the
matching `competition.md` backlog line if applicable, replace this prompt with
the next self-contained single-unit prompt, and create one atomic
Conventional Commit-style commit only when a source-changing unit passes all
gates. A pure observational result records evidence and creates no success
commit. Stop before provider fallback injection, catalog identity migration,
packaging, tagging, pushing, release, or Marketplace work.
