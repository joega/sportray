# Sportray private roadmap

Last reviewed: 2026-08-23

## Current milestone — Marketplace publication readiness

Status: the single Marketplace submission issue #873 is closed and published.
Marketplace automation now shows exactly `submission`, `validated`, `listed`,
and `approved-and-verified`; those listing labels were not applied by this
checkout. No duplicate issue was created. The current Marketplace submission
guide and exact submission format were checked on 2026-08-23.

### Readiness outcome

- GitHub reports `joega/sportray` as public, unarchived, enabled, MIT-licensed,
  and rooted on `main`.
- Marketplace automation published and verified `io.github.joega.sportray` at
  <https://omarchyplugins.com/plugin.html?id=io.github.joega.sportray>.
- The existing issue's validator reports one root manifest, public and
  reachable repository, root README and license, Quattro compatibility, and a
  supported root preview at commit `0b0f6ca`.
- The existing issue's automated security baseline passed exact commit
  `0b0f6ca898c481fe93437a8f765edfd450fe700d` with no findings or capabilities.
- The 834x962 RGB `preview.png` is about 140 KiB, below the 50 MB and
  40-megapixel input limits.
- Public documentation now preserves Omarchy's interactive confirmation for
  install and removal, explicitly documents runtime/network dependencies and
  privilege boundaries, and explains that removal retains the separate
  preference state file.
- Proposed listing metadata remains category `Widgets`, tags `bar` and
  `quickshell`, with optional missing-tag suggestion `sports`.
- `MARKETPLACE_SUBMISSION.md` contains the exact owner-review title and body:
  `[Plugin]: Sportray`, all six required headings in order, and the five exact
  checked checklist statements from the current submission guide.
- The local checkout is intentionally an unreleased post-tag hardening tree:
  `v1.0.0-rc.7` remains on its existing older commit, while `manifest.json`
  now carries the owner-assigned `1.0.0-rc.8` value. No release date is
  asserted. The owner confirmed permission to submit the personally captured
  `preview.png` as shown, including its visible provider and team marks.

### Acceptance evidence

- Complete deterministic JavaScript suite: pass; the nested-pointer unit adds
  deterministic source, retry, next-game, empty-action, and whole-row routing
  coverage, and the asset-host unit adds fixture-driven accepted/rejected logo
  URL coverage. The unsupported-schema unit adds fixture-driven future-schema,
  malformed-future, raw-preservation, and schema-1/corrupt recovery coverage;
  the mixed-Following layout unit adds compact/normal source-action geometry
  coverage.
- Accessibility-action fixture/source coverage proves one attached press/toggle
  route for source, retry, View day, empty-state, favorite, and whole-row
  controls, plus disabled/unavailable guards.
- `git diff --check`: pass.
- Installed Omarchy 4.0.0-1 `omarchy plugin validate`: pass.
- Real `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`: exit 0 with the
  established standalone import/unqualified-access warnings.
- `tests/run-js-tests.sh`: pass with 158 deterministic tests.
- `omarchy plugin validate "$PWD"`: pass on actual Omarchy.
- Actual Omarchy discovery lists Sportray enabled; exactly one Quickshell
  instance is running; shell ping returns `ok`; the linked checkout rescans
  successfully; the post-rescan log tail contains normal provider/cache
  activity and no Sportray error, exception, or binding-loop warning.
- The changed README alone produces no finding or capability under the exact
  Marketplace security-baseline analyzer.

### Remaining publication gates

- The Marketplace listing-review gate is complete on the existing issue #873:
  it is closed, has exactly `submission`, `validated`, `listed`, and
  `approved-and-verified`, and its publication comment links the verified
  listing.
- The public `origin/main` and local `HEAD` resolve to
  `0b0f6ca898c481fe93437a8f765edfd450fe700d`, matching the current validator,
  security, and publication snapshot. No newer-version verification action was
  requested or run.
- If Marketplace requests repository changes, new rights claims, or a
  different target commit, stop for owner direction. A newer listed version
  may be published only through the Marketplace verification form using the
  full target SHA and explicit owner authorization. A GitHub Release remains
  a separate, unauthorized action.

## Previous milestone — public visibility handoff

Status: post-visibility verification complete. The repository is publicly
readable and the release candidate passed the anonymous access and Omarchy
install smoke gates below.

The public branch and release tag now share one clean root commit:

- `main`: `de450941b5846914e1f8200f1a74ccf0a301428c`
- `origin/main`: `de450941b5846914e1f8200f1a74ccf0a301428c`
- `v1.0.0-rc.7^{}`: `de450941b5846914e1f8200f1a74ccf0a301428c`
- annotated tag object: `1c6a205177c6d8ce34b468bc79bc24c66ef7ae39`

## Product contract

- Native Omarchy Quattro `bar-widget`; never start a second Quickshell process.
- Eight leagues: NHL, NFL, MLB, NBA, NCAA Football, NCAA Men's Basketball,
  Premier League, and MLS.
- No account, API key, Sportray backend, telemetry, database, or daemon.
- Provider parsing stays in `providers/`; QML consumes normalized games.
- Settings remain bounded schema-1 JSON with canonical
  `<league>:<providerTeamId>` favorite identities.
- Future settings schemas remain opaque: Sportray uses safe schema-1 defaults
  without rewriting the newer file, and persistence stays gated until a
  compatible state-file reload replaces it.
- Polling owns at most one request per league, preserves last-good data, and
  isolates provider failures.
- Notifications remain favorite-only, first-fetch silent, deduplicated, and
  routed through `/usr/bin/omarchy-notification-send` argument arrays.

## Pre-publication cleanup outcome

- Updated the release-asset assertion for the maintained 834×962 preview.
- Corrected README and changelog text so it no longer claims the pushed RC tag
  does not exist.
- Removed `AGENTS.md`, `roadmap.md`, `NEXT_SESSION_PROMPT.md`, and `docs/` from
  the public tree and every public commit.
- Replaced the development history with one clean public root commit. Detailed
  product changes remain summarized in `CHANGELOG.md`.
- Force-updated only remote `main` and `v1.0.0-rc.7` using exact leases and one
  atomic push.
- Preserved the original private history in
  `/home/joeg/Projects/sportray-pre-public-backup-20260819.bundle`, SHA-256
  `20ef230f3708643c51c1ca97a4f78203730e2858600403037cf1cc93e82979d1`.

## Verification

- The complete deterministic JavaScript suite passes, including the release
  asset gate and all later polling, freshness, recovery, and privacy cases.
