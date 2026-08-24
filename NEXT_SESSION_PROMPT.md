Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap unit:
perform one read-only release-readiness consistency audit of the current
notification behavior and its README/roadmap evidence after the verified
Omarchy shell-restart recovery.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and
the latest handoff in this file. Read `docs/upstream-contract.md` when it is
present; it is intentionally absent in this checkout, so inspect the
installed/current Omarchy and Quickshell sources directly and record any
material boundary deviation in `roadmap.md` and later the README. Inspect
`git status`, the current branch, and recent commits. Preserve unrelated user
changes, including any deletion of `MARKETPLACE_SUBMISSION.md`; do not restore
or stage it.

Verified current state:

- Sportray is an Omarchy Quattro `bar-widget` with eight leagues, settings,
  standings, bounded game data, and favorite-only start, score-change, final,
  pregame, and opt-in close-game notifications.
- The Settings-page preview wiring is explicit: `SportrayService` exposes the
  existing `NotificationService`, and `Panel.qml` passes it to
  `SettingsHub`/`SettingsView`. The helper queue and notification argv are
  unchanged.
- On actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537`, the current Notifications view
  rendered all six preferences plus **Send test notification** after
  `omarchy restart shell`; the settings route produced entries in Omarchy
  notification history with the expected Sportray preview text.
- `rescanPlugins` and a successful summon do not necessarily replace an
  already-loaded bar-widget instance. `shell call` is not a bar-widget child
  route. The supported recovery is `omarchy restart shell`, followed by
  summon/toggle. No Sportray source change was needed for the verified issue.
- The complete JavaScript suite, plugin validation, real-import-path QML lint,
  summon-helper test, and `git diff --check` passed for the preceding source
  unit. Established standalone-import, host-type, and unqualified-access
  lint warnings remain expected.

Bounded outcome:

Audit the public README, private roadmap, and current source/runtime evidence
for stale or contradictory notification and shell-lifecycle claims. Make only
minimal documentation corrections that are directly supported by the checked
out state. Do not modify provider logic, notification policies, settings
schema, QML interaction, packaging, or remote state.

Required checks:

- Inspect the installed Omarchy/Quickshell lifecycle and notification sources
  if any boundary claim is uncertain; do not rely on an obsolete plan.
- Run `git diff --check`. If documentation changes are made, also run the
  complete applicable repository gates: `./tests/run-js-tests.sh`,
  `omarchy plugin validate "$PWD"`, real-import-path `qmllint`, and
  `./tests/test-summon-helper.sh`.
- Do not claim a new Omarchy runtime pass unless an actual shell/widget/log
  check is performed. Do not push, tag, publish, submit, or change Marketplace
  state.

Known risks and stop conditions: the active bar-widget may require a shell
restart after source changes; pointer injection may remain unavailable; and
the previous batched keyboard exercise produced multiple history entries, so
do not infer a new repeated-key contract from it. Stop after the consistency
audit and directly supported documentation changes. Update `roadmap.md` with
a dated handoff and evidence, replace this file with the next self-contained
single-unit prompt, and create one atomic Conventional Commit-style commit
when the documentation gate passes. Request subagents only for independent
read-only source/documentation reconnaissance that materially improves
confidence; the main agent owns edits, validation, handoff, and commit.
