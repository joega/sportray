Work in `/home/joeg/Projects/sportray` on the next bounded roadmap unit:
add fixture-driven ambient priority transition coverage for the already wired
live-favorite rotation path.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify every
Omarchy/Quickshell boundary against installed Omarchy and Quickshell sources.
Inspect git status, current branch, recent commits, the latest ambient-bar
handoff, `BarWidget.qml`, `Panel.qml`, `BarPresentation.js`,
`FavoritePresentation.js`, the countdown and rotation policies, polling models,
fixtures, and tests. Preserve unrelated changes.

Verified current state:

- `Panel.qml` retains the existing `FavoritePresentation.selectBarState`
  result, passes normalized today-scoped games plus canonical favorites,
  `ambientTodayDateKey`, `selectedDateKey`, singleton `ambientNowMs`, and a
  caller-owned 60-second presentation cadence to
  `LiveFavoriteRotationPolicy.select`, then applies the result through
  `BarPresentation.applyLiveFavoriteRotation`.
- Rotation changes only `live-favorite-count` into the selected bounded
  `live-favorite` game. `favorite-upcoming` remains the only countdown state;
  empty/offline/non-today rotation results preserve the prior state. Compact/
  full mode, panel anchoring, and shared polling ownership are unchanged.
- `LiveFavoriteRotationPolicy.js` and `CountdownProjectionPolicy.js` are pure,
  fixture-tested policies. Neither owns time, timers, provider parsing,
  settings, polling, or QML state. The singleton service's existing minute
  timer is the only ambient time publication relevant to the bar.
- `fixtures/bar-presentation/policy.json` and `live-favorite-rotation.json`
  cover current selection and safe fallback behavior. The complete suite
  passes with 184 deterministic tests. Plugin validation, real-import-path
  QML lint, and diff check pass.
- Actual Omarchy 4.0.0-1 / Quickshell revision `28771c7` has one running shell;
  the linked checkout rescanned, toggle/hide IPC completed, and the fresh log
  contained no Sportray exception, QML load failure, binding loop, or
  rotation-related error.

Bounded outcome:

Add sanitized fixture-driven tests for three state transitions: the selected
rotation game advances at a caller `nowMs` cadence boundary, removal of all
live favorites returns to the existing favorite-upcoming/neutral selection,
and countdown projection reclaims precedence when the normalized state changes
from live to scheduled. Keep production behavior unchanged unless the tests
expose a concrete defect in the current model boundary.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell sources first. Stop and document the
  risk in `roadmap.md` if transition coverage reveals that reliable behavior
  needs a new timer contract, provider data, polling cadence, settings field,
  or upstream API; leave the current runtime path intact.
- Keep provider parsing outside QML and use sanitized fixtures. Do not add a
  timer, endpoint, field, setting, polling cadence, or unrelated UI work.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command
  over every QML file, and `git diff --check`. On Omarchy, rescan/exercise the
  existing bar route and inspect the fresh Quickshell log.
- Update `roadmap.md` with status, evidence, decisions, risks, and a dated
  handoff. Replace this file with the next self-contained single-unit prompt.
  Create one atomic Conventional Commit-style commit only after every gate
  passes. Request subagents only for independent read-only work that materially
  improves confidence.