- `git diff --check` passes.
- `omarchy plugin validate` passes.
- Real-import-path `qmllint` exits 0 with the known standalone host/import and
  unqualified-access warnings.
- A clean local clone passes the full suite, diff check, validator, and lint.
- Actual Omarchy has one running shell, shell ping returns `ok`, and the
  inspected log has no new Sportray error or binding-loop warning.
- A fresh mirror of GitHub contains one parentless commit, no private planning
  paths or agent terms, no local machine paths, and no detected credential,
  private-key, or authenticated-URL patterns.
- After visibility changed, anonymous `git ls-remote` returned the expected
  `main`, annotated `v1.0.0-rc.7`, and peeled tag refs; a fresh anonymous clone
  resolved to the expected root and contained no private planning paths or
  handoff terms.
- The fresh public checkout passed the complete JavaScript suite, `git diff
  --check`, `omarchy plugin validate`, and real-import-path `qmllint` (exit 0
  with the known standalone host/import and unqualified-access warnings).
- Actual Omarchy had exactly one running shell, `shell ping` returned `ok`, and
  the post-open Sportray log tail contained only normal polling/fetch activity.
- The installed panel was opened once and visually rendered the current local
  date, Wednesday 2026-08-19, with the Following slate showing live MLS and
  final-game rows.

## Known risks

- ESPN is an undocumented website API and may change without notice.
- The preview contains provider team marks; README attributes the data sources,
  but legal/trademark review remains user-owned.
- GitHub UI metadata could not be inspected through `gh` because the CLI is not
  authenticated. The user confirmed the repository contains only pushed code.
- Marketplace submission remains intentionally out of scope and requires
  separate user authorization.

## Latest handoff — 2026-08-19 post-visibility verification

The user changed `joega/sportray` to public. Anonymous refs, a fresh clone, the
complete JS suite, diff check, production validator, real-import-path lint,
single-shell check, shell ping, clean post-open logs, and one visual panel open
all passed. The public refs remain `main` and peeled `v1.0.0-rc.7` at
`de450941b5846914e1f8200f1a74ccf0a301428c`, with annotated tag object
`1c6a205177c6d8ce34b468bc79bc24c66ef7ae39`. No private planning paths or terms
appeared in the fresh clone. The panel showed the current local date and a
rendered Following slate. No source changes were needed; only this private
roadmap and the next-session prompt are being committed. Do not publish the
private recovery bundle, modify remote refs, create a GitHub Release, or submit
to the Marketplace without separate authorization.

Known risks remain ESPN's undocumented API and provider marks in the preview;
legal/trademark review is user-owned. The `docs/upstream-contract.md` file is
intentionally absent from the public tree; installed Omarchy source was used
for the runtime command and import-path checks.

## Latest handoff — 2026-08-19 regional availability documentation

The README now documents that Sportray has only been tested in the United
States, that ESPN and NHL.com access may vary by region, and that contributions
for additional data adapters, providers, sports, and leagues are welcome. This
is documentation-only; no provider or runtime behavior changed. The private
planning files remain excluded from the public tree.

Next bounded unit: take a separately authorized source or release follow-up.

## Latest handoff — 2026-08-19 Marketplace publication readiness

The repository has been audited against the live Marketplace publishing guide,
CLI/agent submission guide, installed Omarchy 4.0.0-1 validator, and the
Marketplace's exact validation and security-baseline implementation. Remote
commit `9438e6120c6efe579906c56e105463938bd83aeb` passed Marketplace validation
and baseline v3 with no findings or capabilities. The plugin ID and repository
are absent from the current registry. The README and changelog now preserve the
interactive install/removal confirmations and explicitly document required
runtime/network access, privilege boundaries, and retained preference state.

Local commit `4be78fd1d3a22b21b0764b9133679908f09032c6` contains the publication
documentation hardening. Local repository checks pass: the complete JS suite,
diff check, production plugin validator, real-import-path lint (exit 0 with
established warnings),
single-shell check, plugin discovery, shell ping, toggle/hide IPC, and clean
Sportray log inspection. Commit `4be78fd` has not been pushed, no GitHub Release
was created, and no Marketplace issue was opened.

Next bounded unit: after explicit user authorization, push the one local commit,
rerun the exact Marketplace validator and baseline against the new remote HEAD,
show the completed issue title/body, obtain the owner's confirmation of all
five checklist statements (especially preview rights), and create the
submission issue only after explicit final approval. Stop before submission if
the remote head differs, any exact-SHA check fails, or rights confirmation is
not provided. The provider/team marks in `preview.png`, ESPN's undocumented API,
and non-U.S. availability remain known risks.

## Latest handoff — 2026-08-22 public-consumption scheduler hardening

The notification delivery boundary was hardened in `9f5ca8b`: provider-derived
notification text is sanitized, bounded, and protected from option injection;
the installed helper was exercised with a safe `notify-send` stub. The scheduler
deadline unit is now complete in the current worktree: `PollPolicy` exposes
earliest-deadline and remaining-delay helpers, and `PollScheduler` preserves an
earlier retry when healthy aggregate updates request a longer cadence. The full
deterministic suite passes with 144 tests, `omarchy plugin validate` passes on
actual Omarchy, real-import-path `qmllint` exits 0 with established warnings,
and `git diff --check` passes.

No push, tag, release, or Marketplace submission was performed. The checkout
intentionally has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1
behavior remains the runtime boundary source. Known remaining risks include
multi-monitor duplicate graphs, stale date re-enable state, nested pointer
activation, keyboard search routing,
destruction-time callbacks, asset-host policy, curl limits, settings file
permissions, and release metadata/rights gates.

Next bounded unit: prevent stale date data from being restored after
disable/date-change/re-enable. Stop before multi-monitor, scheduler, nested
interaction, keyboard routing, packaging, or publication work.

## Latest handoff — 2026-08-22 NHL lookahead bound

The NHL empty-day lookahead unit is complete in the current worktree. A pure
`model/LookaheadPolicy.js` guard requires every returned date to be valid and
strictly later than the date just requested, retains the existing 35-day window,
and caps the lookup at eight requests. `services/LeagueFetch.qml` counts
lookahead requests, rejects repeated, earlier, malformed, out-of-range, and
over-limit responses, and stores the safe `unavailable` result through the
existing six-hour lookahead cache.

