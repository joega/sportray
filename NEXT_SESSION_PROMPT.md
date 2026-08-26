Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement **W1 — Watch policy and durable-state integration** from
`LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including its latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt in full. `docs/upstream-contract.md` is intentionally absent;
inspect installed/current Omarchy and Quickshell sources directly for any
host-boundary claim. Inspect git status, branch, and recent commits; preserve
unrelated changes and the absence of `MARKETPLACE_SUBMISSION.md`.

Verified current state:

- C1, C2, C3, and C4 calendar work are complete in the current checkout.
- C4 adds a bounded enabled-league calendar filter and `L`/`l` keyboard
  routing. The 42-cell month surface, selected-day route, filters, detail
  route, and calendar schedule owner are already present and runtime-verified.
- Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` has one shell. The symlinked
  checkout registers after the supported restart/rescan lifecycle; discovery,
  ping, rescan, and bounded summon all return `ok`, and the visible right-bar
  widget is 27x26. Fresh logs are clean apart from the unrelated desktop-
  portal registration warning. Direct pointer-click injection was unavailable
  in the prior session, so do not claim it as runtime evidence without a
  real injector.
- The private handoff/source changes from C4 are currently uncommitted and
  must be preserved while starting W1. No watch state, notification admission,
  or settings-schema change has been made yet.

Bounded outcome: add only the pure watch normalization, bound, expiry, dedupe,
and durable-state integration required by W1. Consume the already-landed
shared settings-schema migration if present, preserve schema-1 round trips and
future-schema opacity, and cap watched games at 32. Store only canonical game
identity, league, needed provider game ID, normalized start/created times, and
expiry state. Do not add row/UI actions, notification admission, provider
fetching, broader polling, calendar ownership, followed leagues, scoring or
leader detail, broadcasts, packaging, release, push, or Marketplace work.

Required checks: fixture-driven policy/state tests covering malformed entries,
duplicate identities, the 32-item bound, postponement and clock-skew expiry,
terminal recovery expiry, restart-safe active watches, schema-1 preservation,
future-schema opacity, and no raw provider fields; then rerun
`./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Runtime shell exercise is not expected unless W1 changes QML or host wiring;
if it does, use one shell only and inspect fresh logs.

Stop if the existing settings migration is not sufficient without changing
the planned schema boundary, if future-schema state would be rewritten, or if
watch identity/expiry cannot remain bounded and provider-neutral. Do not widen
scope to W2 notification admission. When the W1 gate passes, update
`LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and this prompt with dated evidence,
refresh the next prompt for W2, and create one atomic Conventional Commit.
Request subagents only for independent read-only policy/schema review; do not
parallelize edits to shared settings or notification state.
