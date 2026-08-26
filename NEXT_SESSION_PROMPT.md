Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
complete D1 live-football provider-shape observation for scoring plays and
leaders.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest roadmap handoff, and `LEVEL_THE_FIELD_SPRINT.md`. If
`docs/upstream-contract.md` is absent, inspect the installed/current Omarchy
and Quickshell sources directly and record material boundary deviations.

Verified current state:

- Calendar C1-C5, watches W1-W3, followed leagues L1-L2, and shared settings
  migration S1 are complete. Settings now migrate schema 1 to schema 2 while
  preserving compatible values; future schemas above 2 remain opaque.
- The deterministic suite passes with 257 tests; actual Omarchy validation,
  real-import-path QML lint, one-shell restart/ping, and schema-1 migration /
  restart evidence pass.
- L3 pointer/direct-Accessible runtime verification remains blocked because
  this Wayland host has keyboard injection but no supported pointer injector
  or AT-SPI event-driving client. Do not reopen it here.
- Existing live football scoring-play/leader support remains provider-gated;
  no verified in-progress shape has been accepted yet. Do not infer absent
  fields from fixtures or add a second endpoint.

Bounded outcome: during an actually eligible in-progress NCAA Football event,
make bounded read-only scoreboard observations for scoring plays and leaders.
Record sanitized keys, types, optionality, observed counts, ordering, identity
relationships, response size, and elapsed time without retaining raw live
payloads. Decide scoring-play support and leader support independently. If no
eligible live event is available, record that gate and stop with no source
changes. Do not implement D2/D3, add endpoints, increase response limits, or
change providers, polling, notifications, watches, calendar, cache, settings,
or host APIs.

Required checks if observations yield a source change: add only sanitized
fixture coverage, run `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
On actual Omarchy, keep one supported shell, inspect fresh Quickshell logs,
and verify no duplicate graph, exception, or binding loop. If the live shape
is insufficient, update the sprint, roadmap, competition evidence, and this
prompt, and leave the unit incomplete rather than guessing.

Known risks: the next eligible CFB window may not be live during the session;
ESPN is undocumented; provider payloads may omit or cap optional sections; and
the current response byte/event limits remain hard bounds. Do not push, tag,
release, publish, or perform Marketplace work. If a verified shape is accepted,
update all handoff files and create one atomic Conventional Commit only after
the gate passes.
