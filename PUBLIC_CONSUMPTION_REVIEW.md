# Public-Consumption Review

Date: 2026-08-23
Reviewed baseline: read-only Marketplace publication/listing recheck,
2026-08-23
Environment: Omarchy 4.0.0-1, Quickshell 0.3.0.r20

## Latest Marketplace-draft review — 2026-08-23

`MARKETPLACE_SUBMISSION.md` now contains the owner-review draft required by the
current Marketplace submission guide: title `[Plugin]: Sportray`, repository
root URL, category `Widgets`, tags `bar, quickshell`, suggested tag `sports`,
maintainer notes, and all five exact checked checklist statements under the six
required headings in the required order. The maintainer note names only the
authorized root `preview.png` and does not claim rights for any other asset.

The guide was checked at
<https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md>
on 2026-08-23. No issue was created, and no packaging, tag movement, push,
GitHub Release, or Marketplace submission occurred. The next gate is owner
review and explicit approval of the complete title and body.

The deterministic suite, actual-Omarchy plugin validation, real-import-path
QML lint, and `git diff --check` all pass. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 owns
`/usr/bin/omarchy-launch-browser`, and installed Quickshell 0.3.0.r20 exposes
the existing QString-list `Quickshell.execDetached` method. No runtime,
provider, settings, or public product behavior changed.

## Latest release-handoff review — 2026-08-23

The owner assigned local version `1.0.0-rc.8` and confirmed permission to
submit the personally captured `preview.png` as shown, including its visible
provider and team marks. The manifest now carries `1.0.0-rc.8`; the annotated
`v1.0.0-rc.7` tag remains unchanged, the current tree remains unreleased, and
no release date is asserted. No packaging, tag movement, push, GitHub Release,
or Marketplace submission occurred.

The deterministic suite, Omarchy plugin validation, real-import-path QML lint,
and `git diff --check` remain passing. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 and Quickshell 0.3.0
remain the runtime boundary sources. No runtime behavior or public product
contract changed during this metadata unit.

The owner-controlled release-input blocker is resolved for local metadata.
The remaining publication gate is owner review and explicit approval of the
complete Marketplace issue title and body; no issue may be created without
that approval.

## Verdict

Sportray is installable and has passed the recorded Omarchy and Marketplace
preflight checks. Marketplace automation has now published and verified the
listing; any newer-version verification remains owner/Marketplace controlled.

## Latest Marketplace submission refresh — 2026-08-23

