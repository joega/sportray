Work in `/home/joeg/Projects/sportray` on the next bounded roadmap unit:
wire the accepted pure countdown projection into one existing ambient-bar
presentation path for already normalized today-scoped favorite upcoming state.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify every
Omarchy/Quickshell boundary against the installed Omarchy and Quickshell
sources. Inspect git status, the current branch, recent commits, the latest
ambient-bar handoff, `BarWidget.qml`, `Panel.qml`, `BarPresentation.js`,
`FavoritePresentation.js`, current polling models, fixtures, and tests.
Preserve unrelated changes.

Verified current state:

- `BarPresentation.js`, `LiveFavoriteRotationPolicy.js`, and
  `CountdownProjectionPolicy.js` are complete and fixture-tested. Horizontal/
  top bars use full bounded `WidgetButton` text; vertical/left/right bars use
  compact icon-only `BarIconButton` presentation. Rotation and countdown
  policies are not yet wired to QML and accept only normalized today-scoped
  state plus caller-supplied bounded time inputs.
- `BarWidget.qml` remains the only policy consumer. It receives the existing
  panel projection and keeps the popup anchor, favorite-first state, today
  focus, and current polling boundaries intact.
- The current repository passes 180 deterministic JavaScript tests,
  `omarchy plugin validate "$PWD"`, real-import-path QML lint, and
  `git diff --check`. Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 revision
  `28771c7` has one running shell; the last rescan and top/left manual routes
  were clean, and the user bar position is restored to `top`.
- `model/CountdownProjectionPolicy.js` projects `future`, `due`, `invalid`,
  `empty`, `offline`, and `not-today` states with bounded labels and preserved
  local date identity. It does not call `Date.now()`, start timers, select
  games, poll, or request provider data.

Bounded outcome:

Use the accepted policy in one existing ambient-bar presentation path so a
selected normalized today-scoped favorite upcoming game can expose its bounded
countdown label/state while live-favorite priority and compact/full mode
selection remain unchanged. Pass caller-owned current time; do not make the
policy or QML consumer start a timer or request new data. Keep provider parsing
outside QML and preserve the existing bar/panel/polling ownership boundaries.
Add fixture-driven tests for the changed presentation precedence and safe
future/due/empty/offline states.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell sources first. Stop if a reliable
  ambient-bar countdown requires a new upstream API, timer contract, or
  provider data; document the risk in `roadmap.md` and leave current bar
  behavior intact.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` command over every QML file, and `git diff --check`.
- Keep provider parsing outside QML and use sanitized fixture-driven tests.
- Do not add a new settings field, provider endpoint/field, polling cadence,
  live rotation timer, or unrelated QML interaction. If the existing caller
  cannot provide fresh time without a new timer, stop and document that risk.
- Update `roadmap.md` with status, evidence, decisions, risks, and a dated
  handoff. Replace this file with the next single bounded prompt. Create one
  atomic Conventional Commit-style commit only after every gate passes.
  Request subagents only for independent read-only work that materially
  improves confidence.