Fixture-driven tests cover repeated, earlier, malformed, over-limit, and valid
later NHL schedule responses; the valid fixture confirms the first upcoming
game and date are still selected. The complete JavaScript suite passes with 145
tests, `omarchy plugin validate "$PWD"` passes on actual Omarchy,
real-import-path `qmllint` exits 0 with the established warnings, and
`git diff --check` passes. No Quickshell runtime was exercised, so no new log
check was needed. The checkout intentionally has no `docs/upstream-contract.md`;
installed Omarchy 4.0.0-1 behavior remains the runtime boundary source.

No push, tag, release, or Marketplace submission was performed. Known remaining
risks are multi-monitor duplicate graphs, stale date re-enable state, nested
pointer activation, keyboard search routing, destruction-time callbacks,
asset-host policy, curl limits, settings file permissions, and release
metadata/rights gates.

Next bounded unit: prevent stale date data from being restored after
disable/date-change/re-enable. Stop before multi-monitor, scheduler, nested
interaction, keyboard routing, packaging, or publication work.

## Latest handoff — 2026-08-22 stale date snapshot admission

The stale date restore unit is complete in the current worktree. `LeagueFetch`
now clears the active and last-known snapshot on every initialized selected-date
change, including while a league is disabled, while retaining the bounded
date-keyed cache. Re-enable restoration is admitted only when
`DateCachePolicy` proves that the last-known snapshot and selected date match.
Same-date disable/re-enable, selected-date cache restoration, failure recovery,
and provider-neutral presentation state remain intact.

Fixture-driven tests in `fixtures/transitions/m6-4.json` cover same-date
restore, date changes while disabled, empty snapshots, and protection of
current games. The complete JavaScript suite passes with 146 tests.
`omarchy plugin validate "$PWD"` passes on actual Omarchy 4.0.0-1,
real-import-path `qmllint` exits 0 with the established host/import and
unqualified-access warnings, and `git diff --check` passes. The linked plugin
was rescanned in the live shell; one Quickshell instance remained healthy,
shell ping returned `ok`, and the post-rescan log tail showed normal
provider/cache activity without a Sportray error, exception, or binding-loop
warning. The only warning observed was the pre-existing Qt.atob deprecation.
No manual date-toggle UI sequence was exercised.

The checkout intentionally has no `docs/upstream-contract.md`; installed
Omarchy 4.0.0-1 remains the runtime boundary source. No push, tag, release, or
Marketplace submission was performed.

Known remaining risks are duplicate multi-monitor polling/notification graphs,
nested pointer activation, keyboard search routing, destruction-time callbacks,
asset-host policy, curl limits, settings file permissions, unsupported future
schemas, mixed Following layout, accessibility actions, release metadata, and
preview rights.

Next bounded unit: prevent nested game-row and child-action pointer activation
from firing two actions. Stop before keyboard routing, destruction callbacks,
packaging, tagging, pushing, or Marketplace work.

## Latest handoff — 2026-08-22 multi-monitor ownership

The multi-monitor ownership unit is complete. The checkout intentionally has
no `docs/upstream-contract.md`, so installed Omarchy 4.0.0-1 sources were
rechecked: `Bar.qml` creates a `ModuleSlot`/bar-widget item for every
`Quickshell.screens` entry. Sportray now imports one engine-wide
`SportrayService` QML singleton. It is the exclusive owner of `SettingsStore`,
`FetchService`, and `NotificationService`; every per-screen widget/panel is a
view that registers open/lookahead context. Shared selected-date state retains
the normal single-monitor reset to today when a panel closes.

`MonitorOwnership.js` covers two open panels, lookahead handoff, close, and
removal. Source topology assertions prove the singleton has exactly one
settings, fetch, and notification graph and repeated panel/widget views have
none. The full deterministic suite passes with 147 tests. `omarchy plugin
validate "$PWD"` passes on actual Omarchy 4.0.0-1; real-import-path `qmllint`
over all QML files exits 0 with established warnings; and `git diff --check`
passes. The linked plugin was rescanned: one Quickshell instance, shell ping,
and toggle/hide IPC were healthy. The post-rescan log shows one Sportray
polling initialization with normal cache/fetch activity and no Sportray error,
exception, or binding-loop warning. The existing `Qt.atob` deprecation remains.

No push, tag, release, or Marketplace action was performed. Remaining risks:
nested pointer activation, keyboard search routing, destruction-time callbacks,
asset-host policy, curl limits, settings permissions, future schemas, mixed
Following layout, accessibility actions, release metadata, and preview rights.

## Latest handoff — 2026-08-22 nested result-row pointer activation

The nested pointer-activation unit is complete. The checkout intentionally has
no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1 and Qt 6.11.1 headers
were used as the boundary source. `QQuickTapHandler` is a `PointerHandler` and
has no child-control exclusion policy, while the installed pointer contract
exposes independent grab permissions. Sportray therefore explicitly gates the
delegate `TapHandler` on each nested action's `MouseArea.pressed` state. A
source link, status retry, next-game source or View day control, and the empty
card action cancel/disable the enclosing row handler for their pointer press;
unpressed whole-row taps retain the existing one primary action. Keyboard and
accessible actions remain on their existing `Keys` and `Accessible` paths.

`PointerInteractionPolicy.js` keeps the pressed-state decision deterministic.
The suite now has 148 tests, including source/retry/next-game/empty child
actions and whole-row routing. `tests/run-js-tests.sh`, installed Omarchy
4.0.0-1 `omarchy plugin validate "$PWD"`, real-import-path `qmllint` over all
QML files (exit 0 with the established standalone warnings), and
`git diff --check` pass. Runtime was not exercised for this unit, so no new
Quickshell log inspection was needed.

No push, tag, release, or Marketplace action was performed. Remaining risks:
keyboard search routing, destruction-time callbacks, asset-host policy, curl
limits, settings permissions, future schemas, mixed Following layout,
accessibility actions, release metadata, and preview rights.

Next bounded unit: make the installed `PanelKeyCatcher` yield ordinary text
input to active editors while retaining Escape behavior. Stop before
destruction callbacks, asset-host policy, packaging, tagging, pushing, or
Marketplace work.

## Latest handoff — 2026-08-22 editor keyboard routing

The editor keyboard-routing unit is complete. The checkout intentionally has
no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1
`PanelKeyCatcher.qml` was inspected and confirms a `Keys.BeforeItem` handler
whose `blocked` property forwards all keys to descendants. Sportray now blocks
the catcher while the settings team search editor is focused (or the sport
popup is open), so `h`, `j`, `k`, `l`, `x`, Space, and ordinary text reach the
active editor. Team-picker Escape is explicitly wired through `SettingsHub` to
the panel's existing close-utility path; when no editor owns focus, catcher
Escape and navigation retain their existing routes.