The existing submission issue [#873](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/873) was updated in place; no duplicate issue was created. Its saved title and body now match the repository-local draft exactly, including category `Widgets`, tags `bar, quickshell`, suggested tag `sports`, maintainer notes, and the five checked guide statements. The preview note is limited to the owner-authorized personally captured root `preview.png` as shown, including its visible provider and team marks.

The marketplace validation workflow reran successfully and refreshed the existing bot comments. It reports Quattro compatibility and manifest `1.0.0-rc.8` at commit `4fcfa60`; the automated security baseline also passed exact commit `4fcfa604e61bb8f8d219c0be3ef43f92024dfda6` with no findings or capabilities. This is a commit-bound validation snapshot, not an automatic promise to track future branch changes. Issue #873 remains open with `submission` and `validated` labels and is ready for listing review.

The local gates pass: 158 deterministic tests, actual-Omarchy `omarchy plugin validate "$PWD"`, real-import-path QML lint over every QML file with established warnings, and `git diff --check`. Installed Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 remain the verified boundaries; the checkout intentionally has no `docs/upstream-contract.md`. No runtime or public product behavior changed. No package, tag, push, GitHub Release, or preview-rights decision occurred.

The next gate is Marketplace-maintainer listing review. Later updates to an
already listed snapshot must use the Marketplace verification form with the
full target commit SHA; they are not performed by creating duplicate
submission issues.

## Latest Marketplace publication recheck — 2026-08-23

The later read-only review of existing issue
[#873](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/873)
found that maintainer listing review is complete. The issue is closed and has
exactly four labels: `submission`, `validated`, `listed`, and
`approved-and-verified`. The latter two labels and closure were observed from
Marketplace automation; this checkout did not edit labels or issue state.

The exact title remains `[Plugin]: Sportray`, and the issue body matches
`MARKETPLACE_SUBMISSION.md` exactly. Its metadata remains repository URL
`https://github.com/joega/sportray`, category `Widgets`, tags
`bar, quickshell`, and suggested tag `sports`. The body continues to claim
rights only for the owner-authorized personally captured root `preview.png` as
shown, including its visible provider and team marks.

All three issue comments were read. The validator reports Quattro compatibility
and manifest `1.0.0-rc.8` at commit `0b0f6ca`; the automated security baseline
passed exact commit
`0b0f6ca898c481fe93437a8f765edfd450fe700d` with no findings or capabilities;
and Marketplace automation reports: “Published and verified Sportray” at
<https://omarchyplugins.com/plugin.html?id=io.github.joega.sportray>.
No maintainer request for repository changes, rights, or a different target
commit was present, and no newer-version verification action was run.

Local `HEAD` and read-only `origin/main` both resolve to
`0b0f6ca898c481fe93437a8f765edfd450fe700d`. The tree remains unreleased and
untagged; the annotated `v1.0.0-rc.7` tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`. Installed Omarchy 4.0.0-1 still
owns `/usr/bin/omarchy-launch-browser`, and installed Quickshell 0.3.0.r20
still exposes the existing QString-list `Quickshell.execDetached` method.
The checkout intentionally has no `docs/upstream-contract.md`.

No repository behavior, rights claim, package, tag, release, or remote state
was changed in this recheck. The next bounded unit is a later read-only public
listing recheck. Stop for owner direction if Marketplace requests repository
changes, new rights claims, or a different target commit; a newer listed
version requires explicit authorization of the verification form and its full
40-character target SHA.

## Latest Marketplace listing-review monitor — 2026-08-23

The read-only check of existing issue [#873](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/873) found no maintainer listing decision or request. The issue remains open with exactly `submission` and `validated` labels. Its title, body, repository URL, category, tags, and suggested tag still match the repository draft exactly: `[Plugin]: Sportray`, `https://github.com/joega/sportray`, `Widgets`, `bar, quickshell`, and `sports`. The body continues to claim rights only for the owner-authorized personally captured root `preview.png` as shown, including its visible provider and team marks.

The issue has two relevant comments. Validation reports Quattro compatibility at
`4fcfa60` with manifest `1.0.0-rc.8`; the automated security baseline reports
a pass at exact commit `4fcfa604e61bb8f8d219c0be3ef43f92024dfda6` with no
findings or capabilities. No newer listed version was explicitly requested,
so no verification-form action was run.

The current read-only `origin/main` ref is
`0b0f6ca898c481fe93437a8f765edfd450fe700d`, not the earlier handoff's
assumed local-only commit. The issue evidence remains bound to the earlier
`4fcfa604…` snapshot; no push or other remote write occurred in this unit.
Installed Omarchy `4.0.0-1` and Quickshell `0.3.0.r20.g28771c7-2` remain the
verified boundaries, and the checkout intentionally has no
`docs/upstream-contract.md`. No labels, issue content, rights claims,
repository files outside this handoff, package, tag, or release changed.

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
- Provider-supplied logo URLs previously accepted arbitrary HTTP(S) hosts in [GameModel.js](/home/joeg/Projects/sportray/model/GameModel.js:27) and [TeamModel.js](/home/joeg/Projects/sportray/model/TeamModel.js:28), then loaded directly in [GameRow.qml](/home/joeg/Projects/sportray/components/GameRow.qml:108). **Status: fixed in the current worktree.** `AssetUrlPolicy` now admits only HTTPS URLs whose exact host is `a.espncdn.com` or `assets.nhle.com`; the provider fallbacks used by the QML-loaded shell enforce the same reviewed hosts. Fixture-driven tests cover accepted ESPN/NHL URLs plus HTTP, untrusted-host, malformed, and missing values. Rejected or failed images still use the existing initials/neutral bindings in `GameRow.qml` and `TeamPicker.qml`.
- Provider response bodies previously had no size limit and `StdioCollector` buffered complete responses; provider event arrays were also unbounded. **Status: fixed in the current worktree.** `LeagueFetch` now uses `curl --max-filesize 2097152` plus a bounded `SplitParser` stream guard for both score and lookahead requests. `ResponsePolicy` rejects bodies beyond its conservative streamed-text limit, and ESPN/NHL score and schedule parsers reject more than 256 events before normalization. Invalid or oversized responses follow the existing isolated failure path and preserve last-good data.
- The installed settings file was world-readable (`0644`) with world-traversable parent directories; it contains favorites, notification preferences, fingerprints, and timestamps. **Status: fixed in the current worktree.** `SettingsStore` repairs only its plugin-owned `settings` directory to `0700`, repairs existing regular state files to `0600` before opening them, and repairs each newly atomically-saved file after `FileView.saved`. Persistence is gated when the fixed repair commands cannot complete; shared ancestors are intentionally untouched. Fixture-driven policy tests cover new files, overly-permissive files, parent repair, valid schema-1 round trips, and failed-repair admission without touching the real state path.
- Unsupported future state schemas were destructively replaced instead of
  preserved for rollback. **Status: fixed in the current worktree.** Numeric
  schema versions newer than 1 are treated as opaque by `StateModel` and
  `SettingsModel`: safe schema-1 defaults remain available, `needsWrite` is
  false, and the exact raw state text is retained without logging. The
  `SettingsStore` blocks startup-recovery, settings, and transition writes
  until a compatible reload replaces the future file. Fixture-driven coverage
  includes extra fields, malformed future field shapes, exact raw preservation,
  valid schema-1 input, and corrupt JSON recovery. Permission hardening and
  bounded fields remain unchanged.
- Mixed Following rows may clip the trailing source action.
  **Mixed-row geometry status: fixed in the current worktree.** `GameRow` now
  reserves the trailing source button independently from the flexible context,
  favorite, and detail region. `GameRowLayout.footerLayout` and
  `fixtures/layout/mixed-following.json` cover the 280px compact panel and
  400px normal panel widths, proving source reachability, non-overlap, and the
  unchanged normalized row identity/order. The source control remains
  focusable and keeps its existing provider URL policy.
- Accessibility roles previously lacked corresponding assistive press/toggle
  actions. **Status: fixed in the current worktree.** The installed QtQuick
  Accessible contract was verified from Qt 6.11.2 metadata and headers:
  existing controls now connect pressAction/toggleAction to their current
  callbacks, favorite delegates expose checked/checkable state, and disabled
  or unavailable actions remain non-activatable. Fixture/source-driven tests
  prove one route per source, retry, View day, empty-state, favorite, and
  whole-row action without changing pointer, keyboard, provider, row, URL, or
  settings behavior.
- [Panel.qml](/home/joeg/Projects/sportray/Panel.qml:32) previously redeclared the host Panel's existing `settings` property. **Status: fixed in the current worktree.** The installed Omarchy 4.0.0-1 host property remains inherited, while Sportray's service store is injected through the distinct `settingsStore` property. Source-driven coverage rejects the old declaration and injection and preserves the settings consumers.

## Release and documentation gates

- README's “uses only” dependency claim omitted `omarchy-launch-browser`, invoked by [SourceLinkButton.qml](/home/joeg/Projects/sportray/components/SourceLinkButton.qml:26). **Status: fixed in the current worktree.** README now names the installed controlled path `/usr/bin/omarchy-launch-browser`; the source action and runtime behavior are unchanged.
- Release metadata was audited against the current tree. **Status: reconciled locally.** The existing `v1.0.0-rc.7` tag points to an older tree, while the current post-tag hardening changes remain unreleased and `manifest.json` now carries the owner-assigned `1.0.0-rc.8` value. No release date is asserted; do not move the existing tag.
- The preview contains ESPN and club marks. The owner confirmed permission to submit the personally captured `preview.png` as shown, including those visible marks, before accepting the Marketplace rights declaration in the [submission guide](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md).
- Public CI, `SECURITY.md`, and `CONTRIBUTING.md` are absent. These are not validator failures but would improve trust for an unsandboxed long-lived plugin.

## Verification completed

- The notification injection finding is fixed and covered by the adversarial
  model/helper-argv test described above.
- The scheduler retry-deadline finding is fixed and covered by the deadline
  admission behavior test described above.

- `tests/run-js-tests.sh`: 157 tests passed, including notification, scheduler,
  NHL lookahead, stale-date, multi-monitor ownership, and nested-pointer
  and editor-keyboard routing checks, plus reviewed team-logo and response-bound
  fixtures, unsupported-future-schema preservation, and compact/normal
  mixed-Following row geometry, plus accessibility-action source/fixture
  coverage.
- The actual Omarchy shell was fully restarted after the permission change.
  The plugin repaired `~/.local/state/omarchy/settings` to `0700` and
  `sportray.json` to `0600`; shell ping, toggle/hide IPC, and fresh log
  inspection passed with no new Sportray error, exception, or binding-loop
  warning.
- Response-bound fixtures cover normal bounded bodies, oversized streamed input,
  ESPN/NHL score and lookahead event-count rejection, and preservation of a
  failed league's last-good data beside a healthy sibling.
- Team-logo fixtures prove the exact reviewed HTTPS hosts are accepted and HTTP,
  untrusted-host, malformed, and missing values normalize to neutral `null`
  logos; image bindings retain initials when a logo is absent or fails.
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
  tail contained normal provider/cache activity without a new Sportray error,
  exception, or binding-loop warning. The changed plugin was exercised through
  toggle/hide IPC; isolated MLB timeout warnings remained on the provider retry
  path. The existing Qt.atob deprecation and unrelated desktop portal
  registration warning were unchanged. An intentionally oversized live
  provider response was not injected.
- No telemetry, accounts, secrets, downloaded-code execution, or privileged operations were found.

The lookahead, stale-date, multi-monitor ownership, nested-pointer, editor-
keyboard routing, destruction-safety, reviewed asset-host, and response-bound
implementations, fixtures, tests, roadmap, and review handoff were changed in
this hardening history. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 and Quickshell 0.3.0
remain the runtime boundary sources.

## Latest handoff — 2026-08-23 unsupported future settings schema preservation

The unsupported-schema preservation unit is complete. This checkout
intentionally has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1
and Quickshell 0.3.0.r20 sources were inspected. `FileView` continues to use
`QDir::mkpath` for missing parents and `QSaveFile` for atomic writes, with no
permission-setting or rollback API; no upstream boundary change was needed.

Future state files now remain byte-for-byte unchanged while the UI uses safe
defaults and all persistence writes are gated. Schema-1 and corrupt recovery,
permission hardening, reinstall retention, bounded fields, and canonical IDs
remain intact. The deterministic suite has 155 passing tests, plugin
validation, real-import-path QML lint, and diff checks pass, and tests never
touch the real settings path. No runtime restart was needed for this pure
parser/store gate, so no fresh Quickshell log or live permission measurement
was claimed.

Next bounded unit: fix the mixed Following row geometry so the trailing source
action remains visible and reachable at the narrowest supported panel width.
Keep provider parsing and normalized row identity unchanged; stop before
accessibility, packaging, release, or Marketplace work.

## Latest handoff — 2026-08-23 mixed Following row geometry

The mixed Following layout unit is complete in the current worktree. The
checkout intentionally has no `docs/upstream-contract.md`; installed Omarchy
4.0.0-1 and Quickshell 0.3.0.r20 sources were rechecked. `KeyboardPanel`
requests the desired 400px width but fits it to available screen space, while
Sportray's compact panel bound is 280px. No upstream API deviation was
introduced.

`GameRow` now separates the footer metadata region from the source action. The
source action is anchored to the trailing edge, and `GameRowLayout.footerLayout`
accounts for mixed-league context text, favorite metadata, source width, all
gaps, and a minimum detail budget. The provider-neutral game model, favorite
ordering, source URL policy, row actions, and panel height bounds are
unchanged. Fixture-driven coverage exercises the verified mixed Following
identity/order at 280px and 400px, proving a non-empty reachable source region
without overlap.

The complete deterministic suite passes with 156 tests. `omarchy plugin
validate "$PWD"`, real-import-path QML lint over all QML files (exit 0 with
the established warnings), and `git diff --check` pass. The linked plugin was
rescanned on actual Omarchy; one Quickshell instance remained healthy, shell
ping returned `ok`, toggle/hide IPC worked, and the fresh log showed no new
Sportray error, exception, or binding-loop warning. The isolated MLB timeout
warnings stayed on the existing provider retry path. The settings directory
remains `0700` and `sportray.json` remains `0600`.

No push, tag, release, or Marketplace action was performed. Remaining risks
are accessibility actions, the host `settings` property compatibility note,
release metadata, and preview rights.

Next bounded unit: complete one accessibility-action slice for the existing
scoreboard and utility controls: inspect the installed Qt/Omarchy accessibility
contract, then ensure the source, retry, View day, empty-state, favorite, and
whole-row actions expose one usable assistive press/toggle route without
changing provider parsing, row identity/order, pointer routing, or persisted
settings. Stop before packaging, tagging, pushing, release, or Marketplace
work. The next unit must add fixture/source-driven coverage, rerun all
repository gates, update the roadmap/review/next prompt, and create one
atomic commit only after the gate passes.

## Latest handoff — 2026-08-23 accessibility actions

The accessibility-action hardening unit is complete. Installed Omarchy
4.0.0-1, Quickshell 0.3.0.r20, and Qt 6.11.2 QtQuick accessibility metadata
were inspected; Qt's attached Accessible type supplies pressAction and
toggleAction signals with checkable/checked state, and no Omarchy-specific
API deviation was needed.

The shared semantic button, source action, retry status, View day/next-game
card, empty-state utility action, scoreboard whole-row action, and favorite
team checkbox now expose one assistive route to their existing action. Disabled
buttons and missing source URLs are non-activatable; unavailable game rows
remain readable static text. Pointer routing, keyboard routing, provider
parsing, normalized row identity/order, source URL policy, and persisted
settings are unchanged.

The new fixtures/accessibility-actions/actions.json source-driven coverage
passes with 157 total deterministic tests. Real-import-path QML lint, Omarchy
plugin validation, and git diff --check pass. The linked plugin was rescanned
and exercised through toggle/hide IPC on actual Omarchy; one shell remained
healthy, ping returned ok, the fresh log had no new Sportray error, exception,
or binding-loop warning, and settings remained 0700/0600.

No upstream API deviation, push, tag, release, or Marketplace action occurred.
The next bounded unit is to rename Sportray's local Panel settings binding to
settingsStore so it no longer redeclares the host Panel's settings property.
Preserve behavior and stop before release or publication work.

## Latest handoff — 2026-08-23 host settings-property compatibility

The host-property compatibility unit is complete. The checkout intentionally
has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1's
`qs.Ui.Panel` source confirms that `settings` is a host property used by the
inline `setting(name, fallback)` helper. Installed Quickshell is
`0.3.0.r20.g28771c7-2`, and the real QML import path remains the lint boundary.
No upstream API deviation was introduced.

Sportray's `Panel.qml` now uses `settingsStore` for favorite and enabled-league
reads, settings-change invalidation, and the settings hub. `BarWidget.qml`
injects the shared store through that distinct property. Permission repair,
future-schema preservation, favorite/notification behavior, persisted path,
and schema-1 state behavior are unchanged. The fixture-backed source test
proves the declaration, all changed consumers, and removal of the old local
declaration/injection.

The complete suite passes with 158 tests. Plugin validation, real-import-path
QML lint (exit 0 with established warnings), and `git diff --check` pass. No
live shell rescan was required for this source-only change; no new runtime log
result is claimed. No push, tag, release, or Marketplace action occurred.

The next bounded unit is documentation-only: correct README's controlled
dependency inventory to include the existing `omarchy-launch-browser` source
action, without changing runtime behavior. Release metadata and preview rights
remain owner-controlled gates.

## Historical next-session prompt (superseded by `NEXT_SESSION_PROMPT.md`)

```text
Work in /home/joeg/Projects/sportray on the next public-release hardening
unit: protect the persisted settings file and its parent directories with
least-privilege permissions.

Read AGENTS.md, README.md, docs/upstream-contract.md, roadmap.md, and the latest
roadmap/review handoff before editing. This checkout intentionally has no
docs/upstream-contract.md; verify any Omarchy/Quickshell boundary against
installed Omarchy 4.0.0-1 sources and record that fact. Inspect git status,
branch, and recent commits; preserve unrelated changes.

Verified starting state:
- Notification injection, scheduler retry deadlines, NHL lookahead bounds,
  stale-date admission, multi-monitor ownership, nested pointer routing,
  editor keyboard routing, destruction-safe callbacks, reviewed logo hosts,
  and provider response/event bounds are fixed.
- model/ResponsePolicy.js sets a 2 MiB curl transport limit, a conservative
  streamed-text admission limit, and a 256-event provider limit. LeagueFetch
  uses curl --max-filesize and bounded SplitParser chunks for both score and
  lookahead requests; ESPN and NHL parsers reject over-count payloads before
  normalization.
- fixtures/response-bounds/limits.json covers normal input, oversized streamed
  input, ESPN/NHL score and lookahead over-counts, and preservation of a failed
  league beside a healthy sibling.
- 152 deterministic tests, omarchy plugin validate "$PWD", real-import-path
  qmllint over all QML files (with established warnings), and git diff --check
  pass.
- Installed Omarchy is 4.0.0-1 and Quickshell 0.3.0. Process wraps QProcess,
  StdioCollector buffers all parser input, and this checkout has no
  docs/upstream-contract.md; the response unit uses SplitParser chunk
  admission plus the curl bound.
- The linked plugin was rescanned and normal provider fetch plus toggle/hide
  was exercised. One Quickshell instance remained healthy, shell ping returned
  ok, and the fresh log tail had no new Sportray error, exception, or
  binding-loop warning. No oversized live response was injected.
- Known remaining risks are settings permissions, unsupported future schemas,
  mixed Following layout, accessibility actions, release metadata, and
  preview rights. Do not execute provider-supplied commands or broaden this
  unit.

Bounded outcome:
Ensure ~/.local/state/omarchy/settings/sportray.json is created or repaired
with owner-only file permissions and owner-only parent directories, while
keeping schema-1 persistence, safe recovery, reinstall retention, and existing
user settings behavior intact. Do not redesign the schema or move the path.

Required checks:
- Inspect services/SettingsStore.qml, all state-file read/write paths, and the
  installed Omarchy/Quickshell file-write boundary before editing. Record any
  upstream deviation in roadmap.md and later the README.
- Add deterministic coverage for a new file, an overly-permissive existing
  file, parent-directory repair, valid schema-1 round trips, and safe behavior
  when permissions cannot be repaired. Use a temporary path or pure policy
  seam; never mutate the user’s real settings during tests.
- Preserve corrupt/unsupported-schema recovery and never log raw settings or
  provider data. Do not weaken bounded fields or canonical IDs.
- Run tests/run-js-tests.sh.
- Run omarchy plugin validate "$PWD" on actual Omarchy.
- Run /usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell over all QML files.
- Run git diff --check; if runtime is exercised, inspect Quickshell logs for
  new Sportray errors, exceptions, or binding-loop warnings.

Stop after this settings-permission unit. Do not combine unsupported-schema,
layout, accessibility, packaging, tagging, pushing, release, or Marketplace
work. Use subagents only for independent read-only upstream/file-permission
reconnaissance that materially improves confidence. When the gate passes,
update roadmap.md, PUBLIC_CONSUMPTION_REVIEW.md, and this prompt with the next
single bounded unit, then create one atomic Conventional Commit-style commit.
Do not commit a knowingly failing unit.
```

## Latest handoff — 2026-08-23 controlled browser-launcher inventory

The README dependency-inventory unit is complete. The source action in
`components/SourceLinkButton.qml` still invokes
`Quickshell.execDetached(["omarchy-launch-browser", sourceUrl])`; README now
names the installed controlled command path
`/usr/bin/omarchy-launch-browser` alongside the existing curl, permission,
and notification helper paths. No QML, provider, settings, lifecycle,
accessibility, pointer, keyboard, URL, or runtime behavior changed.

The checkout intentionally has no `docs/upstream-contract.md`. Installed
Omarchy 4.0.0-1 owns `/usr/bin/omarchy-launch-browser`, and installed
Quickshell 0.3.0.r20 exposes the existing `Quickshell.execDetached` list
method; no upstream API deviation was introduced. The deterministic suite,
Omarchy validator, real-import-path QML lint, and diff check pass. No live
shell rescan was needed for this documentation-only change, so no new
Quickshell log result is claimed.

No push, tag, release, or Marketplace action occurred. Remaining risks are
release metadata and preview rights. The next bounded unit is to reconcile
local release metadata and version claims with the current committed tree,
without packaging, moving the existing tag, pushing, creating a release, or
submitting to the Marketplace.

## Latest handoff — 2026-08-23 local release metadata reconciliation

The local release metadata audit is complete. The current tree is an
unreleased post-`v1.0.0-rc.7` tree: the existing annotated tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, while `manifest.json` retains the
last repository-assigned version `1.0.0-rc.7`. No repository evidence assigns
a next numeric version or release date, so no version bump, tag movement, or
release-date claim was made.

README and CHANGELOG now distinguish the last tagged candidate from the
current unreleased hardening tree. The provider, dependency, settings,
privacy, and no-backend contract remains unchanged. The checkout intentionally
has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1 owns
`/usr/bin/omarchy-launch-browser`, and Quickshell 0.3.0.r20 exposes the existing
QString-list `Quickshell.execDetached` method. The metadata-only unit adds no
runtime result claim.

The deterministic suite remains at 158 tests; Omarchy plugin validation,
real-import-path QML lint, and `git diff --check` are required gates for this
unit. No packaging, tag, push, GitHub Release, Marketplace submission, or
preview-rights decision was made.

Next bounded unit: use explicit owner-provided release inputs to record the
next version and preview-rights disposition, updating local release metadata
only where those inputs support it. If either input is absent, do not infer it;
document the blocker and stop before tagging, pushing, releasing, or
Marketplace work.

## Latest handoff — 2026-08-23 blocked release-handoff recheck

The release-handoff unit remains blocked. The owner supplied neither an
explicit next numeric version nor a preview-rights disposition for
`preview.png`; no release date was supplied either. `manifest.json` therefore
remains at the last repository-assigned `1.0.0-rc.7`, the annotated
`v1.0.0-rc.7` tag remains unchanged and peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and `HEAD` remains 20 commits
beyond that tag. No rights claim was inferred from repository history or the
preview contents.

The checkout intentionally has no `docs/upstream-contract.md`. Installed
Omarchy `4.0.0-1` and Quickshell `0.3.0.r20.g28771c7-2` were rechecked; the
existing host `Panel.settings` property and QString-list
`Quickshell.execDetached` API remain unchanged and no runtime boundary was
edited. The existing deterministic baseline is 158 passing tests. The
conditional release-edit gates were not rerun because there is no authorized
metadata edit to validate.

No packaging, tagging, pushing, GitHub Release, Marketplace submission, or
preview-rights decision occurred. Resume only after both owner-controlled
inputs are supplied; then make the smallest local metadata/review updates and
run every required gate before any later publication step. If either input is
still absent, update the blocker handoff and stop without changing release
metadata or creating a success commit.

## Latest handoff — 2026-08-23 local release-handoff completion

The owner-input blocker is resolved for local preparation. `manifest.json` now
contains `1.0.0-rc.8`, the owner confirmed permission to submit the personally
captured `preview.png` as shown including its visible provider and team marks,
and no release date was inferred. The existing annotated `v1.0.0-rc.7` tag
still peels to `de450941b5846914e1f8200f1a74ccf0a301428c`; it was not moved.

README, CHANGELOG, the version-linked deterministic assertion, this review,
and the roadmap now distinguish the assigned local candidate from the
unreleased and untagged tree. The public product, provider, settings, and
runtime contracts remain unchanged. The deterministic suite has 158 passing
tests, Omarchy validation and real-import-path QML lint pass with the
established warnings, and `git diff --check` passes. No runtime rescan was
needed or claimed for metadata/documentation-only changes.

No packaging, tagging, pushing, GitHub Release, Marketplace submission, or
issue creation occurred. The next bounded unit is to prepare the complete
Marketplace issue title and body locally for owner review, preserving the
submission guide's required headings and checklist. Stop before creating the
issue or making any other remote change.

## Latest handoff — 2026-08-23 local Marketplace issue draft

The repository-local `MARKETPLACE_SUBMISSION.md` draft is complete. It uses
the current guide's exact title `[Plugin]: Sportray`, preserves all six
required headings and their order, and preserves all five exact checked
checklist statements. The selected metadata is repository URL
`https://github.com/joega/sportray`, category `Widgets`, tags `bar, quickshell`,
and suggested missing tag `sports`. The maintainer notes identify only the
owner-authorized personally captured root `preview.png` as shown, including
its visible provider and team marks; no other asset rights are claimed.

Before editing, the version and tag relation were rechecked: manifest
`1.0.0-rc.8`, unchanged `v1.0.0-rc.7` peeling to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and an unreleased HEAD 22 commits
beyond that tag. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 and Quickshell 0.3.0.r20
remain the verified boundary sources. The deterministic suite, actual
Omarchy validation, real-import-path QML lint, and `git diff --check` pass.

No issue, package, tag, push, GitHub Release, Marketplace submission, or new
preview-rights decision occurred. The remaining gate is explicit owner review
and approval of the complete title and body.

## Latest panel-surface review -- 2026-08-27

The attached Sportray panel now uses the installed Omarchy `KeyboardPanel`'s
supported `borderSpec` property with `Border.none()`. This removes the popup
outline while retaining the themed fill, rounded card shape, zero-gap bar
attachment, host screen clamp, focus handling, and inner control borders. The
change is a surface-spec override, not a compositor window-rule change, and no
upstream API deviation was introduced.

The source checks pass: 260 deterministic tests, summon-helper tests, plugin
validation, real-import-path QML lint with established warnings, and
`git diff --check`. The installed checkout was intentionally not changed, so
no live visual screenshot or shell-log result is claimed for this source-only
review.

## Latest runtime panel check -- 2026-08-27

After the installed plugin was refreshed with the borderless override, the
shell was restarted and Sportray was resummoned. One Quickshell instance
remained healthy, shell ping returned `ok`, and fresh logs contained no
Sportray error, exception, binding-loop, or QML-load warning. A live screenshot
confirmed that the panel card has no outer popup outline; the remaining orange
lines belong to tiled terminal-window borders, and the inner game-row outline
is an intentional control border.
