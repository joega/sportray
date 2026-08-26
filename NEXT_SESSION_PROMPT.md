Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement **W2 — Notification admission** from `LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including its latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt. `docs/upstream-contract.md` is absent; inspect installed/current
Omarchy and Quickshell sources directly for any host-boundary claim. Inspect
git status, branch, and recent commits; preserve unrelated changes and the
absence of `MARKETPLACE_SUBMISSION.md`.

Verified current state:

- C1-C4 and W1 are complete. W1 is a bounded watch policy and durable-state
  projection in the existing schema-1 state file.
- `model/WatchPolicy.js` admits only canonical game identity, league, provider
  game ID, normalized start/created/expiry times, and active/expired state. It
  rejects malformed entries, deduplicates newest-by-created identity, caps
  watches at 32, applies a six-hour terminal recovery window when supplied a
  terminal normalized game, and applies a 30-day hard maximum.
- `StateModel.js` and `services/SettingsStore.qml` persist `watchedGames` as a
  bounded known schema-1 field. Future schema state remains exact opaque raw
  text, uses safe defaults, and is never rewritten.
- W1 added no UI, notification admission, provider parsing, fetching, polling,
  calendar ownership, or followed-league behavior.
- Deterministic suite, summon-helper tests, diff check, plugin validation, and
  real-import-path QML lint pass. Actual Omarchy 4.0.0-1 / Quickshell 0.3.0
  revision `28771c7c74b42e20afca0b1b63980cb46515537` was restarted with one
  shell; summon returned `ok` and fresh logs were clean of Sportray errors.
  The unrelated desktop-portal warning remains.

Bounded outcome: extend only the existing pure notification admission policy
so a normalized event is eligible when its game is a favorite team OR an
active explicitly watched game. Preserve one delivery when both match,
stop watch-derived admission after removal/expiry, retain favorite-derived
admission, and keep global/event notification settings authoritative. Reuse
existing transition detection, sanitization, argument-array delivery, and
persistent dedupe. Do not add watch UI, provider fetching, polling changes,
new notification types, followed leagues, scoring/leaders, broadcasts,
packaging, release, push, or Marketplace work.

Required fixture checks: favorite-only, watch-only, both without duplicate
delivery, removed watch, expired watch, malformed watch, restart-safe active
watch, disabled global/event settings, first-fetch silence, and no calendar
hydration admission. Then run `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
If QML or host wiring changes, use one shell on actual Omarchy and inspect a
fresh log; otherwise runtime shell exercise is not required.

Stop if active-watch identity cannot remain bounded/provider-neutral, if
future-schema state would be rewritten, if favorite/watch admission produces
duplicate deliveries, or if notification settings can bypass the gate. Update
the sprint, roadmap, and this prompt with dated evidence and create one
atomic Conventional Commit only after all gates pass. Request subagents only
for independent read-only policy or test review.
