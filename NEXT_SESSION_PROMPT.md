Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: implement broader team discovery (P1-5) as one bounded vertical slice.
The owner directed on 2026-08-24 that all candidate slices from
`competition.md` will be completed in sequence; the agreed order after this
unit is calendar extensions, then broadcast/event links, then a second
verified provider adapter (requires explicit terms/region/reliability review),
then owner-controlled release/publication follow-ups.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, the
latest handoff, and `competition.md`. `docs/upstream-contract.md` is
intentionally absent in this checkout; inspect installed Omarchy/Quickshell
sources directly for any host-boundary claim and record material deviations in
`roadmap.md`. Inspect `git status`, the current branch, and recent commits.
Preserve unrelated user changes, including the absence of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The checkout is on `main`, clean, with all five recorded minimum competitive
  baseline capabilities implemented. The 2026-08-24 team-statistics unit added
  the optional bounded `TEAM STATS` detail projection (MLB hits/errors from the
  already fetched ESPN scoreboard snapshot) rendered in the existing
  drill-down with neutral placeholders; 211 deterministic tests pass.
- Baseline gates at handoff time: `tests/run-js-tests.sh` (211 tests),
  `tests/test-summon-helper.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
  (exit 0 with established warnings), and `git diff --check` pass. Actual
  Omarchy restarted into one healthy shell (PID 911404); the detail view was
  exercised through real keyboard input and the fresh log was clean.
- The favorite picker currently resolves teams through the bounded static
  catalogs (`providers/NhlTeamCatalog.js`, `providers/EspnTeamCatalog.js`) and
  `model/TeamPickerModel.js`; favorites remain canonical
  `<league>:<providerTeamId>` identities in schema-1 settings.

Bounded outcome:

Broader team discovery as one vertical slice: expand cross-league team
discovery in the existing favorite picker using only bounded static catalog
data or a verified provider contract. Keep provider parsing in `providers/`,
keep the pure picker model fixture-tested before QML wiring, reuse the
existing picker UI and schema-1 settings persistence without a schema change,
and bound every catalog size, search input, and result list. If discovery
would require a new unverified endpoint, stop and record the blocker instead.

Required checks (rerun all after implementation):

- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
- On actual Omarchy: restart/rescan as required by the changed boundary,
  confirm one healthy shell, exercise the changed picker behavior through the
  real input path available, and inspect the fresh Quickshell log for Sportray
  errors, exceptions, or binding loops before claiming runtime success.

Known risks and stop conditions: ESPN remains an undocumented API; any new
request path or second provider adapter requires explicit terms/region/
reliability review before implementation; release metadata/tagging/pushing/
Marketplace remain owner-controlled and out of feature scope. Stop before
calendar extensions, broadcast links, packaging, tagging, pushing, releasing,
or Marketplace work; stop if the slice would require a new upstream shell API,
an unverified endpoint, or scope beyond one vertical slice. Do not weaken
acceptance gates to finish.

At the end, update `roadmap.md` with the dated handoff and evidence, update
`competition.md` backlog status, replace this file with the next self-contained
single-unit prompt (calendar extensions), and create one atomic Conventional
Commit-style commit only when all applicable gates pass. Request subagents only
for independent read-only reconnaissance; the main agent owns edits,
validation, handoff, and commit.
