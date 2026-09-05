Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
manually exercise the visible closed-state ticket's remaining interaction and
state cases, making only the smallest correction justified by runtime evidence.
Do not alter Calendar behavior.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when absent, inspect installed/current Omarchy and Quickshell sources.

Verified current state:

- `BarWidget.qml` instantiates `TicketOverlay.qml` on the widget's actual screen.
  It is an always-mapped-while-closed `PanelWindow` with layer-shell keyboard
  focus `None` and an input mask limited to its visible card.
- Opening the normal score panel unmaps the ticket. The score panel remains the
  only `KeyboardPanel`; `SportrayService.qml` remains the sole data/fetch owner.
- Actual Omarchy showed the ticket directly below the top bar with a normalized
  final score. Toggle IPC removed its layer and mapped exactly one normal score
  panel without overlap.
- The linked checkout is the discovered plugin. A preserved same-ID backup was
  renamed to the hidden directory
  `~/.config/omarchy/plugins/.io.github.joega.sportray.backup-20260905-170100`
  because visible same-ID directories silently replace one another during the
  installed registry scan.
- Calendar remains disabled by the shared readonly feature flag. Do not change
  Calendar providers, cache, settings, routes, or hydration.

Bounded outcome: on actual Omarchy, click the ticket's primary surface and
confirm it opens the normal scores panel. Where a normalized safe game link is
present, exercise the labeled source action and confirm it does not also open
the score panel. Exercise empty/offline presentation only if it can be done
without weakening provider or persisted-state safety. Fix only a reproduced
ticket presentation or interaction defect. If a case cannot be exercised,
document the precise limitation instead of inferring success.

Required checks after any code change: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, installed-checkout production validation,
and `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Restart the actual shell, confirm one Quickshell instance, inspect relevant
`hyprctl layers` state and `qs log`, and do not claim a runtime pass without
that evidence.

Known risks: empty/offline states have not been manually forced; the source
action exists only for a safe normalized link; and a non-hidden same-ID backup
would again shadow the linked checkout. Request subagents only for independent
read-only work that materially benefits from parallelism.

When complete, update `README.md`, `roadmap.md`, `CHANGELOG.md`, and this prompt
with accurate evidence and limitations. Create one atomic Conventional Commit
only if a correction is made and all gates pass. Do not push or change remote
state.
