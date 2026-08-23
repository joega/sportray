# Public-Consumption Review

Date: 2026-08-22  
Reviewed baseline: `2f3f327c0fd862e7213630e682cda24d6aa4381e`
Environment: Omarchy 4.0.0-1, Quickshell 0.3.0.r20

## Verdict

Sportray is installable and passes the current Omarchy and Marketplace preflight checks, but it is **not ready for public release**. Several high-severity lifecycle, multi-monitor, nested interaction, and keyboard-routing issues should be fixed before submission.

## Release-blocking findings

### Critical: provider text can become a shell command through notifications

Team labels flow into the beginning of notification descriptions in [model/NotificationModel.js](/home/joeg/Projects/sportray/model/NotificationModel.js:130). A provider-supplied label beginning with an option such as `--hint=string:omarchy-exec:...` is reinterpreted by the installed [omarchy-notification-send](/usr/bin/omarchy-notification-send:84) helper as a `notify-send` option. Omarchy stores that hint and executes it with `bash -lc` when the user clicks the toast.

The preconditions are notifications enabled, a favorite game, malicious or compromised provider data, and a click on the toast. No payload was executed during this review; the argument path was reproduced with a safe stub.

Status: fixed in the current worktree. Notification display text now strips
control characters, bounds provider-derived fields, and prefixes option-looking
text before it reaches the helper. Deterministic tests exercise hyphen-leading
labels, an `omarchy-exec`-shaped value, control characters, oversized values,
and a safe stub invocation of the installed helper; no supplied payload is
executed. The installed helper's option parsing remains an upstream behavior
worth reporting separately.

### High: each monitor creates an independent polling and notification graph

[BarWidget.qml](/home/joeg/Projects/sportray/BarWidget.qml:100) loads a panel and [BarWidget.qml](/home/joeg/Projects/sportray/BarWidget.qml:113) loads a settings store for every bar widget. Each [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:524) then creates its own `FetchService` and `NotificationService`.

Omarchy creates one widget instance per screen. Multi-monitor systems can therefore duplicate provider traffic and notifications, maintain separate transition baselines, and race writes to the same state file. Existing topology tests cover only one panel instance.

Status: fixed in the current worktree. Because `docs/upstream-contract.md` is
intentionally absent, installed Omarchy 4.0.0-1 `Bar.qml` was rechecked and
confirmed to create one module/widget item per `Quickshell.screens` entry.
`SportrayService` is now the exclusive engine-wide owner of the settings store,
fetch graph, and notification transition baseline. Per-screen widgets/panels
register only open/lookahead context. Deterministic two-panel ownership checks
cover handoff and removal; a live linked-plugin rescan showed one polling
initialization and no new Sportray runtime error.

### High: healthy updates can erase another league's retry deadline

[PollScheduler.qml](/home/joeg/Projects/sportray/services/PollScheduler.qml:30) unconditionally replaces the timer when aggregate games change. A one-minute retry scheduled by one league can be replaced seconds later by another league's normal 6/12/24-hour cadence. This contradicts the documented 1–30-minute failure backoff and can strand later retry deadlines.

The scheduler should retain the earliest retry/cadence deadline, preferably with explicit per-league retry state, and needs executable behavior tests.

Status: fixed in the current worktree. The scheduler now centralizes earliest
deadline admission and preserves a pending retry when healthy aggregate updates
request a longer cadence. Tests cover retry-versus-cadence ordering, elapsed
deadlines, and manual-refresh behavior.

### High: NHL lookahead can loop indefinitely

[LeagueFetch.qml](/home/joeg/Projects/sportray/services/LeagueFetch.qml:288) validates `nextDateKey` only against the selected date. It does not require progress beyond `lookaheadRequestDateKey`, track visited dates, or enforce a hop limit. A successful empty response repeating the same or a previous date causes serial requests indefinitely.

The fix must require strictly increasing dates, a visited/max-hop bound, and
failure caching. The existing test only checks that the returned date is copied.

Status: fixed in the current worktree. `LookaheadPolicy` requires a valid date
strictly later than the date just requested, retains the existing 35-day
window, and caps the selected empty-day lookup at eight requests.
`LeagueFetch` tracks the request count and routes malformed, repeated, earlier,
out-of-range, and over-limit responses through the existing six-hour
`unavailable` cache entry. Fixture-driven tests cover the rejected responses
and confirm that a valid later response still produces the first upcoming game
and date.

### High: disabled/date-change/re-enable can restore stale data

When disabled, [LeagueFetch.qml](/home/joeg/Projects/sportray/services/LeagueFetch.qml:297) returns before clearing the old snapshot. Re-enabling restores `lastKnownGames` without checking `snapshotDateKey`. Old-date games are filtered from display, but the stale raw state prevents the correct fetch and lookahead, leaving a stale/status-only empty panel.

