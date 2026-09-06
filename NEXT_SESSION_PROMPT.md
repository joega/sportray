Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
isolate ambient ticker games from selected-date panel navigation while retaining
one shared fetch owner and bounded request behavior.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`,
this prompt, and the latest roadmap handoff. Read
`docs/upstream-contract.md` when present; when absent, inspect
installed/current Omarchy and Quickshell sources.

Verified current state:

- HEAD is `3743c1f` on clean `main` matching `origin/main` (confirm before
  work). The bottom ticker, click-regression fix, sport separators, shared
  service ownership, restored main-popout border, and disabled Calendar are
  live. The installed `KeyboardPanel` supplies the desired theme-aware popup
  border; do not reintroduce `Border.none()` or alter panel geometry.
- Review found that `components/SourceLinkButton.qml` and
  `components/TicketStrip.qml` use `indexOf("espn.com")`-style substring
  checks at the browser-launch sink. This does not enforce the exact-host
  boundary claimed by the changelog: for example,
  `https://example.invalid/espn.com` passes. Upstream provider/GameModel and
  TicketPresentation normalization usually reject it first, but the sink must
  independently fail closed. Upstream checks are case-insensitive while the
  sinks currently require lowercase `https://`, creating an enabled-but-no-op
  edge case for uppercase schemes.
- A separate review finding remains for a later unit: `ambientGames` aliases
  the selected-date fetch, so browsing another panel date temporarily changes
  every ticker. Do not address it in this security unit.
- 269 deterministic JavaScript checks, summon-helper suite,
  `git diff --check`, `omarchy plugin validate "$PWD"` (exit 0), and
  real-import-path `qmllint` over every QML file (exit 0, established
  warnings only) pass. One Quickshell process is healthy, shell ping is `ok`,
  and no warning-priority journal entries appeared after current HEAD loaded.

Verified current state: `model/ProviderUrlPolicy.js` now provides exact,
case-insensitive HTTPS authority validation for the six provider hosts, and both
browser launch sinks use it. Executable boundary tests pass. The remaining
review finding is that `SportrayService.ambientGames` aliases the selected-date
fetch, temporarily changing the ticker while browsing another date.

Bounded outcome: keep one fetch owner and existing bounds, but make the ticker
current-day scoped during panel date navigation and add a deterministic selected-
date transition test. Preserve ticker interaction/layout/accessibility, panel
border, disabled Calendar, provider parsing, and all other behavior.

Required checks after any code change: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML
file. Confirm one Quickshell instance, inspect shell ping and fresh
logs (summon IPC only with consent). Do not claim runtime behavior
from static reasoning alone.

Known risks: QML JavaScript URL parsing support must be verified against the
installed Qt/Quickshell runtime; avoid assuming browser-only APIs. Games
without a safe provider URL must remain neutral and non-activatable. Horizontal
anchors must never land on a Row child again. The ambient selected-date bug,
continuous-animation cost, minute model churn, and panel-open Overlay hit
testing are explicitly out of scope. Request subagents only for independent
read-only work that materially benefits from parallelism.

When complete or blocked, update `README.md` if public behavior changed,
`roadmap.md`, `CHANGELOG.md` if user-visible behavior changed, and this prompt
with accurate evidence and limitations. Create one atomic Conventional Commit
when the gate passes. Do not push or change remote state.
