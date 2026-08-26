Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
complete **L3 — followed-league runtime and documentation verification** from
`LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including the latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt. `docs/upstream-contract.md` is absent; inspect installed/current
Omarchy and Quickshell sources directly before any host-boundary edit.

Verified current state:

- L1 and L2 are complete in the committed tree. Schema 1 remains compatible;
  `followedLeagueIds` is bounded, canonical, deduplicated, and intersected
  with enabled leagues. Legacy schema-1 state still starts with no followed
  leagues and future schemas remain opaque.
- Sports settings visibly distinguish Enable/Disable from Follow/Following.
  Follow is disabled for disabled leagues. Move up/down controls are bounded
  by normalized followed position and use the existing `SettingsStore` write
  boundary.
- Keyboard cursor activation, pointer press, and the shared Qt Accessible
  semantic-button route converge on the same settings actions. Settings
  revision invalidation refreshes labels and enabled states.
- Following sections and league destinations use followed-first order after
  favorite games; the calendar league filter cycles in that same order.
  Favorite-first ordering and canonical Following deduplication are unchanged.
- README documents the enabled-versus-followed distinction. No provider,
  fetch, polling, notification, watch, calendar-fetch, or new host API was
  added.
- Deterministic suite passes with 254 tests; summon-helper, diff check,
  plugin validation, and real-import-path QML lint pass. The lint command
  exits 0 with established standalone host/import warnings.
- A 2026-08-25 local-time Omarchy restart/rescan left exactly one shell and
  normal Sportray logs, but summon reported `no live bar widget for:
  io.github.joega.sportray`; direct UI interaction was not completed or
  claimed. Re-establish a live registered widget before exercising controls.

Bounded outcome: on actual Omarchy, verify the live Sportray bar widget and
exercise Enable, Follow, Move up, Move down, disable cleanup, persistence
across restart, followed-first Following/destination/calendar order, focus
refresh, no duplicate Following rows, pointer, keyboard, Accessible, and
top/bottom/left/right edge placement. If the widget cannot be registered,
diagnose only the existing registration/lifecycle boundary and stop without
changing provider or host APIs. Do not add schema migration, fetching,
polling, notifications, watches, scoring, leaders, broadcasts, packaging,
release, push, or Marketplace work.

Required checks: run `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
On actual Omarchy, perform a supported one-shell restart/rescan/summon,
confirm one shell, exercise the listed interactions, and inspect fresh
Quickshell logs for Sportray errors, exceptions, binding loops, or duplicate
graphs. Restore any temporary settings to their original values.

Known risks and stop conditions: do not claim a manual interaction when no
live widget is registered; do not leave followed IDs for disabled leagues;
do not infer UI success from an IPC `ok` that accompanies `no live bar widget`;
do not add a second polling/fetch owner or bypass future-schema opacity. Stop
if the installed registration, semantic/accessibility, focus, or panel-height
boundary cannot support the checks without a new unverified host API. Request
subagents only for independent read-only registration/log or fixture review.

When the runtime gate passes, update `LEVEL_THE_FIELD_SPRINT.md`,
`roadmap.md`, and this prompt with dated evidence, then create one atomic
Conventional Commit. If blocked, record the exact blocker and leave the next
prompt ready without marking L3 complete. Do not push, tag, release, publish,
or perform Marketplace work.
