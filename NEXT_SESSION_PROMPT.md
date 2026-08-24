Work in `/home/joeg/Projects/sportray` on the next bounded product unit:
implement one fixture-driven compact/full ambient bar presentation policy for
the existing normalized game state, preserving today focus and current bar
priority/polling boundaries.

Before any edit, read `AGENTS.md`, `README.md`,
`docs/upstream-contract.md`, `roadmap.md`, and this latest handoff. This
checkout intentionally has no `docs/upstream-contract.md`; verify any
Omarchy/Quickshell boundary against installed Omarchy and Quickshell sources.
Inspect git status, the current branch, recent commits, the game-detail handoff,
`BarWidget.qml`, `Panel.qml`, the current bar-priority/formatting models,
fixtures, and tests. Preserve unrelated changes.

Verified current state:

- The existing scores panel has a local keyboard-accessible game-detail route
  backed by `GameDetailModel`; its source action remains the guarded
  `omarchy-launch-browser` route.
- The existing normalized game shape and `FavoritePresentation.selectBarState`
  already drive the ambient bar indicator. Existing provider polling, caching,
  favorites, and notification boundaries are complete and fixture-tested.
- The previous unit passes the full JavaScript suite with 168 tests,
  `omarchy plugin validate`, real-import-path QML lint, and `git diff --check`.
  Actual Omarchy 4.0.0-1 / Quickshell 0.3.0.r20 was manually exercised and the
  current runtime is one shell instance.

Bounded outcome:

Add a pure, provider-neutral policy/model fixture slice for two bounded ambient
bar presentation modes (compact and full), then wire only the existing
`BarWidget.qml` consumer to that policy. Preserve the current favorite-first
selection, stable today focus, neutral fallbacks, and bounded text behavior.
Add fixture-driven tests for mode selection, long labels, empty/offline states,
and the existing live/favorite priority. Keep provider parsing outside QML.

Do not add live rotation, countdown scheduling, new provider fields or
endpoints, alerts, new leagues, provider fallback, niche adapters, settings
schema changes, packaging, tagging, pushing, release, or Marketplace work.
Stop if a reliable mode requires an upstream shell contract beyond the current
installed bar/widget sources; document that risk in `roadmap.md` and leave the
existing bar behavior intact.

Required checks and stop condition:

- Inspect installed Omarchy/Quickshell bar/widget sources before changing any
  QML boundary.
- Run `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `qmllint` command over every QML file, and `git diff --check`.
- Because the bar consumer changes, rescan the linked plugin on actual Omarchy,
  inspect the fresh Quickshell log, and manually exercise both modes. Do not
  report an Omarchy check as passing unless it actually ran there.
- At completion, update `roadmap.md` with status, evidence, decisions, risks,
  and a dated handoff; replace this file with the next single bounded prompt;
  and create one atomic Conventional Commit-style commit only after every gate
  passes. Use subagents only for independent read-only work that materially
  improves confidence.