`KeyboardRoutingPolicy.js` provides the pure routing decision used by the QML
binding. Deterministic coverage exercises active-editor shortcuts, editor
Escape, popup ownership, catcher Escape, catcher navigation, and ordinary
panel text routing. The complete suite passes with 149 tests.
`omarchy plugin validate "$PWD"`, real-import-path `qmllint` over all QML files
(exit 0 with established standalone warnings), and `git diff --check` pass.
Runtime was not exercised for this unit, so no new Quickshell log inspection
was needed.

No push, tag, release, or Marketplace action was performed. Remaining risks:
destruction-time callbacks, asset-host policy, curl limits, settings
permissions, future schemas, mixed Following layout, accessibility actions,
release metadata, and preview rights.

Next bounded unit: guard delayed panel callbacks and destruction-time work from
running after their owning panel or list has been destroyed. Stop before
asset-host policy, packaging, tagging, pushing, or Marketplace work.

## Latest handoff — 2026-08-23 destruction-safe deferred callbacks

The destruction-safety unit is complete in the current worktree. `model/LifecyclePolicy.js`
provides plain-JavaScript owner tokens with generation capture, live admission,
and invalidation. `Panel.qml` routes every plugin-owned `Qt.callLater` through
panel or result-list guards, invalidates both owners in `Component.onDestruction`,
and stops its delayed height/clock timers. `BarWidget.qml`, `SettingsHub.qml`,
and `TeamPicker.qml` use the same guard; SettingsHub passes the panel token to
its child picker. The inherited popout-close callback is locally overridden so
its deferred state reset is guarded too. The existing row tap policy now reads
its nested-action state from the delegate parent scope, fixing a runtime
`ReferenceError` found during validation without changing pointer behavior.

