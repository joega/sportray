Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
implement **L2 — Followed-league settings and navigation UI** from
`LEVEL_THE_FIELD_SPRINT.md`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`
including the latest handoff, `competition.md`, `LEVEL_THE_FIELD_SPRINT.md`,
and this prompt. `docs/upstream-contract.md` is absent; inspect installed/current
Omarchy and Quickshell sources directly before any host-boundary edit.

Verified current state:

- L1 is complete in the committed tree. Settings schema remains version 1 and
  has the optional known field `followedLeagueIds`; legacy schema-1 state
  recovers to `[]` so migration never implicitly follows enabled leagues.
- `SettingsModel` exposes bounded canonical subset normalization plus pure
  toggle, move-up, move-down, and disable-cleanup helpers. Unknown, malformed,
  duplicate, disabled, and over-bound IDs fail closed.
- `StateModel` and `SettingsStore` persist the field through the existing
  permission and atomic-write boundary. Future schemas remain opaque and are
  never rewritten. No schema 2 was introduced.
- `PanelPresentation.build` accepts optional followed IDs and exposes stable
  followed-first league order plus Following sections that deduplicate game
  identities after favorite games. Existing favorite ordering remains
  dominant. No caller is wired to followed behavior yet.
- Deterministic suite passes with 253 tests; summon-helper, diff check,
  plugin validation, and real-import-path QML lint pass. L1 changed no runtime
  behavior, so no new Omarchy runtime claim exists.

Bounded outcome: add the user-facing Enable/Follow distinction and bounded
Move up/Move down settings actions, then apply the normalized followed order
to Following, league destinations, and the calendar filter. Reuse existing
semantic/accessibility and nested-pointer patterns. Do not add provider
fetching, polling, notifications, calendar ownership, watches, scoring or
leaders, broadcasts, packaging, release, push, or Marketplace work.

Required checks: add fixture/source coverage for enable-versus-follow
distinction, keyboard/pointer/Accessible action convergence, disabled-league
cleanup, followed-first destination order, calendar-filter order, focus/state
refresh, and no duplicate Following games. Run `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Because L2 changes QML, perform the actual Omarchy one-shell restart/rescan/
summon, exercise pointer, keyboard, Accessible, focus, and edge placement
paths, inspect fresh Quickshell logs, and record exact host evidence.

Known risks and stop conditions: do not implicitly follow enabled leagues,
merge following with favorite teams or watches, retain disabled ghost IDs,
create duplicate rows, add a second polling/fetch owner, or bypass future-
schema opacity. Stop if the installed semantic/accessibility or panel-height
boundary cannot support the actions without a new unverified host API. Request
subagents only for independent read-only QML/source or fixture review.

When the gate passes, update `LEVEL_THE_FIELD_SPRINT.md`, `roadmap.md`, and
this prompt with dated evidence, then create one atomic Conventional Commit.
Do not push, tag, release, publish, or perform Marketplace work.
