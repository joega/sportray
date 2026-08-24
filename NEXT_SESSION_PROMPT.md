Work in `/home/joeg/Projects/sportray` on the next bounded roadmap unit:
wire the accepted pure live-favorite rotation/cadence policy into one existing
ambient-bar presentation path for already normalized today-scoped state.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify every
Omarchy/Quickshell boundary against the installed Omarchy and Quickshell
sources. Inspect git status, the current branch, recent commits, the latest
ambient-bar handoff, `BarWidget.qml`, `Panel.qml`, `BarPresentation.js`,
`FavoritePresentation.js`, current polling models, fixtures, and tests.
Preserve unrelated changes.

Verified current state:

- `BarPresentation.js` now owns bounded full/tooltip precedence for the
  accepted countdown projection, and `BarWidget.qml` computes that projection
  only for the existing normalized `favorite-upcoming` state. Live-favorite
  priority, starting-soon behavior, compact/full mode selection, panel
  anchoring, and polling ownership remain unchanged.
- `LiveFavoriteRotationPolicy.js` is complete and fixture-tested but remains
  unwired. It accepts normalized today-scoped live/intermission favorite games,
  caller `nowMs`, and bounded cadence/item inputs; it does not own a timer,
  polling, provider parsing, settings, or QML state.
- The singleton `SportrayService` publishes caller-owned `nowMs` through its
  existing minute date-boundary timer. The countdown consumer uses that clock;
  do not add another timer or alter that service clock in this rotation unit.
- The current repository passes 182 deterministic JavaScript tests,
  `omarchy plugin validate "$PWD"`, real-import-path QML lint, and
  `git diff --check`. Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 revision
  `28771c7` has one running shell; the linked checkout rescanned, the bar IPC
  toggle/hide route completed, and the fresh log was free of Sportray
  exceptions, QML load failures, binding loops, and countdown errors.

Bounded outcome:

Use the accepted rotation policy in the same existing ambient-bar presentation
path so normalized today-scoped live favorite games can select a bounded live
favorite for the bar without changing the countdown precedence, favorite
selection semantics, compact/full mode, panel anchor, or polling ownership.
Pass caller-owned time/cadence inputs; do not make the policy or QML consumer
start a second timer or request new data. Keep provider parsing outside QML and
add fixture-driven tests for rotation precedence, empty/offline/non-today
fallbacks, and safe interaction with the existing countdown projection.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell sources first. Stop if reliable
  ambient-bar rotation requires a new upstream API, timer contract, or
  provider data; document the risk in `roadmap.md` and leave current bar
  behavior intact.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` command over every QML file, and `git diff --check`.
- Keep provider parsing outside QML and use sanitized fixture-driven tests.
- Do not add a second timer, settings field, provider endpoint/field, polling
  cadence, or unrelated QML interaction. If the existing caller cannot provide
  a sufficiently fresh rotation time without a new timer contract, stop and
  document that risk.
- Update `roadmap.md` with status, evidence, decisions, risks, and a dated
  handoff. Replace this file with the next single bounded prompt. Create one
  atomic Conventional Commit-style commit only after every gate passes.
  Request subagents only for independent read-only work that materially
  improves confidence.