Deterministic coverage now has 150 tests, including live callback admission,
destroyed-owner rejection, idempotent invalidation, source-level panel/list
guards, and timer teardown. `tests/run-js-tests.sh`, `omarchy plugin validate
"$PWD"`, real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell`
over all QML files, and `git diff --check` pass. The checkout intentionally
has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1 sources and the
current Quickshell 0.3.0.r20 shell were used for the lifecycle/timer boundary.

Actual Omarchy validation restarted the shell after a plugin rescan, confirmed
one running Quickshell instance, exercised the Sportray toggle/hide path, and
inspected the fresh log. Provider/cache activity was normal and no new
Sportray error, exception, or binding-loop warning appeared; the unrelated
desktop portal registration warning was unchanged. No push, tag, release, or
Marketplace action was performed.

Known remaining risks are reviewed asset-host policy, curl limits, settings
permissions, unsupported future schemas, mixed Following layout, accessibility
actions, release metadata, and preview rights.

Next bounded unit: restrict provider-supplied team logo URLs to HTTPS and a
reviewed host allowlist while preserving neutral logo fallbacks. Stop before
curl response limits, settings permissions, packaging, tagging, pushing, or
Marketplace work. The next unit must inspect current provider/logo fixtures,
add deterministic accepted/rejected URL coverage, validate the QML image
boundary, rerun the full repository gates, update this roadmap/review/prompt,
and create one atomic commit only after all gates pass.

## Latest handoff — 2026-08-23 reviewed team-logo asset hosts

The team-logo asset-host unit is complete in the current worktree. The checkout
intentionally has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1
sources were rechecked for the unchanged native `Image`/bar-widget boundary,
and the installed version is `4.0.0-1`. Existing provider fixtures verify the
reviewed asset hosts: ESPN logos use the exact host `a.espncdn.com`, while NHL
logos use the exact host `assets.nhle.com`.

`model/AssetUrlPolicy.js` now accepts only HTTPS logo URLs from those exact
hosts. `TeamModel` and `GameModel` use the shared policy when CommonJS is
available; the ESPN/NHL provider normalization fallbacks used by the
QML-loaded shell enforce the same host checks when it is not. Team and game
links retain their separate existing URL handling. `GameRow.qml` and
`TeamPicker.qml` continue to map missing, rejected, malformed, or failed
images to initials/neutral fallbacks.

`fixtures/asset-hosts/team-logo-urls.json` and the deterministic suite cover
accepted HTTPS URLs and rejected HTTP, untrusted-host, malformed, and missing
values through both team and game normalization. The suite passes with 151
tests. `omarchy plugin validate "$PWD"` passes on actual Omarchy 4.0.0-1;
real-import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over
all QML files exits 0 with the established standalone warnings; and
`git diff --check` passes. No runtime rescan or manual image exercise was
needed because no QML image binding or Omarchy boundary changed.

The README and public-consumption review now document the reviewed hosts and
neutral fallback behavior. No curl-limit, settings-permission, packaging,
tagging, pushing, release, or Marketplace work was performed.

Known remaining risks are provider response buffering and event-count limits,
settings permissions, unsupported future schemas, mixed Following layout,
accessibility actions, release metadata, and preview rights.

Next bounded unit: bound provider response sizes and parsed event counts before
they reach the normalized scoreboard model. Stop before settings permissions,
packaging, tagging, pushing, or Marketplace work. Inspect the installed
Omarchy 4.0.0-1 process/collector contract, add fixture-driven oversized and
bounded-response coverage, rerun the repository gates, update the roadmap,
review, and next-session prompt, and create one atomic Conventional
Commit-style commit only after all gates pass.

## Latest handoff — 2026-08-23 provider response and event bounds

The provider response-admission unit is complete in the local commit
`66202b9`. The
checkout intentionally
has no `docs/upstream-contract.md`; installed Omarchy 4.0.0-1 and Quickshell
0.3.0 sources were inspected. The current `Process` wraps `QProcess`, reads
available stdout with `readAll`, and passes it to a parser. `StdioCollector`
appends every incoming chunk to its internal buffer and exposes complete text at
stream end; it has no size property. `SplitParser` with an empty marker emits
chunks without retaining a parser buffer, which is now the QML admission path.

`model/ResponsePolicy.js` sets a deliberate 2 MiB `curl --max-filesize`
transport limit, a conservative streamed-text limit of 699,050 UTF-16 code
units, and a 256-event cap. `services/LeagueFetch.qml` uses the transport limit
and bounded `SplitParser` accumulation for both score and lookahead requests;
an over-limit chunk kills only that league request and follows the existing
isolated failure/retry path. `EspnProvider` rejects oversized `events` arrays,
and `NhlProvider` rejects oversized `games` and nested schedule event arrays,
before calling `parseGame` or producing normalized models. Normal responses,
last-good snapshots, and healthy sibling leagues remain unchanged.

`fixtures/response-bounds/limits.json` and the deterministic suite cover normal
bodies, oversized streamed input, ESPN score/next-game and NHL score/schedule
over-counts, and preservation of a failed NHL snapshot beside a healthy MLB
snapshot. The suite passes with 152 tests. `omarchy plugin validate "$PWD"`
passes on actual Omarchy 4.0.0-1, real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files exits
0 with the established standalone warnings, and `git diff --check` passes.

The linked plugin was rescanned. One Quickshell instance remained healthy,
shell ping returned `ok`, normal provider fetches exited successfully, and a
toggle/hide exercise plus fresh log inspection showed no new Sportray error,
exception, or binding-loop warning. The only warnings were the pre-existing
Qt.atob deprecation and unrelated desktop portal registration warning. No
intentionally oversized live provider response was injected. README and the
public-consumption review now document the bounds and the deliberate limitation
that the checked runtime path was normal input rather than an injected failure.

No push, tag, release, or Marketplace action was performed. Known remaining
risks are settings permissions, unsupported future schemas, mixed Following
layout, accessibility actions, release metadata, and preview rights.

Next bounded unit: protect the persisted settings file and its parent
directories with least-privilege permissions. Inspect `SettingsStore.qml`, all
state-file paths, and the installed file-write boundary; add temporary-path or
pure-policy coverage for new-file creation, overly-permissive existing state,
parent-directory repair, schema-1 round trips, and safe permission-repair
failure. Stop before unsupported-schema, layout, accessibility, packaging,
tagging, pushing, release, or Marketplace work. On success, update this
roadmap, `PUBLIC_CONSUMPTION_REVIEW.md`, and `NEXT_SESSION_PROMPT.md`, then
create one atomic Conventional Commit-style commit.

## Latest handoff — 2026-08-23 settings-file and parent-directory permissions

The settings-permission hardening unit is complete in the current worktree.
The checkout intentionally has no `docs/upstream-contract.md`; installed
Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 sources were inspected. The installed
`FileView` creates missing parents with `QDir::mkpath`, uses `QSaveFile` for
atomic writes, and exposes no permission-setting API, so permission repair is
implemented at the QML boundary with fixed absolute `/usr/bin/mkdir`,
`/usr/bin/chmod`, and `/usr/bin/test` argument arrays. No provider-supplied
value enters these commands.

`SettingsStore` now repairs only the plugin-owned
`~/.local/state/omarchy/settings` directory to `0700`; shared ancestors remain
unchanged. It repairs an existing regular state file to `0600` before
opening `FileView`, repairs each newly atomically-saved file after `saved`, and
blocks persistence when any required repair step fails. Schema-1 normalization,
corrupt/unsupported input recovery, canonical favorite IDs, reinstall
retention, and bounded state fields are unchanged. Permission failures emit
only a fixed stage label and never raw settings/provider data.

`model/SettingsPermissionPolicy.js` and
`fixtures/settings-permissions/permissions.json` provide deterministic
coverage for new-file admission, overly-permissive existing-file repair,
parent-directory repair, invalid repair exit codes, and post-save admission.
The existing valid schema-1 round-trip coverage remains green. The complete
suite passes with 154 tests. `omarchy plugin validate "$PWD"` passes on actual
Omarchy, real-import-path `qmllint` over all QML files exits 0 with the
established host/import and unqualified-access warnings, and `git diff --check`
passes.

Actual Omarchy was fully restarted so the startup path ran against the linked
checkout. The resulting state directory is `0700` and `sportray.json` is
`0600`; shell ping, toggle/hide IPC, normal provider initialization, and fresh
log inspection passed with no new Sportray error, exception, or binding-loop
warning. The unrelated desktop portal registration warning did not change.

No push, tag, release, or Marketplace action was performed. Known remaining
risks are unsupported future schemas, mixed Following layout, accessibility
actions, release metadata, and preview rights. The next bounded unit is to
preserve unsupported future state files for rollback instead of replacing them
with schema-1 defaults. Stop before layout, accessibility, packaging, tagging,
pushing, release, or Marketplace work.

## Latest handoff — 2026-08-23 unsupported future settings schema preservation

The unsupported-schema preservation unit is complete in the current worktree.
The checkout intentionally has no `docs/upstream-contract.md`; installed
Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 sources were inspected. The installed
`FileView` still creates missing parents with `QDir::mkpath`, uses `QSaveFile`
for atomic writes, and exposes no permission-setting or rollback API. No
upstream API deviation was introduced.

`StateModel` and `SettingsModel` now identify numeric schema versions newer than
1 as opaque future state. They return the existing safe defaults,
`status: "unsupported-schema"`, and `needsWrite: false` while retaining the
exact input text in a non-logging `preservedRawText` result field. Missing,
corrupt, older-unsupported, and schema-1 inputs retain their existing recovery
decisions. `SettingsStore` clears the retained text on every reload and blocks
all later state writes while a future file remains active, so settings actions
and transition dedupe updates cannot replace it. A compatible file reload
resumes normal permission-gated persistence.

`fixtures/settings-schemas/state.json` and the deterministic suite cover a
future schema with extra fields, a future schema with malformed field shapes,
exact raw-text preservation, valid schema-1 recovery, corrupt JSON recovery,
and the QML write gate. The suite has 155 tests. `tests/run-js-tests.sh`,
`omarchy plugin validate "$PWD"`, real-import-path `qmllint` over all QML files
(exit 0 with established standalone warnings), and `git diff --check` pass.
No provider data or settings contents are logged, the real settings path is
not used by tests, and no push, tag, release, or Marketplace action was
performed.

Known remaining risks are mixed Following layout, accessibility actions,
release metadata, and preview rights.

Next bounded unit: ensure mixed Following rows preserve a visible, reachable
trailing source action at the narrowest supported panel widths without
overlapping team/score content or changing the normalized row contract. Stop
before accessibility, packaging, tagging, pushing, release, or Marketplace
work. The next unit must inspect the current row model and QML geometry,
add fixture-driven width/layout coverage, recheck the installed Omarchy panel
surface if the boundary changes, rerun all repository gates, update the
roadmap/review/next prompt, and create one atomic commit only after all gates
pass.

## Latest handoff — 2026-08-23 mixed Following row geometry

The mixed Following row geometry unit is complete in the current worktree. This
checkout intentionally has no `docs/upstream-contract.md`; installed Omarchy
4.0.0-1 and Quickshell 0.3.0.r20 sources were rechecked. `KeyboardPanel`
requests 400px content but fits it to available space, and Sportray's compact
bound is 280px. No upstream API deviation was introduced.

`GameRow` now gives the trailing source action its own anchored geometry and
keeps context/favorite/detail metadata in a bounded flexible region.
`model/GameRowLayout.js` is provider-neutral and accounts for all visible
metadata widths and gaps. `fixtures/layout/mixed-following.json` plus the new
deterministic test cover the existing mixed Following normalized row identity
and order at 280px and 400px, proving source reachability, a non-empty detail
budget, and no overlap. Source URL admission, pointer routing, keyboard focus,
and panel height behavior are unchanged.

The complete suite passes with 156 tests. `omarchy plugin validate "$PWD"`,
real-import-path `qmllint` over all QML files (exit 0 with established
warnings), and `git diff --check` pass. Actual Omarchy was rescanned and
toggle/hide IPC exercised; one Quickshell instance remained healthy, shell ping
returned `ok`, and the fresh log showed no new Sportray error, exception, or
binding-loop warning. Isolated MLB timeout warnings remained on the existing
provider retry path. The settings directory is still `0700` and the state file
is `0600`.

No push, tag, release, or Marketplace action was performed. Remaining risks are
accessibility actions, the accepted host `settings` property compatibility
note, release metadata, and preview rights.

Next bounded unit: complete one accessibility-action slice for the existing
scoreboard and utility controls. Inspect the installed Qt/Omarchy accessibility
contract first, then add explicit assistive press/toggle routing for the source,
retry, View day, empty-state, favorite, and whole-row actions without changing
provider parsing, normalized row identity/order, pointer routing, or persisted
settings. Stop before packaging, tagging, pushing, release, or Marketplace
work. On success, update this roadmap, `PUBLIC_CONSUMPTION_REVIEW.md`, and
`NEXT_SESSION_PROMPT.md`, then create one atomic Conventional Commit-style
commit only after all gates pass.

## Latest handoff — 2026-08-23 accessibility actions

The accessibility-action hardening unit is complete in the current worktree.
This checkout intentionally has no docs/upstream-contract.md; installed
Omarchy 4.0.0-1, Quickshell 0.3.0.r20, and the Qt 6.11.2 QtQuick metadata and
headers were inspected. QtQuick's attached Accessible type exposes
pressAction and toggleAction signals plus checkable/checked state; no
Omarchy-specific accessibility API or deviation was required.

SemanticActionButton now connects the installed press-action signal to its
existing clicked() signal and ignores disabled controls. Source links bind
their action enabled state to the existing source URL policy. GameRow,
LeagueStatus, and NextGameCard connect assistive press activation to their
existing guarded primary actions, with unavailable GameRow sources represented
as static text. Team-picker favorite delegates expose explicit checkbox state
and connect assistive toggle activation to the existing favorite toggle route.
Pointer handlers, keyboard handlers, provider parsing, normalized row
identity/order, source URL admission, and schema-1 settings persistence are
unchanged.

fixtures/accessibility-actions/actions.json and the new deterministic
source-driven test prove one attached press/toggle handler and one existing
callback per changed control, preserve favorite checked state, and keep
disabled/unavailable actions non-activatable. The complete suite passes with
157 tests. omarchy plugin validate "$PWD", real-import-path
/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell over all QML files, and
git diff --check pass.

The linked plugin was rescanned on actual Omarchy; one Quickshell instance
remained healthy, shell ping returned ok, toggle/hide IPC worked, and the
fresh log tail showed normal provider/cache activity without a new Sportray
error, exception, or binding-loop warning. The settings directory remains
0700 and sportray.json remains 0600. No provider data or settings contents
were logged.

No upstream API deviation was introduced, and no push, tag, release, or
Marketplace action was performed. Known remaining risks are the accepted host
settings property compatibility note, release metadata, and preview rights.

Decision log: use the installed QtQuick attached Accessible.onPressAction and
Accessible.onToggleAction signals directly on existing controls; do not add a
new accessibility abstraction. Disabled shared actions are ignored, while
unavailable scoreboard rows retain readable static text and their action
callback is guarded.

Next bounded unit: remove Sportray's redeclaration of the host Panel
settings property by introducing the distinct plugin-local settingsStore
property, while preserving all settings reads/writes, future-schema and
permission gates, utility navigation, and persisted schema-1 behavior. Inspect
the installed Omarchy Panel source and current Panel.qml/settings bindings
before editing, add source-driven coverage for the renamed boundary, rerun all
repository gates, update this roadmap, the public-consumption review, and the
next-session prompt, then create one atomic Conventional Commit-style commit.
Stop before release metadata, packaging, tagging, pushing, release, or
Marketplace work.

## Latest handoff — 2026-08-23 host settings-property compatibility

The host-property compatibility unit is complete in the current worktree. This
checkout intentionally has no `docs/upstream-contract.md`; installed Omarchy
4.0.0-1 `/usr/share/omarchy/shell/Ui/Panel.qml` was inspected and confirms
that the host declares `property var settings` for its inline shell settings
and reads it through `setting(name, fallback)`. Installed Quickshell is
`0.3.0.r20.g28771c7-2`; its real QML import path remains the lint boundary.
No upstream API deviation was introduced.

`Panel.qml` now declares the distinct plugin-local `settingsStore` property.
All panel-owned favorite, enabled-league, settings-change, and utility-hub
bindings use that store, while the inherited host `settings` property remains
available for host behavior. `BarWidget.qml` injects the shared service store
through `settingsStore`; the settings service graph, permission repair,
unsupported-future-schema write gate, favorite/notification actions, persisted
path, and schema-1 format are unchanged.

`fixtures/settings-boundary/panel.json` and a source-driven test prove the new
declaration, reject the local `settings` redeclaration and old injection, and
cover every changed Panel consumer. The complete deterministic suite passes
with 158 tests. `omarchy plugin validate "$PWD"`, real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files, and
`git diff --check` pass; the established standalone import and unqualified
access warnings remain. No live shell rescan was needed for this source-only
boundary change, so no new Quickshell log result is claimed.

No push, tag, release, or Marketplace action was performed. Known remaining
risks are the README's controlled-browser-launcher dependency inventory,
release metadata, and preview rights. The next bounded unit is to correct the
README dependency inventory for the existing `omarchy-launch-browser` source
action without changing runtime behavior. Stop before packaging, tagging,
pushing, release, or Marketplace work.

## Latest handoff — 2026-08-23 controlled browser-launcher inventory

The README dependency-inventory unit is complete. The source action in
`components/SourceLinkButton.qml` remains
`Quickshell.execDetached(["omarchy-launch-browser", sourceUrl])`; README now
names the installed controlled command path
`/usr/bin/omarchy-launch-browser` alongside the existing curl, permission,
and notification helper paths. No QML, provider, settings, lifecycle,
accessibility, pointer, keyboard, URL, or runtime behavior changed.

This checkout intentionally has no `docs/upstream-contract.md`. Installed
Omarchy 4.0.0-1 owns `/usr/bin/omarchy-launch-browser`, and installed
Quickshell 0.3.0.r20 exposes the existing `Quickshell.execDetached` list
method; no upstream API deviation was introduced. The complete deterministic
suite, `omarchy plugin validate "$PWD"`, real-import-path QML lint, and
`git diff --check` pass. No live shell rescan was needed for this
documentation-only change, so no new Quickshell log result is claimed.

No push, tag, release, or Marketplace action was performed. Known remaining
risks are release metadata and preview rights. The next bounded unit is to
reconcile local release metadata and version claims with the current committed
tree, without packaging, moving the existing tag, pushing, creating a
release, or submitting to the Marketplace.

## Latest handoff — 2026-08-23 local release metadata reconciliation

The local release metadata audit is complete. `HEAD` is an unreleased
post-`v1.0.0-rc.7` tree; the existing annotated tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and `manifest.json` still carries
the last repository-assigned version `1.0.0-rc.7`. The repository contains no
evidence assigning a next numeric version or release date, so the manifest was
not changed and the existing tag was not moved.

README and CHANGELOG now distinguish the last tagged candidate from the
current unreleased hardening tree. Provider, dependency, settings, privacy,
and no-backend claims remain unchanged; no runtime or Omarchy/Quickshell API
boundary changed. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 owns
`/usr/bin/omarchy-launch-browser`, and Quickshell 0.3.0.r20 exposes the
existing QString-list `Quickshell.execDetached` method.

The deterministic suite remains at 158 tests. Omarchy plugin validation,
real-import-path QML lint, and `git diff --check` pass. This metadata-only unit
does not claim a new shell rescan or runtime log result. No packaging, tag,
push, GitHub Release, Marketplace submission, or preview-rights decision was
made.

The next bounded unit requires explicit owner-provided release inputs: record
the next version and preview-rights disposition, then update local release
metadata only where those inputs support it. If either input is absent, do not
infer it; document the blocker and stop before tagging, pushing, releasing, or
Marketplace work.

## Latest handoff — 2026-08-23 owner release inputs unavailable

The updated release-handoff unit is blocked because the owner did not provide
either required input: a next version assignment or a preview-rights
disposition for `preview.png`. The repository therefore retains
`manifest.json` version `1.0.0-rc.7`, the existing annotated
`v1.0.0-rc.7` tag remains unchanged, and no release date or rights claim was
inferred. `HEAD` is the unreleased post-tag hardening tree, 20 commits beyond
the tag.

The audit reconfirmed that the checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 owns
`/usr/bin/omarchy-launch-browser`, and installed Quickshell 0.3.0 revision
`28771c7` exposes the existing QString-list `Quickshell.execDetached` method.
No runtime, provider, settings, or public product contract changed. No
packaging, tagging, pushing, GitHub Release, Marketplace submission, or
preview-rights decision was made.

The repository baseline remains 158 deterministic tests, passing plugin
validation, real-import-path QML lint with the established warnings, and
`git diff --check`; these gates were rerun for this blocked handoff. No
success commit was created because the owner-controlled inputs are absent.

Decision log: do not invent a version, release date, or preview-rights status
from the current tag, commit count, or screenshot contents. Resume only when
the owner supplies both inputs; then make the smallest local metadata/review
updates and rerun all release-handoff gates before any later publication step.

Next bounded unit: with explicit owner-provided next-version and
preview-rights inputs, record those decisions in local release metadata and
review documentation without publishing. If either input is still absent,
document the blocker and stop without changing release metadata.

## Latest handoff — 2026-08-23 blocked release-handoff recheck

The blocked release-handoff unit was rechecked against the owner-provided
inputs and repository state. No explicit next numeric version, release date,
or preview-rights disposition was supplied. The repository therefore still
retains `manifest.json` version `1.0.0-rc.7`; the annotated
`v1.0.0-rc.7` tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and `HEAD` remains 20 commits
beyond that tag. No release metadata was changed and no rights decision was
inferred from the tag, commit history, or `preview.png`.

The checkout still intentionally has no `docs/upstream-contract.md`.
Installed Omarchy `4.0.0-1` and Quickshell `0.3.0.r20.g28771c7-2` were
rechecked; the existing host `Panel.settings` property and
`Quickshell.execDetached` QString-list API remain the relevant boundaries,
with no boundary change required for this documentation-only blocked unit.
The documented deterministic baseline remains 158 passing tests. Conditional
release-edit gates were not rerun because the required owner inputs are
absent and no release metadata edit is authorized.

No packaging, tagging, pushing, GitHub Release, Marketplace submission, or
preview-rights decision was made. This handoff remains blocked until the owner
supplies both the next version and the preview-rights disposition. The next
agent must update this roadmap, `PUBLIC_CONSUMPTION_REVIEW.md`, and
`NEXT_SESSION_PROMPT.md` again if the blocker persists; do not create a
success commit while the inputs remain absent.

## Latest handoff — 2026-08-23 local release-handoff completion

The owner-input blocker is resolved for local preparation. `manifest.json` now
contains the explicitly assigned `1.0.0-rc.8`, and the owner confirmed
permission to submit the personally captured `preview.png` as shown,
including its visible provider and team marks. No release date was supplied or
inferred. The existing annotated `v1.0.0-rc.7` tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`; it was not moved. `HEAD` remains
21 commits beyond that tag after the completed local metadata commit.

