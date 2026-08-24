Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
after explicit owner authorization for a release-related follow-up, perform
one read-only audit of the owner-specified target commit or ref against the
local `1.0.0-rc.8` metadata.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff in this file. Read `docs/upstream-contract.md` when it is
present; it is intentionally absent in this checkout, so inspect the
installed/current Omarchy and Quickshell sources directly if a host-boundary
claim is involved, and record any material deviation in `roadmap.md` and later
the README. Inspect `git status`, the current branch, and recent commits.
Preserve unrelated user changes, including any deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`; `main`, `origin/main`, and `origin/HEAD`
  all resolve to `9942e0f4b6d4ca2cdb5b8652182f31ce26f4c1a4`.
- Sportray is an Omarchy Quattro `bar-widget` with eight leagues, bounded
  normalized game data, settings, standings, and favorite-only start,
  score-change, final, pregame, and opt-in close-game notifications.
- `manifest.json`, README Marketplace wording, and the changelog `Unreleased`
  section all identify `1.0.0-rc.8` as the current unreleased candidate.
- The only local version tag is unchanged annotated `v1.0.0-rc.7`, peeling to
  `de450941b5846914e1f8200f1a74ccf0a301428c`; `HEAD` is 47 commits beyond it.
  There is no `rc.8` tag. The changelog closing summary explicitly describes
  `rc.7` as historical and `rc.8` as untagged.
- The preceding unit changed only that stale changelog wording and passed the
  complete applicable gates: 190 deterministic tests, actual Omarchy plugin
  validation, real-import-path QML lint, summon-helper tests, and diff check.
  No new Omarchy runtime pass was performed.
- `MARKETPLACE_SUBMISSION.md` remains absent/untouched; do not restore or stage
  it. The checkout intentionally lacks `docs/upstream-contract.md`.

Bounded outcome:

Only if the owner supplies explicit release authorization and a target commit
or ref, compare that target's `1.0.0-rc.8` value and release wording in
`manifest.json`, `README.md`, and `CHANGELOG.md` with local tags and refs.
Report any mismatch with exact file/ref evidence. If authorization or a target
ref is missing, report that release state is unchanged and stop. Make no tag,
remote, Marketplace, provider, notification, settings, QML, or packaging
changes; do not invent a release date or rewrite historical `rc.7` evidence.

Required checks:

- Run `git status`, `git diff --check`, and the relevant read-only git ref/tag
  inspections against the owner-specified target.
- If documentation changes are made, run the complete applicable repository
  gates: `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`,
  real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over
  all QML files, and `./tests/test-summon-helper.sh`.
- Do not claim a new Omarchy runtime pass unless an actual shell/widget/log
  check is performed. Do not push, tag, publish, submit, or change Marketplace
  state.

Known risks and stop conditions: release authorization, target-ref selection,
remote HEAD parity, Marketplace verification, and preview rights remain
owner-controlled. Stop at the consistency report and any minimal
evidence-backed documentation repair; if owner direction is absent, stop
without editing. Do not turn this into a release, tag, publication, provider,
notification, settings, UI, or packaging unit.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit when any documentation change and all
applicable gates pass. Request subagents only for independent read-only
metadata/ref reconnaissance that materially improves confidence; the main
agent owns edits, validation, handoff, and commit.
