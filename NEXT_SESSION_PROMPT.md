Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
perform one read-only release-candidate metadata consistency check for the
owner-assigned `1.0.0-rc.8`.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and the
latest handoff in this file. Read `docs/upstream-contract.md` when it is
present; it is intentionally absent in this checkout, so inspect the
installed/current Omarchy and Quickshell sources directly if a host-boundary
claim is involved, and record any material deviation in `roadmap.md` and later
the README. Inspect `git status`, the current branch, and recent commits.
Preserve unrelated user changes, including any deletion of
`MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- The current checkout is on `main`, ahead of `origin/main`, with the latest
  private documentation commit recording actual Omarchy settings-page
  notification verification after `omarchy restart shell`.
- Sportray is an Omarchy Quattro `bar-widget` with eight leagues, bounded
  normalized game data, settings, standings, and favorite-only start,
  score-change, final, pregame, and opt-in close-game notifications.
- The README now distinguishes the underlying shell payload requirement from
  the installed `omarchy-shell` wrapper, which supplies `{}` for omitted
  bar-widget summon/toggle arguments. It also documents the verified shell
  restart recovery for stale active widget instances.
- `manifest.json` carries the owner-assigned `1.0.0-rc.8` value. The existing
  `v1.0.0-rc.7` tag and Marketplace publication state are historical/release
  boundaries; no new release or remote publication is authorized by this
  prompt.
- The preceding audit made no provider, notification, settings, QML,
  packaging, or runtime changes. Do not infer a new Omarchy runtime pass from
  the historical evidence.

Bounded outcome:

Compare the `1.0.0-rc.8` value and release wording in `manifest.json`,
`README.md`, and `CHANGELOG.md` with local tags and refs. Report any mismatch
with exact file/ref evidence. Make no edits unless a directly contradictory
local documentation statement is found; do not invent a release date or
rewrite historical `rc.7` evidence.

Required checks:

- Run `git status`, `git diff --check`, and the relevant read-only git ref/tag
  inspections. If documentation changes are made, run the complete applicable
  repository gates: `./tests/run-js-tests.sh`, `omarchy plugin validate
  "$PWD"`, real-import-path `qmllint`, and `./tests/test-summon-helper.sh`.
- Do not claim a new Omarchy runtime pass unless an actual shell/widget/log
  check is performed. Do not push, tag, publish, submit, or change Marketplace
  state.

Known risks and stop conditions: release authorization, remote HEAD parity,
Marketplace verification, and preview rights remain owner-controlled. Stop at
the consistency report and any minimal evidence-backed documentation repair;
do not turn this into a release, tag, publication, provider, notification,
settings, UI, or packaging unit.

At the end, update `roadmap.md` with the dated handoff and evidence, replace
this file with the next self-contained single-unit prompt, and create one
atomic Conventional Commit-style commit when any documentation change and all
applicable gates pass. Request subagents only for independent read-only
metadata/ref reconnaissance that materially improves confidence; the main
agent owns edits, validation, handoff, and commit.