README, CHANGELOG, the version-linked deterministic assertion, this roadmap,
the public-consumption review, and the next-session prompt now record the
assigned local candidate while preserving the unreleased, untagged state. No
runtime, provider, settings, or Omarchy/Quickshell boundary changed. The
deterministic suite has 158 passing tests; `omarchy plugin validate "$PWD"`,
real-import-path QML lint, and `git diff --check` pass. No runtime rescan was
needed or claimed for this metadata/documentation-only unit.

No packaging, tagging, pushing, GitHub Release, Marketplace submission, or
issue creation occurred. The next bounded unit is to prepare the exact
Marketplace issue title and body locally for owner review, preserving every
required submission heading and checklist item. Stop before creating the
issue or changing remote state.

## Latest handoff — 2026-08-23 local Marketplace issue draft

The exact Marketplace submission draft is now repository-local in
`MARKETPLACE_SUBMISSION.md`. It uses the current guide's title
`[Plugin]: Sportray`, repository URL `https://github.com/joega/sportray`,
category `Widgets`, tags `bar, quickshell`, missing-tag suggestion `sports`,
and all six required headings in order. The body preserves the guide's five
exact checked checklist statements. Its maintainer note names only the
owner-authorized root `preview.png` and its visible provider/team marks; it
makes no rights claim for any other asset.

