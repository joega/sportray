Work in `/home/joeg/Projects/sportray` on the next single bounded roadmap
unit: perform one actual Omarchy runtime verification of the Settings-page
**Send test notification** path after the close-game alert unit's service
wiring fix.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`,
`competition.md`, and the latest handoff in this file. Read
`docs/upstream-contract.md` when it is present; it is intentionally absent in
this checkout, so inspect the installed/current Omarchy and Quickshell sources
directly and record any material boundary deviation. Inspect `git status`, the
current branch, and recent commits. Preserve unrelated user changes, including
any deletion of `MARKETPLACE_SUBMISSION.md`; do not restore or stage it.

Verified current state:

- Sportray supports eight leagues, canonical favorites, bounded date/cache/
  polling behavior, settings, accessibility, standings, source-page routing,
  and favorite-only first-fetch-silent deduplicated start, score-change, final,
  pregame, and opt-in close-game notifications.
- `model/CloseGamePolicy.js` is pure and fixture-tested. It admits a transition
  into a favorite live/intermission game with valid normalized scores tied or
  within one point, scoped to the current local start date. Its default-off
  `closeGame` schema-1 setting and `gameId:close` dedupe fingerprint are
  complete; do not broaden the alert contract in this unit.
- The Settings-page preview bug was fixed by exposing the existing
  `NotificationService` from the `SportrayService` singleton and passing it
  explicitly from `Panel.qml` to `SettingsHub`/`SettingsView`. The direct
  `/usr/bin/omarchy-notification-send` helper test passed and Omarchy history
  recorded the toast, but no manual settings click-through has been claimed.
- The complete JavaScript suite passes with 190 tests; plugin validation,
  real-import-path QML lint, summon-helper tests, and `git diff --check` pass.
  QML lint retains established host-import/unqualified-access warnings.
- Actual Omarchy 4.0.0-1 and Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` are installed. Sportray is enabled,
  shell ping returns `ok`, and the linked checkout can be rescanned/summoned.
  The current limitation is that child-panel IPC does not expose a method for
  the settings action and no reliable desktop pointer injector has been
  available.

Bounded outcome:

Verify the Settings destination's **Send test notification** action on actual
Omarchy using only an available child-panel IPC or reliable desktop input
mechanism. Confirm the notification appears in the Omarchy notification
history and that the Quickshell log has no Sportray helper/QML/exception or
binding-loop failure. If the host still cannot provide a reliable interaction,
record the unchanged external blocker and make no Sportray source change.

Required checks:

- Inspect installed Omarchy/Quickshell widget, panel, IPC, and notification
  sources before choosing the runtime interaction path.
- Rescan the linked plugin on actual Omarchy, exercise only the host-supported
  settings action, inspect `qs list --all`, the current Quickshell log, and the
  notification history.
- If source changes become necessary, run `./tests/run-js-tests.sh`,
  `omarchy plugin validate "$PWD"`, real-import-path `qmllint`, and
  `git diff --check`. Do not claim manual UI success without direct evidence.

Known risks and stop conditions: child-route IPC and pointer injection may
remain unavailable; do not add a second helper route, alert type, provider
endpoint, broader discovery, specialist sports, packaging, tagging, pushing,
release, or Marketplace work. Stop after the runtime evidence or unchanged
blocker is recorded. Update `roadmap.md` with the dated handoff and evidence,
replace this file with the next self-contained single-unit prompt, and create
one atomic Conventional Commit-style commit only if a source/documentation
change was required and all applicable gates pass. Use subagents only for
independent read-only upstream/runtime reconnaissance that materially improves
confidence; the main agent owns any edits, validation, handoff, and commit.
