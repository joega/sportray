Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement **W3 — Watch UI and runtime** from `LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including its latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt. `docs/upstream-contract.md` is absent; inspect
installed/current Omarchy and Quickshell sources directly for every
host-boundary claim.

Verified current state:

- C1-C4, W1, and W2 are complete. W1 persists a bounded schema-1
  `watchedGames` projection; future-schema state remains exact opaque raw text
  and is never rewritten.
- `model/WatchPolicy.js` admits only canonical game identity, league, provider
  game ID, normalized start/created/expiry times, and active/expired state. It
  rejects malformed entries, deduplicates newest-by-created identity, caps
  watches at 32, applies terminal recovery when supplied a terminal game, and
  enforces a 30-day hard maximum.
- W2 extends only pure notification admission. Transition, pregame, and
  close-game alerts admit `favorite OR active unexpired watch`; malformed,
  removed, expired, and absent watches fail closed. Global/event settings,
  first-fetch silence, argument-array delivery, and persistent dedupe remain
  authoritative. Favorite/watch overlap produces one delivery.
- No watch UI, watch mutation action, provider fetching, polling, calendar
  ownership, followed-league behavior, or new notification type exists.
- Deterministic suite, summon-helper tests, diff check, plugin validation, and
  real-import-path QML lint pass. Installed Omarchy is 4.0.0-1 with Quickshell
  0.3.0 revision `28771c7c74b42e20afca0b1b63980cb46515537`.

Bounded outcome: add one semantic watch action usable from the existing game
row and local game-detail route, with active/inactive state, accessible name,
keyboard/pointer routing, safe disabled reasons, and persistence through the
existing SettingsStore/WatchPolicy boundary. Keep watch mutation separate from
notification admission and do not add provider fetching or polling. Exercise
one safe stubbed delivery path on actual Omarchy after the QML wiring is
complete.

Required checks: add fixture/source coverage for add/remove, canonical
identity, duplicate suppression, malformed/expired guards, settings repair and
future-schema opacity, accessibility action convergence, and restart-safe
state. Then run `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Because W3 changes QML, use one shell on actual Omarchy, restart/rescan only
through supported commands, exercise add/remove and one stubbed delivery, and
inspect a fresh Quickshell log for Sportray errors or binding loops.

Known risks: preserve the existing one-owner settings boundary; do not rewrite
future-schema state; do not start another Quickshell process; do not broaden
provider polling for a watched game; and do not create duplicate semantic
actions or notification deliveries. Request subagents only for independent
read-only accessibility or runtime review.

Stop if the watch action cannot remain bounded/provider-neutral, if persistence
or future-schema opacity regresses, if a row/detail route duplicates actions,
or if actual Omarchy exposes a host-boundary mismatch. When all gates pass,
update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and this prompt with dated
evidence, then create one atomic Conventional Commit. Do not push, tag,
release, publish, or perform Marketplace work.