Restore or clear data only when its snapshot date matches the selected date. Preserve the intentional cache-admission policy rather than bypassing it globally.

Status: fixed in the current worktree. `LeagueFetch` now clears its active and
last-known snapshot whenever the initialized selected date changes, including
while the league is disabled. Re-enable restoration uses the pure
`DateCachePolicy` admission guard, so a last-known snapshot is accepted only
when its snapshot date matches the selected date and the current game list is
empty. The existing bounded date-keyed cache remains available for same-date
restore and selected-date fetch admission. Fixture-driven tests cover
same-date restore, date changes while disabled, empty snapshots, and protection
of current games.

### High: nested interactions can fire twice

The result delegate has a whole-row `TapHandler` at [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:969), while child source/retry controls use their own mouse handlers through [SemanticActionButton.qml](/home/joeg/Projects/sportray/components/SemanticActionButton.qml:80). A source click can open the browser twice; retry can queue two refreshes; a next-game source click can also change the date. Review the pointer-acceptance policy against [Qt TapHandler documentation](https://doc.qt.io/qt-6.8/qml-qtquick-taphandler.html) and add interaction tests.

Status: fixed in the current worktree. The checkout intentionally has no
`docs/upstream-contract.md`, so the installed Omarchy 4.0.0-1 / Qt 6.11.1
pointer contract was inspected instead: `TapHandler` is a generic pointer
handler and does not exclude nested child controls. The row handler is now
disabled while a nested source, retry, View day, or empty-card action has its
`MouseArea.pressed` state. Deterministic routing checks prove each child action
wins its tap and an unpressed whole row retains one primary activation; keyboard
and accessibility activation paths are unchanged.

### High: team search loses normal keyboard input

[Panel.qml](/home/joeg/Projects/sportray/Panel.qml:584) blocks the host key catcher only for the sport popup. The installed `PanelKeyCatcher` consumes `h/j/k/l`, `x`, and Space before the search input receives them. Common searches such as “Lakers,” “Knicks,” and “New York” cannot be typed normally.

Block the catcher while any text editor is active, while preserving Escape handling, and test actual key routing.

Status: fixed in the current worktree. The installed Omarchy 4.0.0-1
`PanelKeyCatcher` contract uses `Keys.BeforeItem`; its `blocked` property is the
supported way to forward all keys to descendants. Sportray now combines the
sport-popup state with `SettingsHub.inputActive`, and the TeamPicker Escape
signal is wired through the hub to the existing close-utility path. Pure
routing tests cover editor shortcuts, editor Escape, popup ownership, catcher
Escape, navigation, and ordinary panel text.

## Additional risks

- Destruction-time delayed callbacks previously produced real Quickshell log
  errors during screen/bar remapping: deferred work in [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:305) and [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:832) ran after the panel/ListView was destroyed. **Status: fixed in the current worktree.** `LifecyclePolicy` now invalidates plain-JavaScript owner tokens during destruction; panel, result-list, bar-widget, settings-hub, and team-picker deferred callbacks reject stale generations, and panel timers stop during teardown. The enclosing result-row guard also uses its delegate parent scope, avoiding a runtime `ReferenceError`. Deterministic lifecycle tests cover live execution and destroyed-owner rejection; a fresh Omarchy shell restart, open/close exercise, and log inspection showed no new Sportray lifecycle error.
- Provider-supplied logo URLs accept arbitrary HTTP(S) hosts in [GameModel.js](/home/joeg/Projects/sportray/model/GameModel.js:27) and [TeamModel.js](/home/joeg/Projects/sportray/model/TeamModel.js:28), then load directly in [GameRow.qml](/home/joeg/Projects/sportray/components/GameRow.qml:108). Restrict to HTTPS and reviewed asset hosts.
- `curl` has no HTTPS-only redirect policy or response-size limit; `StdioCollector` buffers complete responses and provider event arrays are not bounded.
- The installed settings file is world-readable (`0644`) with world-traversable parent directories; it contains favorites, notification preferences, fingerprints, and timestamps. Prefer `0600`/`0700`.
- Unsupported future state schemas are destructively replaced instead of preserved for rollback.
- Mixed Following rows may clip the trailing source action; accessibility roles lack corresponding press/toggle actions.
- [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:28) redeclares the host Panel's existing `settings` property. Omarchy 4.0.0-1 accepts it, but a distinct `settingsStore` property is safer for upstream compatibility.

## Release and documentation gates

- README's “uses only” dependency claim omits `omarchy-launch-browser`, invoked by [SourceLinkButton.qml](/home/joeg/Projects/sportray/components/SourceLinkButton.qml:26).
- `manifest.json` remains `1.0.0-rc.7`, while the existing `v1.0.0-rc.7` tag points to an older tree. Most current “Unreleased” changelog entries already exist in that tag. Create a new version/tag; do not move the existing tag.
- The preview contains ESPN and club marks. The owner must confirm rights or replace/redesign the preview before accepting the Marketplace rights declaration in the [submission guide](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).
- Public CI, `SECURITY.md`, and `CONTRIBUTING.md` are absent. These are not validator failures but would improve trust for an unsandboxed long-lived plugin.

## Verification completed

- The notification injection finding is fixed and covered by the adversarial
  model/helper-argv test described above.
- The scheduler retry-deadline finding is fixed and covered by the deadline
  admission behavior test described above.

- `tests/run-js-tests.sh`: 149 tests passed, including notification, scheduler,
  NHL lookahead, stale-date, multi-monitor ownership, and nested-pointer
  and editor-keyboard routing checks.
- NHL lookahead fixtures cover repeated, earlier, malformed, over-limit, and
  valid later schedule responses.
- `omarchy plugin validate "$PWD"`: passed on actual Omarchy.
- Current Marketplace validator from a clean public clone: passed.
- Marketplace security baseline v3: passed, no findings/capabilities.
- Live provider smoke checks for all eight configured leagues: valid responses.
- Real Quickshell discovery, rescan, toggle, rendering, and log inspection completed.
- `git diff --check` and `git fsck --full`: passed.
- The linked checkout was rescanned in the live Omarchy shell. One Quickshell
  instance remained running, shell ping returned `ok`, and the post-rescan log
  tail contained normal provider/cache activity without a Sportray error,
  exception, or binding-loop warning. The only warning observed was the
  pre-existing Qt.atob deprecation; no manual date-toggle UI sequence was
  exercised.
- No telemetry, accounts, secrets, downloaded-code execution, or privileged operations were found.

The lookahead, stale-date, multi-monitor ownership, nested-pointer, and editor-
keyboard routing
implementations,
fixtures, tests, roadmap, and review handoff were changed in this hardening
history. The checkout intentionally has no `docs/upstream-contract.md`;
installed Omarchy 4.0.0-1 remains the runtime boundary source.

## Next-session prompt

```text
Work in /home/joeg/Projects/sportray on the next public-release hardening
unit: guard delayed panel callbacks and destruction-time work from running
after their owning panel or list has been destroyed.

Read AGENTS.md, README.md, docs/upstream-contract.md, roadmap.md, and the latest
roadmap/review handoff before editing. If docs/upstream-contract.md is absent,
verify the relevant contract against installed Omarchy 4.0.0-1 sources and
record that fact. Inspect git status, branch, and recent commits; preserve
unrelated changes.

Verified starting state:
- Notification injection, scheduler retry deadlines, NHL lookahead bounds,
  stale-date admission, and multi-monitor ownership are fixed.
- DateCachePolicy.js admits last-known restore only for a matching valid
  selected date; LeagueFetch.qml clears active/last-known state on every
  initialized date change, including while disabled, while preserving the
  bounded date-keyed cache for same-date admission.
- `SportrayService.qml` is the sole engine-wide owner of settings, fetch, and
  notification state; repeated panels register only open/lookahead context.
- 149 deterministic tests, omarchy plugin validate "$PWD", real-import-path
  qmllint over all QML files (with established warnings), and git diff --check pass.
- The linked plugin was rescanned in Omarchy 4.0.0-1. One Quickshell instance
  remained healthy, shell ping returned `ok`, and the post-rescan log tail had
  normal provider/cache activity with no Sportray error, exception, or
  binding-loop warning. The only warning observed was the existing Qt.atob
  deprecation.
- The checkout intentionally has no docs/upstream-contract.md; verify the
  relevant installed Omarchy 4.0.0-1 contract if an upstream boundary changes.
- Do not execute any provider-supplied command or broaden this unit.

Bounded outcome:
Ensure delayed panel callbacks and destruction-time work cannot access destroyed
panels or result lists. Preserve normal panel transitions and provider-neutral
models.

Required checks:
- Inspect the installed Quickshell lifecycle/timer contract before changing
  delayed callbacks.
- Add deterministic coverage for destroyed-owner guards and normal callback
  execution.
- tests/run-js-tests.sh passes.
- omarchy plugin validate "$PWD" passes on actual Omarchy.
- Run /usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell over all QML files.
- Inspect actual Quickshell logs for new errors if runtime is exercised.
- git diff --check passes.

Stop after the destruction-safety unit is fixed and verified. Do not combine
asset-host policy, packaging, tagging, pushing, or
Marketplace submission work. Update roadmap.md,
PUBLIC_CONSUMPTION_REVIEW.md, and this prompt with the next single bounded
unit, then create one atomic Conventional Commit-style commit only after every
gate passes. Use subagents only for independent read-only checks that materially
improve confidence.
```
