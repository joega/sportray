Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
review the completed ticket-panel integration and take the next owner-directed
unit without changing Calendar behavior.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when absent, inspect installed/current Omarchy and Quickshell sources.

Verified current state:

- Calendar remains disabled in production by the shared readonly feature flag.
- `Panel.qml` admits deferred result-list callbacks through a plain-JS
  lifecycle token and a current-object identity check; preserve this guard.
- `TicketStrip.qml` is integrated into the existing `Panel.qml` KeyboardPanel
  surface for the closed-state ambient ticket; its primary action opens the
  normal panel. `BarWidget.qml` does not create a second TicketOverlay.
- `SportrayService.qml` remains the shared singleton owner of ambient game and
  ticket state. Preserve existing keyboard routes, Escape/focus, lifecycle,
  accessibility, and vertical fallback behavior.
- The deferred lifecycle fix and ticket integration passed JS tests, summon
  helper tests, diff check, plugin validation, real-import-path QML lint, and
  actual Omarchy rescan/restart/ping/summon/log checks.

Bounded outcome: choose and complete the next single roadmap unit after reading
the latest handoff. Keep the production Calendar flag false and avoid Calendar
source/provider/cache/settings changes. Stop and document the precise blocker
if a required gate fails.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, installed-checkout
production validation, and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
over every QML file. If runtime behavior changes, rescan/restart the actual
Omarchy shell, exercise the relevant IPC, and inspect `qs log`; do not claim a
runtime pass without that evidence.

Known risks: Calendar is intentionally dormant; ESPN remains undocumented;
the worktree is dirty with unrelated ticket/calendar changes; and lifecycle
callbacks must not capture destroyed QML objects. Request subagents only for
independent read-only work that materially benefits from parallelism.

When complete, update `roadmap.md` with evidence and a dated handoff, replace
this prompt with the next self-contained prompt, rerun the required checks, and
create one atomic Conventional Commit only when its gate passes. Do not push or
change remote state.
