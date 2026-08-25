Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
Level the Field C3 — Low-frequency calendar fetch and cache.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including its latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt in full. `docs/upstream-contract.md` is intentionally absent;
inspect installed/current Omarchy and Quickshell sources directly for every
host-boundary claim. Inspect git status, branch, and recent commits; preserve
unrelated changes and the absence of `MARKETPLACE_SUBMISSION.md`.

Verified starting state:

- C1 is complete: Calendar is a Monday-first 42-cell month projection using
  existing five-date caches and the existing selected-date fetch route.
- C2 is complete: `model/ChunkPolicy.js` is pure and fixture-tested. It keeps
  the 2 MiB/256-event limits, one concurrent request, at most eight requests,
  a 42-day total window, and seven-day chunks for admitted profiles; ESPN MLB
  is one-day. ESPN CFB, ESPN NCAA Men's Basketball, and MLB StatsAPI range
  hydration remain unsupported.
- Reconnaissance is sanitized in `fixtures/provider-range/c2.json`: ESPN
  ranges had no continuation and observed 100-event caps for MLB/NBA/MLS;
  EPL returned 50 events; NHL returned seven `gameWeek` dates with
  `nextStartDate`; a 42-day MLB StatsAPI request exceeded 2 MiB. No raw body
  is in the repository.
- Runtime ownership is unchanged: `LeagueFetch.qml` still has two Process
  objects, two curl command arrays, zero timers, one in-flight per league, and
  a five-date live-score cache. The C1 month UI must remain honest for unknown
  or partial dates.

Concrete outcome: add one focused, low-frequency calendar schedule owner only
for a currently admitted provider profile, with bounded window caching,
provider parsing outside QML, generation-safe cancellation/late-response
rejection, and explicit stale/partial/empty/unavailable states. Reuse
`ChunkPolicy`; do not infer completeness from capped, off-season, unsupported,
or partial responses.

Hard scope limits:

- Do not widen byte, event, request, concurrency, or cache bounds.
- Do not enable ESPN CFB/NCAA Men's Basketball or MLB StatsAPI range fetching
  without new verified evidence; do not add endpoints, polling changes,
  settings schema 2, watches, followed leagues, scoring plays, leaders,
  broadcasts, packaging, release, or Marketplace work.
- Schedule hydration must not generate notifications or replace selected-day
  live-score ownership. Preserve the no-account/no-backend/no-daemon model.

Required checks: fixture-driven provider/cache/partial/late-response tests;
source assertions for ownership and bounds; `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path `qmllint` over every
QML file. Because this unit changes runtime ownership, on actual Omarchy also
confirm one shell, discovery, ping, summon, and fresh clean logs, plus the
changed behavior. Stop if current provider behavior no longer satisfies
`ChunkPolicy` or completeness cannot be represented honestly.

When the gate passes, update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and
this prompt with evidence and risks, then commit C3 atomically. Do not push or
make release/Marketplace changes. If blocked, leave C1 intact, document the
smallest blocker, refresh this prompt for that blocker, and do not create a
success commit.
