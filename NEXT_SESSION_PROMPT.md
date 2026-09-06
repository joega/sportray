Work in `/home/joeg/Projects/sportray` on the single bounded follow-up to UX-2:
perform the consented Omarchy runtime review of Following inclusion semantics.
Read `AGENTS.md`, `README.md`, `roadmap.md` including its latest handoff,
`POPUP_UX_DIRECTION.md`, and this prompt. Read `docs/upstream-contract.md` when
present; otherwise inspect installed/current Omarchy and Quickshell sources before
changing any host boundary. Inspect git status, branch, and recent commits.

Current verified state: `PanelPresentation.build` includes active watched games
only when they are already present in enabled/fetched league state, includes all
games from followed enabled leagues with zero favorites, deduplicates overlapping
favorite/watch/followed games, and preserves deterministic favorite/status/time
ordering. `ResultRows` no longer gates followed/watch content behind favorites and
uses selected-date-neutral empty copy. Fixture-driven JS coverage passes for
zero-favorite, followed-only, watch-only, duplicate, disabled-league, ordering,
and empty-state cases. No provider, fetch/cache/polling owner, settings persistence,
or hidden request changed. The design brief remains an untracked owner document;
preserve it.

Bounded outcome: with explicit owner consent, rescan/restart at most once and
exercise Following with zero favorites, followed leagues alone, watched games,
disabled leagues, selected-date navigation, keyboard, and assistive routes. Confirm
one Quickshell process and inspect fresh logs. Make at most one source correction,
only if a reproduced UX-2 behavior requires it. Do not redesign detail, standings,
freshness, ticker, Calendar, or workspace behavior; do not alter persisted settings
or add requests. If consent is unavailable, stop after static verification.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
Do not report unperformed visual/focus checks as passing. Preserve the pending
ticker-today proof while browsing panel dates. Update `roadmap.md` with evidence,
decisions, and a dated handoff; refresh this prompt for the next single unit; commit
atomically only when all applicable gates pass. No push, tag, release, or Marketplace
work.
