Work in `/home/joeg/Projects/sportray` on the next bounded roadmap unit:
add one pure, fixture-driven countdown projection policy for already normalized
today-scoped favorite upcoming games.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify every
Omarchy/Quickshell boundary against the installed Omarchy and Quickshell
sources. Inspect git status, the current branch, recent commits, the latest
ambient-bar handoff, `BarWidget.qml`, `Panel.qml`, `BarPresentation.js`,
`FavoritePresentation.js`, current polling models, fixtures, and tests.
Preserve unrelated changes.

Verified current state:

- `BarPresentation.js` and `LiveFavoriteRotationPolicy.js` are complete and
  fixture-tested. Horizontal/top bars use full bounded `WidgetButton` text;
  vertical/left/right bars use compact icon-only `BarIconButton` presentation.
  The rotation policy is not wired to QML and accepts only normalized,
  today-scoped live favorite state plus caller-supplied bounded time/cadence.
- `BarWidget.qml` remains the only policy consumer. It receives the existing
  panel projection and keeps the popup anchor, favorite-first state, today
  focus, and current polling boundaries intact.
- The current repository passes 176 deterministic JavaScript tests,
  `omarchy plugin validate "$PWD"`, real-import-path QML lint, and
  `git diff --check`. Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 revision
  `28771c7` has one running shell; the last rescan and top/left manual routes
  were clean, and the user bar position is restored to `top`.

Bounded outcome:

Implement only a provider-neutral pure policy that projects a bounded
countdown label/state for an already normalized favorite upcoming game using
caller-supplied `nowMs` and start-time inputs. Use fixtures to cover future,
due, invalid, empty/offline, and bounded text behavior while preserving the
local today identity. Do not start timers, add live polling, request provider
countdown data, add provider fields or endpoints, change settings schema, or
wire a QML consumer in this unit.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell sources first. Stop if a reliable
  countdown projection requires an upstream API or new provider data; document
  the risk in `roadmap.md` and leave current bar behavior intact.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` command over every QML file, and `git diff --check`.
- Keep provider parsing outside QML and use sanitized fixture-driven tests.
- Update `roadmap.md` with status, evidence, decisions, risks, and a dated
  handoff. Replace this file with the next single bounded prompt. Create one
  atomic Conventional Commit-style commit only after every gate passes.
  Request subagents only for independent read-only work that materially
  improves confidence.
