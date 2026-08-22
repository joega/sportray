# Public-Consumption Review

Date: 2026-08-22  
Reviewed baseline: `4be78fd1d3a22b21b0764b9133679908f09032c6`  
Environment: Omarchy 4.0.0-1, Quickshell 0.3.0.r20

## Verdict

Sportray is installable and passes the current Omarchy and Marketplace preflight checks, but it is **not ready for public release**. A critical notification injection path and several high-severity scheduler, lifecycle, and multi-monitor issues should be fixed before submission.

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

### High: healthy updates can erase another league's retry deadline

[PollScheduler.qml](/home/joeg/Projects/sportray/services/PollScheduler.qml:30) unconditionally replaces the timer when aggregate games change. A one-minute retry scheduled by one league can be replaced seconds later by another league's normal 6/12/24-hour cadence. This contradicts the documented 1–30-minute failure backoff and can strand later retry deadlines.

The scheduler should retain the earliest retry/cadence deadline, preferably with explicit per-league retry state, and needs executable behavior tests.

Status: fixed in the current worktree. The scheduler now centralizes earliest
deadline admission and preserves a pending retry when healthy aggregate updates
request a longer cadence. Tests cover retry-versus-cadence ordering, elapsed
deadlines, and manual-refresh behavior.

### High: NHL lookahead can loop indefinitely

[LeagueFetch.qml](/home/joeg/Projects/sportray/services/LeagueFetch.qml:288) validates `nextDateKey` only against the selected date. It does not require progress beyond `lookaheadRequestDateKey`, track visited dates, or enforce a hop limit. A successful empty response repeating the same or a previous date causes serial requests indefinitely.

Require strictly increasing dates, a visited/max-hop bound, and failure caching. The existing test only checks that the returned date is copied.

### High: disabled/date-change/re-enable can restore stale data

When disabled, [LeagueFetch.qml](/home/joeg/Projects/sportray/services/LeagueFetch.qml:297) returns before clearing the old snapshot. Re-enabling restores `lastKnownGames` without checking `snapshotDateKey`. Old-date games are filtered from display, but the stale raw state prevents the correct fetch and lookahead, leaving a stale/status-only empty panel.

Restore or clear data only when its snapshot date matches the selected date. Preserve the intentional cache-admission policy rather than bypassing it globally.

### High: nested interactions can fire twice

The result delegate has a whole-row `TapHandler` at [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:969), while child source/retry controls use their own mouse handlers through [SemanticActionButton.qml](/home/joeg/Projects/sportray/components/SemanticActionButton.qml:80). A source click can open the browser twice; retry can queue two refreshes; a next-game source click can also change the date. Review the pointer-acceptance policy against [Qt TapHandler documentation](https://doc.qt.io/qt-6.8/qml-qtquick-taphandler.html) and add interaction tests.

### High: team search loses normal keyboard input

[Panel.qml](/home/joeg/Projects/sportray/Panel.qml:584) blocks the host key catcher only for the sport popup. The installed `PanelKeyCatcher` consumes `h/j/k/l`, `x`, and Space before the search input receives them. Common searches such as “Lakers,” “Knicks,” and “New York” cannot be typed normally.

Block the catcher while any text editor is active, while preserving Escape handling, and test actual key routing.

## Additional risks

- Destruction-time delayed callbacks produced real Quickshell log errors during screen/bar remapping: deferred work in [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:305) and [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:832) ran after the panel/ListView was destroyed. Guard or cancel those callbacks.
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

- `tests/run-js-tests.sh`: 144 tests passed, including the notification helper
  boundary and scheduler deadline tests.
- `omarchy plugin validate "$PWD"`: passed on actual Omarchy.
- Current Marketplace validator from a clean public clone: passed.
- Marketplace security baseline v3: passed, no findings/capabilities.
- Live provider smoke checks for all eight configured leagues: valid responses.
- Real Quickshell discovery, rescan, toggle, rendering, and log inspection completed.
- `git diff --check` and `git fsck --full`: passed.
- No telemetry, accounts, secrets, downloaded-code execution, or privileged operations were found.

The worktree was clean and no implementation files were changed for this review.

## Next-session prompt

```text
Work in /home/joeg/Projects/sportray on the next public-release hardening unit:
bound NHL empty-day lookahead so repeated or non-progressing dates cannot loop.

Read AGENTS.md, README.md, docs/upstream-contract.md, roadmap.md, and the latest handoff before editing. If docs/upstream-contract.md is absent, verify the relevant contract against installed Omarchy 4.0.0-1 sources and record that fact.

Verified starting state:
- The notification injection and scheduler retry-deadline findings are fixed in
  the current hardening commit.
- 144 deterministic tests, Omarchy validation, and real-import-path qmllint pass;
  qmllint retains only the established host/import and unqualified-access
  warnings.
- NotificationModel bounds and sanitizes provider-derived notification text and
  prefixes option-looking content before the installed helper boundary.
- The helper test uses a safe notify-send stub; no supplied payload was executed.
- NHL lookahead still accepts a repeated or earlier returned date, so an empty
  response can trigger unbounded serial lookahead requests.

Bounded outcome:
Make NHL lookahead require strict date progress and enforce a bounded hop count.
Add executable behavior tests for repeated, earlier, malformed, and over-limit
lookahead responses while preserving the existing next-game result and cache
behavior.

Required checks:
- A repeated or earlier lookahead date cannot start another request.
- Lookahead has a finite request bound and caches a safe failure/empty outcome.
- tests/run-js-tests.sh passes.
- omarchy plugin validate "$PWD" passes on actual Omarchy.
- qmllint runs with the real shell import mapping.
- Quickshell logs show no new errors.
- git diff --check passes.

Stop after the NHL lookahead bound is fixed and verified. Do not combine
multi-monitor, scheduler, UI, packaging, tagging, pushing, or Marketplace submission work
into this unit. Update the review handoff, refresh this prompt, and create one
atomic Conventional Commit-style commit only after every gate passes.
```
