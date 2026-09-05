Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
evaluate the new bottom-edge scrolling ticker during sustained actual Omarchy
use and make at most one focused presentation adjustment justified by owner
feedback.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when absent, inspect installed/current Omarchy and Quickshell sources.

Verified current state:

- The old centered top popup card is gone. `TicketOverlay.qml` is a 32-pixel
  `PanelWindow` anchored left/right/bottom on the Top layer with
  `ExclusionMode.Auto` and keyboard focus `None`.
- Actual Hyprland reported the ticker at logical 1920x32 and reserved edges
  `[0,26,0,32]`, so tiled windows stop above it instead of being obscured.
- `TicketStrip.qml` renders one clipped line with a constant-speed infinite
  horizontal animation. Activating the strip opens the existing score panel;
  the ticker stays mapped so the work area does not resize.
- The ticker has no product-name prefix. Sport emoji and catalog-backed friendly
  names introduce consecutive league groups, while a bullet separates later
  games in the same group without repeating provider IDs such as `USA.1`.
- Available normalized team logos render at 18 pixels before their team names;
  missing or failed images collapse without leaving an empty slot.
- Live status details use foreground color at 82% opacity because the muted
  theme token was difficult to read at ticker size. Representative installed
  dark and light palettes meet at least 4.5:1 with that treatment.
- Inter-game spacing uses the small theme token; spacing within each game stays
  compact.
- `TicketPresentation.js` admits at most 24 current-date games, ordered live,
  future scheduled, then finals completed in the last 12 hours. Favorites break
  ties inside a status group. Old finals and past-due schedules are omitted.
- The ticker consumes the existing singleton service slate and creates no new
  provider request, polling owner, focus owner, or Quickshell process.
- Calendar remains disabled by the shared readonly feature flag.

Bounded outcome: observe at least one complete ticker pass on actual Omarchy and
record concrete owner feedback on speed, density, separators, and contrast. If
one defect is confirmed, make only that presentation correction. Do not add a
settings surface or change ticker selection semantics without a separate owner
decision. If no correction is justified, make no source change and document the
result.

Required checks after any code change: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Restart the actual shell, confirm one Quickshell instance, inspect
`hyprctl layers`, monitor reserved edges, a screenshot, and `qs log`. Do not
claim runtime success without that evidence.

Known risks: animation speed and information density have had only a short live
exercise; only the currently visible baseball group was manually observed after
the emoji/heading refinement, while deterministic fixtures cover hockey, soccer,
MLS grouping, Premier League naming, and logo URL projection; the mixed
image/text ticker has had only a short runtime exercise; reduced-motion behavior
is implemented but not connected to a user setting; and a bottom-positioned
Omarchy bar has not been exercised beside the ticker. Matte Black had a live
visual pass, but light themes had palette contrast checks only because the
owner's persisted theme was not changed. Request subagents only for independent
read-only work that materially benefits from parallelism.

When complete, update `README.md`, `roadmap.md`, `CHANGELOG.md`, and this prompt
with accurate evidence and limitations. Create one atomic Conventional Commit
only if a correction is made and all gates pass. Do not push or change remote
state.