The current metadata and tag relation were audited before editing:
`manifest.json` remains `1.0.0-rc.8`, `v1.0.0-rc.7` still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and `HEAD` remains 22 commits
beyond that tag. The checkout intentionally has no `docs/upstream-contract.md`;
installed Omarchy 4.0.0-1 owns `/usr/bin/omarchy-launch-browser`, and installed
Quickshell 0.3.0.r20 exposes the existing QString-list
`Quickshell.execDetached` method. No runtime or public product behavior
changed.

The deterministic suite, `omarchy plugin validate "$PWD"` on actual Omarchy,
real-import-path QML lint over every QML file, and `git diff --check` pass. No
issue was created, and no packaging, tagging, tag movement, pushing, GitHub
Release, Marketplace submission, or preview-rights decision occurred.

Decision log: the draft is ready for owner review, but the checked ownership
statements are not treated as owner approval of the issue. Do not create the
issue until the owner explicitly approves the complete title and body.

Next bounded unit: obtain explicit owner approval of
`MARKETPLACE_SUBMISSION.md`; only if that approval is given, re-audit the
current repository state and create the single correctly formatted submission
issue. If approval is absent, update the handoff and stop without remote
changes.

## Latest handoff — 2026-08-23 Marketplace submission refresh

The existing Marketplace submission issue was found at
`HANCORE-linux/omarchy-plugin-marketplace#873`; no duplicate issue was
created. After the owner requested that the existing submission be updated,
issue #873 was edited in place to match `MARKETPLACE_SUBMISSION.md` exactly:
title `[Plugin]: Sportray`, repository URL
`https://github.com/joega/sportray`, category `Widgets`, tags
`bar, quickshell`, suggested tag `sports`, the maintainer note, and all five
exact checked checklist statements. The note claims rights only for the
personally captured root `preview.png` as shown, including its visible
provider and team marks.

