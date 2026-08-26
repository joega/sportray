Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
begin **C4 — Calendar completion and polish** from
`LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including its latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt in full. `docs/upstream-contract.md` is intentionally absent;
inspect installed/current Omarchy and Quickshell sources directly for every
host-boundary claim. Inspect git status, branch, and recent commits; preserve
unrelated changes and the absence of `MARKETPLACE_SUBMISSION.md`.

Verified current state:

- C1, C2, and C3 are complete. C3 owns one low-frequency NHL schedule
  `Process`, uses `ChunkPolicy` for bounded seven-day chunks over the visible
  42-day month, keeps a three-window cache, and has no timer or notification
  route. Existing live league polling remains separate.
- `NhlProvider.js` normalizes schedule day buckets outside QML;
  `CalendarCachePolicy.js` preserves request/event/byte bounds, freshness, and
  explicit loading/partial/stale/empty/unavailable states. Late responses are
  generation-safe and unknown dates never become empty.
- Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 verification passed after the
  asynchronous rescan registration window settled: one shell, ping `ok`,
  rescan plus bounded summon helper (`unknown` during loading, then `ok`), and
  visible Sportray bar geometry. A fresh restart loaded the checkout.
  Calendar rendered a 42-cell September grid with `Unknown` unqueried dates;
  PageDown/PageUp rapid month replacement was exercised. The only fresh-log
  warning was the unrelated desktop-portal registration warning.
- Deterministic JavaScript tests pass with 242 tests; summon-helper,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  QML lint pass with established warnings.

Bounded outcome: complete only C4's remaining calendar verification/polish
slice—bounded league filtering, keyboard/accessibility routes, month/year
navigation, Today, favorites filtering, selected-day detail, partial-provider
failure, cache reuse, and removal/retirement of the old week strip only if no
consumer remains. Preserve the one-shell/no-second-process boundary and the
existing single calendar request owner.

Required checks: fixture-driven tests for every changed policy or route;
`./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path `qmllint` over every
QML file. On actual Omarchy, verify one-shell discovery, ping, summon, fresh
logs, pointer/keyboard/focus behavior, panel height and all bar edges. Do not
widen provider bounds, add schedule profiles, change live polling or
notifications, or begin watches, followed leagues, scoring/leaders,
broadcasts, packaging, release, push, or Marketplace work.

Known risks: ESPN capped/no-continuation ranges, CFB, NCAA Men's Basketball,
and MLB StatsAPI range hydration remain unsupported; partial coverage must stay
honest. The installed registration path is asynchronous, so use the supported
rescan/summon readiness sequence. Stop if C4 requires wider provider bounds,
destructive host changes, a second process, or a new unverified upstream API.

When the C4 gate passes, update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and
this prompt with dated evidence and risks, then create one atomic Conventional
Commit. If blocked, document the exact blocker in the roadmap and refresh this
prompt without creating a success commit.
