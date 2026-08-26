Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
runtime-verify the hydrated Calendar presentation and vertical month-edge
interaction without changing the completed rehydration implementation.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, this
prompt, and the latest roadmap handoff. Read `docs/upstream-contract.md` when
present; when it is absent, inspect the installed/current Omarchy and
Quickshell sources directly and record any material boundary deviation.

Verified current state:

- Automatic current-month cache rehydration is complete. On actual Omarchy,
  incomplete coverage triggered 30 sequential seven-day requests through the
  existing `CalendarFetch` owner and produced 42 durable day entries each for
  NHL, NFL, NBA, Premier League, and MLS. MLB and both NCAA leagues remain
  selected-day-only.
- A second supported shell restart read 210 of 210 retained admitted
  league-days and correctly skipped another rehydration burst. Do not delete
  or damage the healthy cache just to replay progress.
- The cache-reader FileView boundary and QML no-`require` date fallbacks are
  fixture-tested. The complete suite has 259 tests; helper, diff, production
  validator, and real-import-path QML lint pass.
- The final live shell has one Quickshell process, ping and summon return `ok`,
  one 27x26 Sportray slot is visible, and fresh logs have no Sportray
  exception, binding loop, duplicate graph, load failure, or dropped cache
  FileView operation.

Bounded outcome: on actual Omarchy, use a supported pointer or focused input
path to open Sportray and Calendar. Confirm that current-month known game and
known-empty cells are visible without clicking individual dates, selected-day-
only leagues do not force admitted dates back to Unknown, and the six-week
vertical stream scrolls in both directions. Reach each list edge once and
confirm it requests/recenters the adjacent month without overflow or an
unbounded request loop. Inspect fresh logs afterward. Do not modify provider
profiles, hydration/cache ownership, endpoints, response limits, polling,
notifications, settings, packaging, release, or remote state.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
If no supported pointer/focused interaction path is available, record that
blocker and stop without weakening the gate or creating a success commit. If
the interaction exposes a concrete defect, fix only that defect and repeat the
gate. When the unit passes, update `roadmap.md` and its dated handoff, replace
this file with the next single-unit prompt, and create one atomic Conventional
Commit.

Known risks: this Wayland host previously lacked a supported pointer or AT-SPI
injector; widget registration can race immediately after rescan; the healthy
cache makes the active progress banner transient/unavailable without a genuine
future coverage gap; and ESPN remains an undocumented API. Request subagents
only for independent read-only source or log inspection that materially
benefits from parallelism.
