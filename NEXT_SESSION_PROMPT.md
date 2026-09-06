Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
manually verify the ambient ticker remains on today's games while navigating the
panel date carousel, then make at most one correction justified by observation.

Read `AGENTS.md`, `README.md`, `roadmap.md`, and this prompt first. Since
`docs/upstream-contract.md` is absent, inspect installed/current Omarchy and
Quickshell sources before any boundary change.

Current verified state: `SportrayService` owns one `FetchService`; today games
are snapshotted and `AmbientGamesPolicy` keeps the ticker current-day scoped
while selected-date browsing changes panel games. Deterministic JS, summon
helper, diff check, plugin validation, and real-import-path QML lint pass. One
Quickshell process is healthy and shell ping is `ok`. No live rescan/restart or
date-navigation interaction was performed in the prior unit.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
With explicit owner consent only, rescan/restart and manually navigate dates;
inspect fresh logs and confirm one Quickshell instance. Preserve one fetch
owner, ticker interaction/layout/accessibility, panel border, and disabled
Calendar. Stop before provider, cache, polling redesign, geometry, release,
push, tag, or Marketplace work. Update roadmap, this prompt, and commit
atomically when the gate passes.