The marketplace validation workflow reran successfully after the edit. Its
fresh validation comment reports Quattro compatibility at commit `4fcfa60`
and manifest version `1.0.0-rc.8`; its fresh automated security baseline also
passed at that commit with no findings or capabilities. Issue #873 remains
open with `submission` and `validated` labels and is ready for listing review.
The exact current HEAD is
`4fcfa604e61bb8f8d219c0be3ef43f92024dfda6`.

The public `origin/main` remains at `4fcfa604e61bb8f8d219c0be3ef43f92024dfda6`,
which is the commit validated by issue #873. Local `main` is clean but one
unpushed documentation-only commit (`0b0f6ca`) ahead of that public ref; it
was intentionally not pushed. The annotated `v1.0.0-rc.7` tag still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`, and the public tree is 22 commits
beyond that tag. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy 4.0.0-1 owns
`/usr/bin/omarchy-launch-browser`, and installed Quickshell 0.3.0.r20 exposes
the existing QString-list `Quickshell.execDetached` method. No runtime,
provider, settings, tag, package, push, GitHub Release, or preview-rights
decision changed.

The required local gates pass: 158 deterministic tests,
`omarchy plugin validate "$PWD"` on actual Omarchy, real-import-path
`qmllint` over every QML file with the established warnings, and
`git diff --check`. The marketplace workflow run was
`32663265652` and completed successfully.

Decision log: an existing submission must be refreshed in place rather than
duplicated. Marketplace validation and security evidence are bound to the
exact commit; later listed-version updates require the marketplace's Verify
and publish workflow with the full target SHA. Marketplace publication and
the maintainer's listing approval remain owner-controlled.

Next bounded unit: monitor existing issue #873 for maintainer listing review
and record the resulting exact verified snapshot. Do not create or duplicate
an issue, edit labels, apply approval labels, package, tag, move
`v1.0.0-rc.7`, push, or create a GitHub Release. If the maintainer requests a
repository or submission change, stop and obtain owner direction before
acting; any later listed-version update must use the verification form and a
full 40-character commit SHA.

## Latest handoff — 2026-08-23 Marketplace listing-review monitor

The read-only listing-review check found no maintainer request or listing
decision on the existing `HANCORE-linux/omarchy-plugin-marketplace#873`. The
issue remains open with exactly `submission` and `validated` labels, title
`[Plugin]: Sportray`, and a body that matches `MARKETPLACE_SUBMISSION.md`
exactly. Its metadata remains repository URL
`https://github.com/joega/sportray`, category `Widgets`, tags
`bar, quickshell`, and suggested tag `sports`.

The issue has two relevant comments: Marketplace validation reports Quattro
compatibility at `4fcfa60` with manifest `1.0.0-rc.8`, and the automated
security baseline reports a pass at exact commit
`4fcfa604e61bb8f8d219c0be3ef43f92024dfda6` with no findings or capabilities.
No newer listed version was explicitly requested, so no Marketplace
verification-form action was run.

The current remote `origin/main` read-only ref is
`0b0f6ca898c481fe93437a8f765edfd450fe700d`, while the issue evidence remains
bound to the earlier `4fcfa604…` snapshot. This differs from the prior
handoff's assumption that `0b0f6ca` was local-only; no push or other remote
write was performed in this unit. The checkout remains unreleased and
untagged, and `v1.0.0-rc.7` still peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`.

Installed Omarchy `4.0.0-1` and Quickshell `0.3.0.r20.g28771c7-2` remain the
verified boundaries; this checkout intentionally has no
`docs/upstream-contract.md`. No repository behavior, labels, rights claims,
package, tag, release, or issue content changed. The next bounded unit is a
later read-only recheck of #873 for maintainer listing activity; stop for any
repository-change, rights, or target-commit request.
