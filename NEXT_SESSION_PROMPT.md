Work in `/home/joeg/Projects/sportray` on exactly one bounded roadmap unit:
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
- The installed Sportray root is now a normal Git checkout rather than a
  development symlink. Its verified product commit is
  `7ace7dd4b9838897cf3179176beca0e079341078`, its GitHub origin is preserved,
  and the exact Omarchy plugin-update path passes validation. The source branch
  has only the required planning-doc handoff commit beyond that product commit.
  Confirm the runtime-file trees still match before making any runtime claim.
- The live shell has one Quickshell process and ping returns `ok`. Post-repair
  logs show a normal Sportray reload with no Sportray exception, binding loop,
  duplicate graph, or load failure. An unrelated `crmne.hyprmoncfg` filename-
  case warning remains outside this unit.

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
`git diff --check`, `omarchy plugin validate "$PWD"`, production validation of
the installed checkout, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file. If a concrete defect requires a
source fix, implement only that defect, commit it after the gate passes, then
fast-forward the installed checkout from the local source without changing its
configured GitHub origin and rescan before repeating the runtime check.

Stop if no supported pointer/focused interaction path is available; record the
blocker without weakening the gate or creating a success commit. When the unit
passes, update `roadmap.md` and its dated handoff, replace this file with the
next single-unit prompt, and create one atomic Conventional Commit.

Known risks: this Wayland host previously lacked a supported pointer or AT-SPI
injector; widget registration can race immediately after rescan; the healthy
cache makes the active progress banner transient/unavailable without a genuine
future coverage gap; the installed checkout no longer hot-reloads uncommitted
source-tree edits; and ESPN remains an undocumented API. Request subagents only
for independent read-only source or log inspection that materially benefits
from parallelism.
