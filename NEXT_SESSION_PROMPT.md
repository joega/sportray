Work in `/home/joeg/Projects/sportray` on the single bounded follow-up to UX-1:
finish adaptive visible followed-league shortcuts plus More in the existing popup.
Read `AGENTS.md`, `README.md`, `roadmap.md` including its latest handoff,
`POPUP_UX_DIRECTION.md`, and this prompt. Read `docs/upstream-contract.md` when
present; otherwise inspect installed/current Omarchy and Quickshell sources before
changing a host boundary. Inspect git status, branch, and recent commits.

Current verified state: compact date presentation, flatter aligned score rows,
venue omission from slate rows, and Watch copy clarifying alert semantics are in
the worktree but not owner-reviewed or committed. The panel still uses the full
dropdown for league selection. Preserve existing normalized data/inclusion rules,
enabled-league access, followed order, keyboard/assistive routes, nested-pointer
safety, standings/settings/detail routes, host border, Calendar-disabled state,
and open-on-today semantics. Do not change persisted settings or provider/fetch
ownership.

Bounded outcome: replace or augment the dropdown with width-adaptive visible
Following/followed-league shortcuts and an explicit More route that exposes every
enabled league without hiding essential controls. Add fixture/source coverage for
capacity, ordering, More activation, keyboard focus, and assistive activation.
Stop if this requires changing semantic inclusion, detail, standings, provider,
cache, polling, ticker, Calendar, workspace persistence, or host ownership.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Obtain explicit owner consent before Omarchy rescan/restart or desktop changes;
then exercise pointer, keyboard, assistive, narrow/scaled, long-label, empty,
loading/error, and light/dark routes, inspect fresh logs, and confirm one shell
process. Do not report unperformed visual/focus checks as passing. Preserve the
pending consented ticker-today date-isolation proof.

Update `roadmap.md` with evidence, decisions, and a dated handoff; refresh this
prompt for the next single unit; commit atomically only when all gates and owner
review pass. No push, tag, release, or Marketplace work.
