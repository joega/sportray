Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement **L1 — Followed and ordered league intent model** from
`LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including the latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt. `docs/upstream-contract.md` is absent; inspect installed/current
Omarchy and Quickshell sources directly for every host-boundary claim.

Verified current state:

- C1-C4 and W1-W3 are complete. Calendar is a 42-cell bounded month view;
  watches persist in schema 1 and use canonical `<league>:<providerGameId>`
  identity; notification admission accepts favorite OR active unexpired watch.
- W3 adds `components/WatchAction.qml`, shared by score rows and local detail.
  `SettingsStore.toggleWatch` is the only watch mutation owner and preserves
  permission repair and future-schema opacity. No watch adds provider fetching
  or polling.
- The current settings state remains schema 1 with enabled leagues, favorite
  teams, notifications, transition dedupe, and bounded watched games. There is
  no followed-league field or schema-2 migration yet.
- Deterministic suite, summon-helper tests, diff check, plugin validation, and
  real-import-path QML lint pass. Actual Omarchy is 4.0.0-1 with Quickshell
  0.3.0 revision `28771c7c74b42e20afca0b1b63980cb46515537`; one shell was
  verified after supported restart/rescan/summon. Direct child-panel pointer
  injection is unavailable in the current host session.

Bounded outcome: add only the pure followed-league intent/order model required
by the L1 section. Decide and document the schema-1-to-followed-league
behavior explicitly before changing state: migration must start with no
followed leagues, unknown/duplicate/disabled IDs must fail closed, and the
ordered list must remain bounded and canonical. Extend pure presentation
projection only enough to prove stable followed ordering and game dedupe; do
not add settings UI, league navigation changes, provider fetching, polling,
notifications, calendar ownership, watch changes, scoring/leaders, broadcasts,
packaging, release, push, or Marketplace work.

Required checks: add fixture-driven tests for normalization, migration,
subset enforcement, dedupe, bounds, stable ordering, and no duplicate games.
Run `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file if
any QML changes occur. Inspect installed/current host sources before any
boundary edit. This pure-model unit does not claim an Omarchy runtime pass
unless QML/runtime behavior actually changes and is exercised on the real
single-shell environment.

Known risks and stop conditions: do not silently introduce schema 2, implicitly
enable a disabled league, treat following as team favorites, duplicate a game
across Following sections, broaden provider work, or rewrite future-schema
state. Stop if the migration boundary cannot remain backward-compatible and
bounded, or if followed ordering requires UI/fetch ownership beyond L1.
Request subagents only for independent read-only model/fixture review.

When the gate passes, update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and
this prompt with dated evidence, then create one atomic Conventional Commit.
Do not push, tag, release, publish, or perform Marketplace work.
