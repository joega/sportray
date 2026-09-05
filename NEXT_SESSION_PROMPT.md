Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
perform an actual light-theme visual verification of the bottom ticker only
after explicit owner consent, then restore the owner's original theme.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when absent, inspect installed/current Omarchy and Quickshell sources.
Load the Omarchy skill and its theming guide before running theme commands.

Verified current state:

- Commit `171de79` replaced the old popup with a 32-pixel bottom ticker that
  reserves screen space and does not request keyboard focus.
- The ticker groups games with sport emoji and friendly league names, renders
  18-pixel normalized team logos, and keeps live status detail at 82% of the
  active theme foreground.
- Same-league orange bullet separators have three spaces on each side. Every
  non-initial league heading has an additional 56-pixel gap, approximately eight
  ticker characters, so sport transitions are visually distinct.
- Matte Black has an actual visual pass. Installed light palettes calculate to
  at least 4.5:1 for the status treatment, but no light theme has received an
  actual visual pass.
- Actual Omarchy instance `kov6ravwkt` showed the ticker at logical 1920x32,
  reservations `[0,26,0,32]`, one Quickshell process, healthy panel coexistence,
  and no Sportray QML/binding/animation warning.
- Calendar remains disabled by the shared readonly feature flag.

Bounded outcome: ask for explicit owner approval before changing the active
theme. If approved, record the exact current theme and any restorable background
state, switch to one representative installed light theme, restart/resummon only
as required by the installed contract, and inspect one complete ticker pass for
background, foreground/status contrast, emoji, logos, same-league bullet
padding, and inter-league spacing. Capture a screenshot and logs, then restore
the exact original theme and confirm restoration. If safe exact restoration
cannot be guaranteed, stop without switching themes and document the blocker.
Make at most one ticker-only theme-adaptive correction justified by reproduced
runtime evidence.

Required checks after any code change: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Confirm one Quickshell instance, inspect `hyprctl layers`, monitor reserved
edges, screenshots, and `qs log`. Do not claim a light-theme runtime pass from
palette calculations alone.

Known risks: theme commands change owner-visible desktop state and may affect
background selection, so consent and exact restoration are mandatory. Animation
speed and reduced-motion integration remain outside this unit. A
bottom-positioned Omarchy bar has not been tested. Request subagents only for
independent read-only work that materially benefits from parallelism.

When complete or blocked, update `README.md` if public behavior changed,
`roadmap.md`, `CHANGELOG.md` if user-visible code changed, and this prompt with
accurate evidence and limitations. Create one atomic Conventional Commit only
if a correction or required handoff update is made and all applicable gates
pass. Do not push or change remote state.
