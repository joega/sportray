# Sportray private roadmap

Last reviewed: 2026-08-24

## Competitive scan — 2026-08-23

The live Omarchy plugin catalog now contains a substantial sports cluster,
including generalists (`sportsbar`, `meirdick.scores`, `io.github.brm-src.omatchday`,
and `io.github.popidge.omasoccer`) plus focused MLB, F1, football, esports,
racing, and VCT widgets. This private roadmap section records the relevant
findings so no competitive or Marketplace review document needs to enter the
public product tree.

Observed patterns:

- `meirdick.scores` is the closest generalist peer: separate team and league
  follows, standings, per-game detail, live rotation, provider fallbacks,
  ETag/gzip requests, watchdogs, and pure fixture-tested models.
- `sportsbar` emphasizes simple favorite cards, theme-matched team colors, and
  a lightweight add/remove flow.
- `io.github.brm-src.omatchday` and `io.github.popidge.omasoccer` emphasize
  football calendar/results views, in-panel settings, cross-competition club
  discovery, adaptive polling, and configurable bar modes.
- `io.github.jeremylongshore.mlb-booth` and
  `io.github.jeremylongshore.pit-wall` show the value of sport-specific depth:
  baseball inning/count/outs/last-play context and F1 live timing,
  leaderboards, gaps, race control, schedules, and standings.
- `matteodevenuto.f1-sessions` and `salmun-nister.next-race` add timezone-aware
  weekend schedules, alerts, season rollover, track maps, and circuit context.
- `contra.esports` makes spoiler-free behavior a data-layer property through a
  companion daemon; `cassian.vct-scoreline` narrows the model to live map,
  series, round, and side state.

Source links: [live catalog feed](https://omarchyplugins.com/catalog.json),
[marketplace](https://omarchyplugins.com/), and the linked repositories named
above. The marketplace page's text-rendered view currently says there are no
community plugins, so the catalog feed was used for the current inventory.

The scan changes product prioritization but not the current public contract:
Sportray should compete first on scoreboard depth and reliability rather than
adding leagues indiscriminately. The five minimum baseline capabilities are:

1. league views with sport-aware standings;
2. bounded rich game detail;
3. compact/full bar modes with stable today focus, live rotation, and
   countdowns;
4. per-league provider fallback chains where permitted; and
5. opt-in pregame and close-game alerts alongside the existing notifications.

Existing Sportray strengths remain the eight-league breadth, favorites-first
navigation, bounded date/cache/polling behavior, settings and accessibility
work, source attribution, notification safety, and no-account/no-daemon
privacy boundary. The roadmap must preserve provider parsing outside QML and
must not force non-game sports into the current two-team model.

Decision: the next product milestone should design and fixture-test standings
and league views, followed by generic game-detail data. Specialist adapters
for F1 timing, baseball situations, esports series, and additional racing
should wait until the generic baseline is accepted.

Current status update: the standings slice, generic local game-detail data and
drill-down, compact/full ambient modes, and live-favorite rotation have since
landed in the checkout. `competition.md` is now the private reference for the
catalog inventory, parity ideas, current coverage, and prioritized backlog.
The next useful parity slice is verified NHL standings; the earlier generic
standings/design recommendation is retained as historical rationale only.

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

## Latest handoff — 2026-08-23 competitive baseline review

The read-only Omarchy catalog scan found a crowded sports cluster. The closest
generalist peer is `meirdick.scores`, which combines team and league follows,
standings, per-game detail, live bar rotation, provider fallbacks, bounded
polling, watchdogs, and fixture-tested pure models. `sportsbar`, `omatchday`,
and `omasoccer` reinforce expectations around simple favorite cards, football
calendar/results views, cross-competition discovery, in-panel settings,
adaptive polling, and configurable bar modes. MLB Booth, Pit Wall, F1 Sessions,
Next Race, Esports, and VCT Scoreline demonstrate the value of optional
sport-specific depth. Source links and the complete private summary are above;
no standalone competitive document was added.

The minimum competitive baseline is now recorded as five capabilities:
sport-aware standings and useful league views; bounded rich game detail;
compact/full bar modes with stable today focus, live rotation, and countdowns;
per-league provider fallback chains where permitted; and opt-in pregame and
close-game alerts. Existing Sportray breadth, favorites-first UX, bounded
reliability/privacy work, settings, accessibility, and source attribution are
retained as strengths. Do not force F1, racing, golf, tennis, MMA, or esports
into the current two-team model before a concrete adapter requires an optional
event/participant shape.

This review remains private. `origin/main` was checked and does not contain
`AGENTS.md`, `roadmap.md`, `NEXT_SESSION_PROMPT.md`,
`PUBLIC_CONSUMPTION_REVIEW.md`, or `MARKETPLACE_SUBMISSION.md`; no push,
Marketplace action, release, tag, or public README change was performed.
The next bounded unit is standings and league-view design/implementation;
stop before game-detail, bar-mode, provider-fallback, niche-adapter, or
publication work.

## Standings/league-view slice — 2026-08-23

Status: complete. The first generic standings slice is implemented as one
bounded vertical unit. The existing scores route remains the default, and an
ESPN-backed league destination can switch to an on-demand standings view with
the `S` shortcut or its header action.

Evidence:

- `model/StandingsModel.js` defines the provider-neutral grouped standings
  boundary, canonical team identity, nullable metrics, deterministic rank/name
  ordering, and bounded malformed-input errors.
- `providers/EspnProvider.js` parses one ESPN standings payload shape, backed by
  `fixtures/espn/raw/standings-nfl.json`; the parser isolates malformed entries
  and preserves valid sibling groups.
- `services/StandingsFetch.qml` is the single shared, on-demand fetch boundary;
  `model/StandingsRows.js` keeps loading, empty, error, group, and row display
  shaping out of QML. NHL is explicitly scores-only until a verified standings
  adapter exists.
- The smallest QML route adds a virtualized grouped list and reuses the
  existing favorite action for teams. Missing values render as neutral dashes.
- The JavaScript fixture suite covers ordering, missing fields, empty and
  malformed standings, and favorite routing. `tests/run-js-tests.sh` passes.
- `omarchy plugin validate "$PWD"`, real-import-path `qmllint`, and
  `git diff --check` pass. The linked plugin was rescanned on actual Omarchy
  4.0.0-1 with Quickshell 0.3.0.r20; the view was manually opened in the live
  shell and the fresh instance log had no standings-specific QML errors or
  polish-loop warnings. The current live ESPN offseason response exercised the
  safe empty state; populated rows are covered by the fixture path.

Decision log: keep the first adapter ESPN-only and on demand. Preserve the
existing normalized game/favorite/settings boundaries, use canonical team IDs
for favorite routing, and treat provider omissions as nulls rather than
fabricating values. Do not add game detail, bar modes, provider fallback,
alerts, leagues, niche adapters, packaging, or publication work in this unit.
The intentionally absent `docs/upstream-contract.md` was checked against the
installed Omarchy/Quickshell sources; no obsolete upstream API pattern was
introduced.

Known risks: ESPN's live standings response is sparse or empty for some
offseason destinations, and no NHL standings contract has been verified.
Those cases remain safe empty/unsupported states rather than inferred data.

## Latest handoff — 2026-08-23 standings slice complete

The standings/league-view slice is complete in the working tree and ready for
its atomic commit. It adds a provider-neutral standings model and row flattener,
one fixture-backed ESPN parser path, a shared on-demand QML fetch service, and
a grouped standings route on existing ESPN-backed league destinations. The
scores route, existing favorite/settings/accessibility contracts, and NHL
scores-only behavior remain intact. No game-detail, bar-mode, provider-chain,
alert, new-league, niche-adapter, packaging, release, tag, push, or Marketplace
work was performed.

The next bounded unit is a generic game-detail data/model slice: first inspect
the current provider payloads and installed upstream boundaries, then implement
only a provider-neutral detail shape plus one fixture-backed provider parser if
the contract is reliable. Do not add the detail QML drill-down in that unit
unless its acceptance can remain one small existing-route extension.

## Game-detail data/model slice — 2026-08-23

Status: complete. The first generic game-detail data/model slice is implemented
without opening a drill-down route or changing the Quickshell boundary. It
consumes the existing normalized `GameModel` game shape and exposes a bounded,
provider-neutral detail record for a future view.

Evidence:

- `model/GameDetailModel.js` provides stable identity, away/home participants,
  nullable scores, normalized status, timing, venue, source metadata, and
  bounded error shaping. Missing optional values remain explicit `null`s.
- `providers/EspnProvider.js` adds one fixture-backed
  `parseGameDetailResponse` path. It reuses the verified ESPN scoreboard parser
  and then maps only normalized games into the detail model; no provider event
  payload reaches a consumer.
- `fixtures/espn/raw/game-detail.json` covers out-of-order valid events,
  missing optional fields, and one malformed sibling. The deterministic suite
  now passes 165 tests covering detail ordering, participant normalization,
  null preservation, malformed input, and the 256-record bound.
- `omarchy plugin validate "$PWD"` passes on installed Omarchy 4.0.0-1.
  Real-import-path `qmllint` over every QML file exits 0 with the established
  standalone host/import and unqualified-access warnings. `git diff --check`
  passes. No QML file changed, so no plugin rescan, fresh runtime log, or live
  route exercise was required for this pure model/provider unit.

Decision log: keep detail as a projection of the existing normalized game
boundary, with fixed away/home participant ordering and no provider-specific
fields. Use ESPN's already verified scoreboard event shape for the first
adapter; do not infer a separate event endpoint, box score, play-by-play, or
NHL detail contract. The provider supplies `ESPN` source metadata while the
normalized game's existing safe canonical link remains the URL source.

Known risks: ESPN is an undocumented site API and the fixture-backed detail
projection has no dedicated live event endpoint. NHL has no verified detail
adapter. A future UI must treat null participants, timing, scores, venue, and
source URL as ordinary sparse states and must not imply box-score depth that
this slice does not provide.

## Latest handoff — 2026-08-23 game-detail data/model slice complete

The generic game-detail data/model unit is complete and ready for its atomic
commit. `GameDetailModel` projects the existing normalized game shape into
provider-neutral identity, ordered participants, nullable score/status/timing
fields, venue, and source metadata. ESPN exposes one fixture-backed parser
path that reuses scoreboard normalization; malformed siblings are isolated and
detail records are sorted deterministically by start time with null times last.

The fixture suite covers valid ordering, normalization, omitted-field nulls,
malformed input, raw-payload exclusion, and the bounded 256-record admission.
The full JavaScript suite passes with 165 tests. `omarchy plugin validate
"$PWD"`, real-import-path QML lint over every QML file, and `git diff --check`
pass. No QML or Quickshell boundary changed, so no live rescan, log inspection,
or manual route exercise was claimed.

Installed Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 remain the verified
boundaries; `docs/upstream-contract.md` is intentionally absent. No new
league, provider fallback, alert, bar mode, packaging, tag, push, release, or
Marketplace action occurred. Marketplace issue #873 and public publication
remain owner-controlled.

Next bounded unit: add the smallest existing-route game-detail drill-down UI
that renders this projection from an already loaded normalized game, with no
new provider request. It must handle loading-free sparse/null fields and the
existing ESPN/NHL source link safely. Stop before detail endpoint fetching,
box-score/play-by-play adapters, bar modes, live rotation, alerts, new leagues,
provider fallback, niche sports, packaging, or publication work.

## Game-detail drill-down UI slice — 2026-08-23

Status: complete. The smallest existing-route detail presentation is now
implemented in the current working tree. A valid loaded game row opens a local
detail view; the view owns its selected game and cursor state inside the current
panel and does not issue a request.

Evidence:

- `components/GameDetailView.qml` projects the already normalized game through
  `GameDetailModel.normalizeDetail`, then renders provider-neutral identity,
  away/home participants and scores, status/timing, venue, and the existing
  guarded `SourceLinkButton`. Missing scores, timing, venue, and source metadata
  remain neutral placeholders.
- `model/ResultRows.js` gives valid game rows the typed `open-detail` action even
  when the provider URL is absent. `GameRow.qml` routes whole-row pointer,
  keyboard, and assistive activation to the local detail route while its nested
  source button remains the existing safe browser action.
- `Panel.qml` keeps `detailOpen` and `detailGame` local, bounds the detail height,
  exposes Back as the first keyboard target and the provider source as the second
  when available, and routes Escape/Back to detail close before panel close.
  Closing the panel clears the local detail state; scores, standings, settings,
  polling, and provider fetch routes remain unchanged.
- `fixtures/game-detail-route/route.json`, the accessibility-action fixture, and
  the JavaScript suite cover row/action reachability, sparse placeholders, source
  preservation, and safe back/close routing. The complete suite passes with 168
  deterministic tests.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0.r20 were rechecked. The linked
  plugin passed validation and rescan; the shell was restarted once to load the
  current checkout, remained a single Quickshell instance, and shell ping
  returned `ok`. On actual Omarchy, keyboard Down/Return opened the rendered
  `Game details` view for an ESPN game, showing both teams, scores, final status,
  timing, venue, and source; Escape returned safely to the scores route. The
  fresh log contained normal polling/fetch activity and no Sportray error,
  exception, or binding-loop warning.
- The real import-path `qmllint` command over every QML file exits 0 with the
  established standalone import/unqualified-access warnings. `git diff --check`
  and `omarchy plugin validate "$PWD"` pass.

Decision log: the first drill-down is a presentation-only projection of the
scoreboard snapshot. Keep the source action nested and provider-safe, do not
fetch a second detail endpoint, and do not expose box-score, play-by-play, or
provider-specific fields. NHL remains eligible for the same sparse projection
when a normalized game is already loaded, but no NHL detail adapter was added.
The intentionally absent `docs/upstream-contract.md` was checked against the
installed Omarchy/Quickshell sources; the current `Panel`, `KeyboardPanel`, and
`PanelKeyCatcher` contract was preserved.

Known risks: ESPN remains an undocumented site API, and the projection can only
show fields present in the existing scoreboard payload. Null-heavy games are
intentionally shallow and neutral rather than implying richer detail. No new
provider contract was required for this unit.

## Latest handoff — 2026-08-23 game-detail drill-down UI complete

The existing-route game-detail UI slice is complete and ready for its atomic
commit. Valid loaded game rows now open a local, keyboard-accessible detail
presentation backed by `GameDetailModel`; whole-row activation no longer opens
the provider directly, while the nested ESPN/NHL.com source action remains
unchanged and guarded. The detail route renders identity, ordered participants,
nullable scores, status/timing, venue, source metadata/action, and neutral
placeholders, with Back and Escape returning to the scores route before panel
close.

The fixture/source-driven suite passes with 168 tests. Omarchy validation,
real-import-path QML lint, and diff check pass. Actual Omarchy 4.0.0-1 with
Quickshell 0.3.0.r20 was restarted once to load the linked checkout, rescanned,
manually exercised through keyboard Down/Return and Escape, and inspected with
one running shell and a clean fresh log. The final source contains no temporary
runtime probes. No new endpoint, provider adapter, league, box score,
play-by-play, alert, bar mode, packaging, release, tag, push, or Marketplace
action occurred.

Next bounded unit: implement one fixture-driven compact/full ambient bar
presentation policy for the existing normalized game state, preserving today
focus and the current bar priority/polling boundaries. Start with the pure
policy/model and one existing bar consumer only; do not add live rotation,
countdown requests, new provider fields, new leagues, or publication work.

## Ambient bar presentation policy slice — 2026-08-24

Status: complete. The bounded ambient presentation unit adds automatic compact
and full modes for the existing normalized bar state and keeps all selection,
date, polling, provider, favorites, and notification ownership unchanged.

Evidence:

- `model/BarPresentation.js` is a provider-neutral policy with explicit
  `compact` and `full` modes, 32-character full labels, 64-character tooltips,
  neutral loading/empty/offline fallbacks, and the existing
  `FavoritePresentation.selectBarState` priority when a pure model caller does
  not already provide the selected state.
- `fixtures/bar-presentation/policy.json` drives mode selection, long-label,
  fallback, and live-favorite priority cases. The deterministic suite passes
  with 172 tests.
- `BarWidget.qml` is the only consumer changed: the installed host's
  `vertical` boundary selects compact icon-only `BarIconButton` rendering for
  left/right bars and full bounded `WidgetButton` text for top/bottom bars.
  The panel still supplies the existing `barState`, `barScoreText`,
  `barTooltipText`, and live-favorite signal, so today focus and current
  priority/polling boundaries remain owned by the existing panel/service path.
  The popup anchor follows whichever mode is visible.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision `28771c7` were
  inspected before the QML change. Their `BarWidget.vertical`, `WidgetButton`,
  `BarIconButton`, and `ModuleSlot` contracts support this presentation without
  an upstream API extension. The intentionally absent
  `docs/upstream-contract.md` required no replacement repository document.
- `omarchy plugin validate "$PWD"`, real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file,
  `tests/run-js-tests.sh`, and `git diff --check` pass. The linked plugin was
  rescanned in actual Omarchy with exactly one Quickshell instance. The
  horizontal/top full route and a temporary left/vertical compact route were
  manually opened/rendered; the user bar position was restored to `top`.
  The fresh log has normal Sportray fetch activity and no Sportray exception,
  QML load failure, or binding-loop warning.

Decision log: mode selection is derived from the installed bar orientation,
not a new settings field. QML-imported JavaScript cannot rely on Node's
`require`, so the consumer passes the already normalized and formatted panel
projection into the policy; Node tests still load the existing pure formatter
and favorite helpers for fixture coverage. No provider response, endpoint,
timer, rotation, countdown, alert, league, or settings schema changed.

Known risk: full mode consumes horizontal bar width according to its bounded
32-character label and the host's `WidgetButton` padding. If a future shell
changes that width contract, stop before adding a custom upstream-dependent
layout and preserve the compact icon fallback.

## Latest handoff — 2026-08-24 ambient bar presentation policy complete

The compact/full ambient bar presentation unit is complete and ready for its
atomic commit. `BarPresentation.js` and its fixture select full bounded score
text on horizontal bars and compact icon-only presentation on vertical bars.
`BarWidget.qml` alone consumes the policy, while the existing panel continues
to own normalized today-scoped state, favorite-first priority, formatting
projection, polling, and the popup anchor contract.

The fixture-driven suite passes with 172 tests. Actual Omarchy 4.0.0-1 with
Quickshell 0.3.0 revision `28771c7` rescanned the linked checkout in one
running shell; top/full and temporary left/compact bar routes were opened and
rendered, the bar was restored to `top`, and the fresh log had no Sportray
exception, QML load failure, or binding-loop warning. Plugin validation, real
import-path QML lint, and diff check pass. No upstream boundary deviation,
provider field, endpoint, polling change, live rotation, countdown, alert,
league, settings schema, package, tag, push, release, or Marketplace action
occurred.

Next bounded unit: add a pure fixture-driven live-favorite rotation/cadence
policy for the already normalized today-scoped ambient state. Keep it separate
from timers, provider polling, countdown requests, settings, and QML until the
selection/cadence contract is accepted. Start by rereading `AGENTS.md`,
`README.md`, the intentionally absent `docs/upstream-contract.md`,
`roadmap.md`, this handoff, the installed bar sources, and the current
`BarPresentation.js`/`FavoritePresentation.js` tests. Require a roadmap and
handoff update, refreshed next-session prompt, all repository gates, and one
atomic Conventional Commit-style commit when the pure unit passes; stop if
rotation would require an upstream shell contract or new provider data.

## Live-favorite rotation/cadence policy slice — 2026-08-24

Status: complete. The bounded pure policy describes caller-controlled rotation
among already normalized, today-scoped live favorite games without taking
ownership of time, polling, provider parsing, settings, or QML.

Evidence:

- `model/LiveFavoriteRotationPolicy.js` validates the selected/today date
  identity, accepts only normalized live or intermission favorite games whose
  local date is today, orders them by start time and canonical game identity,
  caps the rotation list at four items, clamps caller cadence to 5 seconds–5
  minutes, and returns a bounded index plus the next transition timestamp.
- `fixtures/bar-presentation/live-favorite-rotation.json` and four deterministic
  tests cover chronological/tie ordering, stable results when input order
  changes, today-scope rejection, empty and offline states, cadence clamping,
  and the rotation-list/index bounds. The suite passes with 176 tests.
- No QML, service, provider, endpoint, settings, polling, timer, countdown, or
  bar consumer changed. The policy is available for a later caller only after
  this selection/cadence contract is accepted.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision `28771c7` were
  inspected first. The existing `BarWidget`, `WidgetButton`, `BarIconButton`,
  and panel contracts provide no required rotation API; no upstream boundary
  deviation was needed. The intentionally absent `docs/upstream-contract.md`
  remains absent.
- `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file,
  and `git diff --check` pass. Lint retains the repository's established
  standalone import and unqualified-access warnings.

Decision log: use the normalized game's canonical ID and local `todayDateKey`
as the stable selection boundary. The policy uses a deterministic day-start
cadence slot supplied with `nowMs`; it never starts a timer or derives a fetch
cadence from a provider. Four items is the hard product-neutral rotation cap,
and invalid or non-today input fails closed to a bounded result. Offline state
is explicit when the caller reports it or has an unavailable error without
data; stale data with an explicit healthy snapshot remains the caller's
responsibility.

Known risks: local date conversion must stay aligned with the existing
`DateModel` boundary when a future QML consumer passes timestamps. A later
consumer must preserve today scope, pass the existing normalized games, and
own timer scheduling separately; this unit does not verify live runtime
rotation because it intentionally has no consumer.

## Latest handoff — 2026-08-24 live-favorite rotation/cadence policy complete

The pure live-favorite rotation/cadence unit is complete. The new policy and
sanitized fixture select at most four normalized today-scoped live favorite
games in deterministic order, derive a bounded cadence index from caller
`nowMs` and cadence inputs, and fail closed for non-today, empty, or offline
state. Four tests cover ordering, stable today identity, empty/offline
behavior, cadence clamping, and list/index bounds.

The fixture-driven suite passes with 176 tests. Plugin validation, full
real-import-path QML lint, and diff check pass. Installed Omarchy 4.0.0-1 and
Quickshell revision `28771c7` were inspected before implementation; no
upstream API, provider field, endpoint, polling boundary, timer, countdown,
settings schema, QML consumer, package, tag, push, release, or Marketplace
action changed. Actual Omarchy runtime rotation remains intentionally
unexercised because this unit has no consumer; the existing bar behavior is
unchanged.

Next bounded unit: add one pure fixture-driven countdown projection policy for
already normalized today-scoped favorite upcoming games. Keep it separate from
timers, polling, provider countdown fields/endpoints, settings, and QML; use
caller-supplied time and preserve the current bar/panel behavior until the
projection contract is accepted. Stop if countdown semantics require provider
data or an upstream shell API.

## Countdown projection policy slice — 2026-08-24

Status: complete. The bounded pure policy projects a caller-selected,
already-normalized, today-scoped favorite scheduled game into a countdown
state without taking ownership of game selection, time, refresh cadence,
provider parsing, polling, timers, or QML.

Evidence:

- `model/CountdownProjectionPolicy.js` validates the local `todayDateKey` and
  `selectedDateKey` identity, canonical favorite membership, scheduled state,
  local start-date scope, and caller-supplied finite `nowMs`/`startTimeMs`
  inputs. It returns `future`, `due`, `invalid`, `empty`, `offline`, or
  `not-today` with preserved date identity, bounded `remainingMs`, and a
  bounded label no longer than 24 characters.
- `fixtures/bar-presentation/countdown.json` contains sanitized normalized-game
  inputs for future, due, invalid-start, non-favorite, empty, and unavailable
  states. Four deterministic tests cover the state projection, local today
  identity, explicit time inputs, and caller-visible text bounds. The complete
  JavaScript suite passes with 180 tests.
- `omarchy plugin validate "$PWD"` passes. The real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
  file exits 0 with the established standalone import and unqualified-access
  warnings. `git diff --check` passes.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision `28771c7` were
  inspected before implementation. The existing bar, panel, and polling
  contracts expose no countdown API or provider timing requirement, so no
  upstream boundary deviation was needed. No QML, service, provider,
  endpoint, settings, polling, timer, or bar-consumer behavior changed.

Decision log: keep countdown projection separate from the existing
`FavoritePresentation.selectBarState` selection boundary. A future caller
must pass the selected normalized favorite game and own any reevaluation
schedule; this policy never calls `Date.now()`. Use local `Date` conversion for
the existing today identity, treat a scheduled game whose start is at or before
`nowMs` as `due`, and fail closed for invalid or non-today input. Static labels
remain provider-neutral and are capped through the same whitespace-trimming
ellipsis convention used by existing presentation policies.

Known risks: a future consumer must reevaluate with a current caller-supplied
time or its label will age between refreshes; this unit intentionally adds no
timer or runtime consumer. The consumer must use the same local timezone
boundary as `DateModel` when passing timestamps. The policy cannot distinguish a
provider status correction from a due scheduled snapshot and must continue to
trust the normalized caller state.

## Latest handoff — 2026-08-24 countdown projection policy complete

The pure countdown projection unit is complete and ready for its atomic commit.
`CountdownProjectionPolicy.js` accepts one already normalized scheduled game,
canonical favorite IDs, local today/selected date keys, and caller-supplied
`nowMs` plus optional `startTimeMs`. It returns bounded `future` or `due`
projection text, or safe `invalid`, `empty`, `offline`, and `not-today` states;
all results preserve the supplied local date identity. It does not select among
games, start a timer, poll, request provider data, add provider fields, or run
inside QML.

The sanitized fixture and four tests cover future, due, invalid-start,
non-favorite/non-today, empty/offline, supplied timestamp, and bounded-text
behavior. The complete JavaScript suite passes with 180 tests. Plugin
validation, full real-import-path QML lint, and diff check pass. Installed
Omarchy 4.0.0-1 and Quickshell revision `28771c7` were inspected first; the
checkout intentionally has no `docs/upstream-contract.md`, and no upstream
boundary change was needed. No QML or service changed, so no new shell rescan,
runtime route exercise, or fresh Quickshell log claim was made.

No push, tag, release, or Marketplace action occurred. Known risks are caller
time freshness, local-timezone alignment with `DateModel`, sparse normalized
start times, and the absence of a runtime consumer. Preserve the current
bar/panel behavior until a later consumer unit owns reevaluation explicitly.

Next bounded unit: wire the accepted countdown projection into one existing
ambient-bar presentation path using the already normalized today-scoped
favorite-upcoming state and caller-owned time, while preserving live-favorite
priority, compact/full mode selection, and current polling boundaries. Stop
before adding a new timer, provider countdown data or endpoint, settings field,
new league, or unrelated QML interaction work.

## Ambient-bar countdown presentation slice — 2026-08-24

Status: complete. The accepted pure countdown projection is wired into the
existing ambient bar presentation path for one normalized today-scoped
favorite-upcoming game. Live-favorite priority, compact/full mode selection,
panel anchoring, and polling ownership remain unchanged.

Evidence:

- `BarWidget.qml` now passes the existing normalized `barState.game` to
  `CountdownProjectionPolicy.project` only when the selected state is
  `favorite-upcoming`. It supplies the panel's selected date, the shared
  service's caller-owned `nowMs`, favorite IDs, normalized-data health, and
  the existing fetch error state. No provider payload or provider parser is
  imported into QML.
- The shared `SportrayService` clock reuses its existing 60-second date-boundary
  timer to publish the current timestamp and local today key. No countdown
  timer, request, polling cadence, settings field, or upstream API was added.
  `Panel.qml` exposes that caller-owned time/date context only to the existing
  ambient-bar path.
- `model/BarPresentation.js` preserves the selected state and mode, exposes the
  bounded countdown projection, and overrides the existing full/tooltip text
  only for valid `future` or `due` `favorite-upcoming` projections. Safe empty
  and offline projections retain the existing matchup/fallback text.
- `fixtures/bar-presentation/policy.json` and the deterministic suite cover
  countdown precedence, future/due labels, compact/full behavior, safe
  empty/offline fallbacks, live-favorite precedence, caller-time wiring, and
  the no-new-timer ownership boundary. The complete suite passes with 182
  deterministic tests.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision `28771c7` were
  inspected before the QML change. The existing `BarWidget`, `WidgetButton`,
  `BarIconButton`, `ModuleSlot`, and shell service contracts were sufficient;
  no upstream boundary deviation was needed. The intentionally absent
  `docs/upstream-contract.md` remains absent.
- `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command
  over every QML file, and `git diff --check` pass. The linked checkout was
  rescanned on actual Omarchy with one running shell; the existing bar IPC
  toggle/hide route completed and the fresh log had normal Sportray polling
  activity with no Sportray exception, QML load failure, binding-loop, or
  countdown-related error.

Decision log: use the already-running singleton service clock as the caller
owned ambient timestamp. Its existing minute timer already maintains the local
day boundary, so the consumer does not create a new timer or make a data
request. Keep `favorite-upcoming` as the only countdown presentation state so
the higher-priority live-favorite and starting-soon behavior remains intact;
safe policy states remain observable in the presentation result but do not
replace established bar text.

Known risks: the ambient label updates at the existing service clock's
minute-level cadence, and the normalized scheduled snapshot can change before
the next provider refresh. The countdown still intentionally depends only on
the normalized start time and local date boundary; no provider timing field or
new endpoint is implied. A later rotation consumer must establish its own
caller-owned reevaluation cadence without changing this unit's boundaries.

## Latest handoff — 2026-08-24 ambient-bar countdown presentation complete

The accepted countdown projection is now wired through `BarWidget.qml` into
`BarPresentation.js` for the existing ambient path. A normalized game is
eligible only when `FavoritePresentation` selected `favorite-upcoming` for the
current local today; valid `future`/`due` projections replace the horizontal
full label and tooltip with bounded countdown text, while compact mode remains
icon-only and live-favorite priority remains unchanged. Empty, offline,
invalid, and non-today projections fail closed to the existing presentation.

The caller-owned timestamp comes from the already-running singleton service
clock, whose existing minute timer now publishes `nowMs` alongside the local
today key. No new timer, provider field/endpoint, polling cadence, settings
field, or upstream API was introduced. Installed Omarchy 4.0.0-1 and
Quickshell `28771c7` were inspected first; the existing bar and service
contracts were sufficient. The checkout intentionally has no
`docs/upstream-contract.md`.

The fixture-driven JS suite passes with 182 tests. Plugin validation, full
real-import-path QML lint, and diff check pass. Actual Omarchy has one running
shell; the linked checkout rescanned, the bar IPC toggle/hide route completed,
and the fresh log contains no Sportray exception, QML load failure,
binding-loop, or countdown-related error. No push, tag, release, Marketplace,
or remote action occurred.

Next bounded unit: wire the accepted pure live-favorite rotation/cadence policy
into one existing ambient-bar presentation path using already normalized
today-scoped state and caller-owned reevaluation time. Preserve the current
countdown precedence, live-favorite semantics, compact/full mode selection,
panel anchor, and polling ownership; stop before adding a second timer,
provider data, settings, or a new upstream API.

## Ambient-bar live-favorite rotation presentation slice — 2026-08-24

Status: complete. The accepted pure live-favorite rotation/cadence policy is
now wired into the existing ambient-bar state path for normalized today-scoped
games. The caller uses the singleton service timestamp and its existing
minute-level publication cadence; no new timer or polling owner was added.

Evidence:

- `Panel.qml` retains `unrotatedBarState` from the existing
  `FavoritePresentation.selectBarState` boundary, passes normalized games,
  canonical favorites, local today/selected date keys, normalized-data health,
  the existing fetch error, caller-owned `ambientNowMs`, and a one-minute
  presentation cadence to `LiveFavoriteRotationPolicy.select`, then applies
  the result through `BarPresentation.applyLiveFavoriteRotation`.
- Rotation applies only to the existing `live-favorite-count` state and
  returns one bounded `live-favorite` game while preserving the original
  count. `favorite-upcoming` remains available to the existing countdown
  projection, starting-soon/neutral/final behavior remains unchanged, and the
  existing compact/full buttons, panel anchor, and polling models remain
  untouched.
- `fixtures/bar-presentation/policy.json` and two fixture-driven tests cover
  multi-live precedence, protection of countdown and single-live states, and
  safe empty/offline/non-today policy fallbacks. The complete deterministic
  JavaScript suite passes with 184 tests.
- The installed Omarchy 4.0.0-1 / Quickshell 0.3.0 revision `28771c7` bar,
  button, module-slot, service-clock, and shared polling contracts were
  inspected before the edit. The linked checkout rescanned on actual Omarchy;
  the existing bar toggle/hide route completed with one shell still running,
  and the fresh log had no Sportray exception, QML load failure, binding loop,
  or rotation-related error. The intentionally absent
  `docs/upstream-contract.md` remains absent.
- `tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, the real
  import-path `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command
  over every QML file, and `git diff --check` pass. Lint retains the
  repository's established standalone import and unqualified-access warnings.

Decision log: keep rotation as a presentation projection after the existing
favorite-priority selection. Only the multi-live favorite count is replaced by
the policy's selected normalized game; all other states are passed through so
countdown precedence and current bar semantics remain explicit. Use the
already-running singleton `nowMs` publication and a caller-supplied 60-second
rotation cadence, which is sufficient for reliable bounded rotation without a
second timer. The cadence is presentation-only and is not exposed as a setting
or used to schedule provider work.

Known risks: the visible rotation advances at the existing minute-level clock
publication, so it intentionally does not promise sub-minute transitions. A
future requirement for a faster or independently scheduled rotation must stop
before adding a timer contract or borrowing a new polling cadence. Local date
conversion must remain aligned with `DateModel`, and stale normalized data with
an explicit healthy snapshot remains the caller's responsibility as defined by
the pure policy.

## Latest handoff — 2026-08-24 ambient-bar live-favorite rotation presentation complete

The accepted live-favorite rotation policy is integrated in the existing
ambient-bar path. `Panel.qml` keeps the prior favorite-first selection, invokes
the pure policy only with normalized today-scoped state and caller-owned time/
cadence inputs, and applies the selected game only when the prior state was
`live-favorite-count`. Empty, offline, and non-today policy results fail closed
to the prior state. The bar's countdown projection therefore still owns
`favorite-upcoming`, while compact/full presentation, panel anchoring, and
polling ownership remain unchanged.

The one-minute cadence reuses the already-running singleton service clock; no
second timer, provider field/endpoint, polling cadence, settings field, or
upstream API was introduced. Installed Omarchy 4.0.0-1 and Quickshell
`28771c7` were inspected first. The linked checkout rescanned, toggle/hide
IPC completed, one shell remained running, and the fresh log was clean.

The fixture-driven suite passes with 184 tests. Plugin validation, full
real-import-path QML lint, and diff check pass. No push, tag, release,
Marketplace, or remote action occurred.

Next bounded unit: add one fixture-driven ambient priority transition matrix
covering a minute-slot rotation, live-state removal, and reclamation of the
existing favorite-upcoming countdown. Keep the implementation pure/model-level
unless a test demonstrates a real presentation defect; do not add a timer,
provider data, settings, polling cadence, or upstream API.

## Ambient-bar priority transition coverage — 2026-08-24

Status: complete. The already wired live-favorite rotation path now has a
fixture-driven transition matrix covering caller-cadence advancement, removal
of all live favorites, and countdown/neutral precedence recovery. Production
behavior remains unchanged.

Evidence:

- `fixtures/bar-presentation/live-favorite-rotation.json` adds sanitized
  normalized-boundary inputs for the 60-second slot transition, a scheduled
  favorite after live-state removal, and a non-favorite scheduled neutral
  fallback.
- `tests/run-js-tests.js` recomputes the existing
  `FavoritePresentation.selectBarState` → `LiveFavoriteRotationPolicy.select`
  → `BarPresentation.applyLiveFavoriteRotation` path for each state. The
  caller `nowMs` boundary advances the selected game from `nhl:104` to
  `nhl:103`; an empty rotation result preserves `favorite-upcoming` or
  `neutral`; and `CountdownProjectionPolicy.project` returns the expected
  `favorite-upcoming` future projection after the normalized live-to-scheduled
  change.
- The complete deterministic suite passes with 185 tests. `git diff --check`,
  `omarchy plugin validate "$PWD"`, and the real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
  file pass with the established standalone import and unqualified-access
  warnings.
- Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision `28771c7` were
  rechecked; the current checkout is linked into the plugin path. A rescan,
  explicit enable, and the existing toggle/hide IPC exercise completed with
  one running shell. The fresh log contains normal Sportray polling and no
  Sportray exception, QML load failure, binding loop, or rotation error.
  After the asynchronous rescan, the host also logged the existing
  `summon: no live bar widget for: io.github.joega.sportray` warning, so no
  visual bar-route claim is made for this run. The warning is outside the
  changed pure-model/test path and did not expose a new timer, provider,
  settings, polling, or upstream API requirement.
- The intentionally absent `docs/upstream-contract.md` remains absent; no
  upstream boundary deviation was introduced.

Decision log: keep transition assertions at the normalized model boundary.
The test must reselect the bar state for every fixture snapshot so it proves
that rotation is only a projection of `live-favorite-count`, while removal
returns control to the existing favorite-upcoming/neutral selector and
countdown policy. Do not add a runtime timer or make test fixtures resemble
raw provider payloads.

Known risks: the installed host's post-rescan `summon: no live bar widget`
warning remains to be reconciled in a future runtime-focused unit; the fresh
log otherwise stayed clean. Rotation intentionally remains minute-cadenced,
and local date conversion plus stale healthy snapshots remain caller-owned.

## Latest handoff — 2026-08-24 ambient-bar priority transition coverage

The ambient priority transition unit is complete in `/home/joeg/Projects/sportray`.
The new sanitized fixture matrix and one deterministic pipeline test cover the
caller cadence boundary (`nhl:104` → `nhl:103`), live-favorite removal back to
the existing scheduled-favorite or neutral selection, and countdown projection
reclamation after the normalized state becomes scheduled. No production,
QML, provider, timer, setting, polling, or upstream API code changed.

The complete suite passes with 185 tests. Plugin validation, full real-import-
path QML lint, and `git diff --check` pass. Installed Omarchy 4.0.0-1 with
Quickshell `28771c7` was rechecked; one shell remained running, the linked
checkout rescanned, and toggle/hide IPC was exercised. The fresh log has no
Sportray exception, QML load failure, binding loop, or rotation error, but it
does contain the host warning `summon: no live bar widget for:
io.github.joega.sportray` after rescan, so no visual route success is claimed.
No push, tag, release, Marketplace, or remote action occurred.

Next bounded unit: diagnose and reconcile the installed Omarchy post-rescan
`summon: no live bar widget` warning for the linked Sportray bar-widget route.
Read `AGENTS.md`, `README.md`, the intentionally absent
`docs/upstream-contract.md`, `roadmap.md`, and this handoff first; inspect the
installed Omarchy/Quickshell widget registry, bar-slot, rescan, and IPC source
before any edit. Keep Sportray production behavior unchanged unless the
diagnosis proves a concrete checkout defect. Stop if reliable registration
requires a new upstream API, plugin kind, timer, provider data, setting, or
polling contract; document the risk and leave the runtime path intact. On
success, rerun the complete JS suite, plugin validation, real-import-path QML
lint over every QML file, and diff check; on actual Omarchy rescan, wait for
asynchronous registration, exercise toggle/hide, inspect a fresh log, and
confirm one shell. Update this roadmap and the next-session prompt, then make
one atomic Conventional Commit-style commit only if a bounded fix and every
gate pass. Request subagents only for independent read-only upstream/runtime
reconnaissance.

## Latest handoff — 2026-08-24 post-rescan summon lifecycle diagnosis

Status: blocked by the installed Omarchy shell's asynchronous widget
registration window. No Sportray source or production behavior changed, and no
success commit was created.

The installed Omarchy 4.0.0-1 / Quickshell `28771c7` sources prove the warning
is emitted by the host, not by a Sportray manifest or entry-point rejection:

- `PluginRegistry.validateManifest()` accepts the linked manifest, and
  `entryPointUrl(manifest, "barWidget")` resolves the relative
  `BarWidget.qml` entry point. The installed `omarchy plugin validate "$PWD"`
  also passes. The source and linked manifests are byte-for-byte identical.
- `shell.reloadPlugins()` first unloads the widget registry. After the scan,
  `syncPluginWidgets()` calls `Qt.createComponent(url, Component.Asynchronous)`
  and only registers the component in `BarWidgetRegistry` from the component's
  `statusChanged` callback once it reaches `Ready`.
- The bar's `ModuleSlot` reads the registry component and exposes a live
  `activeItem` only after that registration and Loader creation. The shell's
  `summon()` path immediately calls `Bar.summonBarWidget()`, which searches
  only those already-live `ModuleSlot.activeItem` objects and warns when none
  exists. It has no registration-ready queue or retry boundary.

Runtime reproduction on actual Omarchy used one shell (PID 761056, Quickshell
instance `g8bgirc9kt`) and the linked checkout at
`/home/joeg/.config/omarchy/plugins/io.github.joega.sportray`:

- Immediately after `omarchy-shell shell rescanPlugins`,
  `omarchy-shell shell summon io.github.joega.sportray '{}'` returned
  `unknown` and logged `summon: no live bar widget for:
  io.github.joega.sportray`.
- After two seconds for asynchronous registration, `listPlugins` still showed
  the enabled third-party `bar-widget`; `debugBarGeometry` showed a visible
  Sportray slot in `right` at 133x26; the same summon returned `ok`.
- A delayed hide completed successfully. The fresh log slice contained only
  the transient host warning and no Sportray exception, QML load failure,
  binding-loop warning, or provider/rotation error.

All repository gates pass without source changes: `tests/run-js-tests.sh`
passes with 185 tests, `omarchy plugin validate "$PWD"` passes, the real
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
file exits 0 with the established warnings, and `git diff --check` passes.

Decision log: preserve the current bar-widget route. Adding a plugin-side
delay, timer, second IPC route, or readiness workaround would mask a host
lifecycle gap and violate this unit's stop condition; Sportray has no
registration-ready API to consume. The safe resolution is for the installed
shell/upstream IPC path to queue or retry bar-widget summons until asynchronous
registration settles. Revisit only after an installed Omarchy/Quickshell change
or an explicit upstream contract that exposes such readiness.

Known risk: callers that summon immediately after a rescan can receive a
transient `unknown` even though the widget becomes live moments later. Normal
post-start and post-settlement toggle/hide behavior is healthy. The checkout
intentionally still has no `docs/upstream-contract.md`; installed sources are
the boundary evidence.

Next bounded unit: recheck this host-registration blocker after an installed
Omarchy/Quickshell update or an explicit upstream readiness/queue fix. Do not
add a plugin-side timer, retry loop, new IPC route, provider field, setting, or
polling contract. If the installed host is unchanged, stop after recording the
same external blocker and leave production code untouched.

## Latest handoff — 2026-08-24 post-rescan blocker recheck

Status: blocked by the unchanged installed Omarchy shell contract. No Sportray
source or production behavior changed, and no success commit was created.

The installed environment remains Omarchy `4.0.0-1` with Quickshell `0.3.0`
revision `28771c7c74b42e20afca0b1b63980cb46515537c`. The inspected
`PluginRegistry.qml`, `shell.qml`, `BarWidgetRegistry.qml`, and bar
`ModuleSlot`/summon sources are unchanged: rescan unloads widget registrations,
`syncPluginWidgets()` creates entry-point components asynchronously, and the
registry only receives a component after `Component.Ready`; `summonBarWidget()`
still searches only live slot items and has no readiness queue or retry.

Runtime recheck used the one running shell, Quickshell instance `g8bgirc9kt`
(PID 761056), and the linked checkout at
`/home/joeg/.config/omarchy/plugins/io.github.joega.sportray`:

- `rescanPlugins` completed, and this run's immediate summon returned `ok`.
- After a two-second settlement wait, `listPlugins` still showed the enabled
  Sportray `bar-widget`; `debugBarGeometry` showed a visible right-section
  Sportray slot at 133x26. A delayed summon returned `ok` and delayed hide
  completed.
- The retained fresh log slice still contains the earlier host warning
  `summon: no live bar widget for: io.github.joega.sportray`, but no new warning
  appeared for this recheck and there is no Sportray exception, QML load
  failure, binding-loop warning, or rotation error. The successful immediate
  summon is timing-sensitive evidence, not proof that the host lifecycle gap
  is resolved; the installed source still has no readiness contract.

All repository gates pass: `tests/run-js-tests.sh` passes with 185 tests,
`omarchy plugin validate "$PWD"` passes, the real import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
file exits 0 with the established warnings, and `git diff --check` passes.
The linked manifest remains valid and unchanged; the checkout still
intentionally has no `docs/upstream-contract.md`.

Decision log: preserve the current bar-widget route and do not add a
plugin-side delay, timer, retry loop, second IPC route, provider field, setting,
polling cadence, or new upstream API. Reliable immediate post-rescan summon
requires an upstream queue/retry or readiness boundary, which this host does
not expose. Revisit only after an installed Omarchy/Quickshell update or an
explicit upstream readiness/queue fix.

Known risk: immediate callers after a rescan may still receive a transient
`unknown` even though the widget becomes live moments later. Normal
post-start and post-settlement toggle/hide behavior is healthy. No production
source change is justified by this recheck.

Next bounded unit: recheck this host-registration blocker only after an
installed Omarchy/Quickshell update or explicit upstream readiness/queue fix.
If the host is unchanged, reproduce the sequence, record the evidence, and
stop without changing Sportray or creating a success commit.

## Latest handoff — 2026-08-24 post-rescan blocker recheck (reproduced)

Status: blocked by the unchanged installed Omarchy shell contract. No Sportray
source or production behavior changed, and no success commit was created.

The installed environment remains Omarchy `4.0.0-1` with Quickshell `0.3.0`
revision `28771c7c74b42e20afca0b1b63980cb46515537c`. The re-inspected
`PluginRegistry.qml`, `shell.qml`, `BarWidgetRegistry.qml`, and bar
`ModuleSlot`/summon sources are unchanged: rescan unloads widget registrations,
`syncPluginWidgets()` creates entry-point components asynchronously, and the
registry receives a component only after `Component.Ready`; `summonBarWidget()`
still searches only live slot items and has no readiness queue or retry.

The linked `manifest.json` remains byte-for-byte identical to the installed
manifest, `BarWidget.qml` is unchanged, and `omarchy plugin validate "$PWD"`
accepts the checkout. The intentionally absent `docs/upstream-contract.md`
remains absent.

Runtime recheck used one running shell, Quickshell instance `g8bgirc9kt` (PID
761056), and the linked checkout at
`/home/joeg/.config/omarchy/plugins/io.github.joega.sportray`:

- `omarchy-shell shell rescanPlugins` followed immediately by
  `omarchy-shell shell summon io.github.joega.sportray '{}'` returned
  `unknown`.
- After a two-second settlement wait, `listPlugins` still showed the enabled
  third-party Sportray `bar-widget`; `debugBarGeometry` showed a visible
  right-section slot at 133x26; delayed summon returned `ok`, and delayed hide
  completed successfully.
- The fresh Quickshell log contains the corresponding host warning
  `summon: no live bar widget for: io.github.joega.sportray` and normal
  Sportray polling/cache activity, but no Sportray exception, QML load
  failure, binding-loop warning, or rotation error. The successful delayed
  route confirms asynchronous registration, not reliable immediate summon.

The complete deterministic suite passes with 185 tests. `omarchy plugin
validate "$PWD"`, the real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
file, and `git diff --check` all pass with the established lint warnings.

Decision log: preserve the current native `bar-widget` route. Reliable
immediate post-rescan summon still requires an upstream queue/retry or
readiness boundary; adding a plugin-side timer, retry loop, second IPC route,
provider field, setting, polling cadence, or new API would violate the bounded
unit and mask the host defect. Revisit only after an installed Omarchy/
Quickshell update or an explicit upstream readiness/queue fix.

Known risk: callers that summon immediately after a rescan may receive a
transient `unknown` even though the widget becomes live moments later. Normal
post-start and post-settlement toggle/hide behavior remains healthy. No
production source change is justified by this recheck.

Next bounded unit: recheck this host-registration blocker only after an
installed Omarchy/Quickshell update or explicit upstream readiness/queue fix.
If the installed host is unchanged, reproduce the immediate and delayed
sequence, update this handoff and `NEXT_SESSION_PROMPT.md`, and stop without
changing Sportray or creating a success commit.

## Latest handoff — 2026-08-24 installed-host-gated blocker recheck

Status: blocked by the unchanged installed Omarchy shell contract. No Sportray
source or production behavior changed, and no success commit was created.

The prerequisite for reopening this unit was not met. Installed packages remain
Omarchy `4.0.0-1` (installed 2026-08-15) and Quickshell `0.3.0`, revision
`28771c7c74b42e20afca0b1b63980cb46515537c` (installed 2026-08-23). The current
host sources still show asynchronous `Qt.createComponent(...,
Component.Asynchronous)` loading, registry insertion only after
`Component.Ready`, and `summonBarWidget()` searching live bar-slot items
without a readiness queue or retry. No explicit upstream readiness/queue fix
is present. The checkout still intentionally has no `docs/upstream-contract.md`;
installed sources remain the boundary evidence.

The linked checkout remains
`/home/joeg/.config/omarchy/plugins/io.github.joega.sportray`, with repository
and installed `manifest.json` plus `BarWidget.qml` hashes matching. The host
reported one running Quickshell shell, instance `g8bgirc9kt` (PID 761056), and
`listPlugins` showed enabled Sportray as a native third-party `bar-widget`.

Fresh actual-Omarchy reproduction:

- `omarchy-shell shell rescanPlugins` completed successfully.
- The immediate summon and hide both returned success in this run.
- After a two-second asynchronous-registration wait, `debugBarGeometry` showed
  Sportray visible in the right section at `133x26`; delayed summon and hide
  both returned success.
- The current log tail has no new summon warning from this run. It retains the
  earlier `summon: no live bar widget for: io.github.joega.sportray` evidence,
  with no Sportray exception, QML load failure, binding-loop warning, or
  rotation error. Immediate success is timing-sensitive and does not prove a
  host lifecycle fix; the source contract remains unchanged and the prior
  immediate `unknown` reproduction remains valid blocker evidence.

Decision log: keep the native `bar-widget` route unchanged. The successful
sample does not justify a plugin-side delay, timer, retry loop, second IPC
route, provider field, setting, polling cadence, or new API. Reliable
post-rescan summon still requires an upstream queue/retry or readiness
boundary. Revisit only after an installed Omarchy/Quickshell update or an
explicit upstream readiness/queue fix.

Known risk: an immediate caller after rescan may still receive a transient
`unknown` before the asynchronous component and bar slot become live. Normal
post-start and post-settlement summon/hide behavior is healthy. No production
source change is justified by this recheck.

Next bounded unit: recheck this host-registration blocker only after an
installed Omarchy/Quickshell update or explicit upstream readiness/queue fix.
If the installed host is unchanged, do not repeat this unit speculatively;
wait for the prerequisite, then reproduce immediate and delayed summon/hide,
update this handoff and `NEXT_SESSION_PROMPT.md`, and stop without changing
Sportray or creating a success commit.

## Latest handoff — 2026-08-24 client-side post-rescan summon mitigation

Status: complete as a bounded client-side mitigation. No Sportray production
QML, provider, polling, settings, or runtime IPC source changed.

Repository reconnaissance found no existing post-rescan Sportray summon
caller: the only repository and user-configured references were the README's
normal `toggle`/`hide` commands and no keybinding or helper that invokes
`summon`. The installed `omarchy-shell` returns IPC-level `unknown` results on
stdout with exit status 0, so a caller cannot use process status alone.

The external helper `scripts/summon-sportray-after-rescan.sh` is now the
documented client-side workaround. It sends exactly
`omarchy-shell shell summon io.github.joega.sportray '{}'`, accepts only stdout
`ok`, retries only after an unsuccessful result, waits 250 ms between attempts,
and stops after five total attempts with a concise nonzero error. It never
calls `rescanPlugins` or `hide`, so normal hide behavior remains unchanged. A
deterministic fake-IPC test covers success on the third attempt, exact summon
arguments, the five-attempt bound, concise failure, and the absence of a hide
call; `bash -n` passes. `shellcheck` is not installed on this environment.
README now documents the exact `rescanPlugins` followed by helper usage and
the helper's external, non-runtime boundary.

Repository evidence:

- `tests/test-summon-helper.sh` passes; `tests/run-js-tests.sh` passes with
  185 deterministic tests.
- `omarchy plugin validate "$PWD"` passes.
- `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
  exits 0 with the established standalone import/unqualified-access warnings.
- `git diff --check` passes.
- Only `README.md`, the external helper/test, `roadmap.md`, and
  `NEXT_SESSION_PROMPT.md` changed; no production QML, provider, polling,
  settings, or new IPC route was added.

Actual Omarchy evidence used one shell, Quickshell instance `g8bgirc9kt`
(PID 761056), and the linked checkout at
`/home/joeg/.config/omarchy/plugins/io.github.joega.sportray`. The installed
versions remain Omarchy `4.0.0-1` and Quickshell `0.3.0`, revision
`28771c7c74b42e20afca0b1b63980cb46515537c`; the host source still loads
widgets asynchronously and has no readiness queue or retry. Rescan returned
success, the helper returned `ok`, normal hide returned success, and after a
two-second settlement direct summon and hide both returned success. `listPlugins`
showed enabled Sportray as a native third-party `bar-widget`, and
`debugBarGeometry` showed a visible right-section slot at `133x26`. The fresh
log tail showed normal Sportray polling/cache activity and no Sportray
exception, QML load failure, binding-loop warning, or rotation error; the
known host `summon: no live bar widget` warning remains in the retained log
history as evidence of the race.

Decision log: because no existing caller was available to integrate, expose
the smallest repository-contained external helper and document its explicit
use. Keep the helper outside the manifest/runtime path; do not add a plugin
timer, new IPC route, host API, provider field, setting, or polling behavior.
An upstream queue/readiness fix remains the correct long-term resolution.

Remaining risk: a caller must opt into the helper after rescan, and five
attempts over roughly one second may still be shorter than an unusually slow
host registration. The installed host contract remains unchanged, so callers
that continue to issue a single immediate summon can still receive transient
`unknown`.

Next bounded unit: revisit the helper only after a concrete existing client
caller is introduced or an installed Omarchy/Quickshell update changes the
registration/readiness contract. Do not broaden into plugin runtime changes,
providers, polling, settings, or new IPC. No remote state was changed.

## Icon-only ambient tray presentation slice — 2026-08-24

Status: complete. The ambient tray no longer replaces the sport icon with a
close countdown such as `Starts in 8h 49m`. Horizontal and vertical bar paths
now use the installed `BarIconButton` contract; a small accent dot marks an
upcoming favorite and an urgent dot marks a live favorite. Existing score/start
details remain available through the host tooltip and panel.

Evidence:

- `model/BarPresentation.js` keeps the accepted normalized countdown projection
  available in its result for compatibility, but no longer promotes its label
  into the tray label or tooltip. It exposes `hasUpcomingFavorite` for the
  presentation indicator while preserving live-favorite priority and bounded
  tooltip text.
- `BarWidget.qml` renders both orientation branches with `BarIconButton` and
  uses the same five-pixel status dot in each branch. The icon and tooltip
  remain provider-neutral and use the existing `Iconography`/formatter
  boundaries; no provider, polling, timer, settings, or IPC behavior changed.
- `fixtures/bar-presentation/policy.json` and the deterministic suite cover
  countdown suppression, tooltip fallback, upcoming/live indicator state, and
  icon-button source wiring. The complete suite passes with 185 tests.
- README now documents the compact icon presentation and color status
  indicator. The checkout intentionally remains without
  `docs/upstream-contract.md`; installed Omarchy 4.0.0-1 / Quickshell 0.3.0
  revision `28771c7` were used for the `BarIconButton` boundary.
- `omarchy plugin validate "$PWD"`, the real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` command over every QML
  file, and `git diff --check` pass with the established lint warnings.
- Actual Omarchy shell restart loaded the linked checkout into one running
  Quickshell instance (`p66hhg1akt`, PID 801169). `shell ping` returned `ok`,
  `debugBarGeometry` showed a visible 27x26 Sportray slot, and a fresh
  screenshot showed the icon-only tray with no countdown text. The fresh log
  contains normal Sportray initialization/fetch activity and no Sportray
  exception, QML load failure, or binding-loop warning. The earlier rescan-only
  attempt retained the old 133px widget until the supported shell restart;
  this is host cache/lifecycle evidence, not a Sportray runtime error.

Decision log: prefer the smallest glanceable status treatment requested by the
user: preserve the icon, use accent for a scheduled favorite and urgent for a
live favorite, and leave richer score/start text to hover and the panel. Do not
add an upcoming-game count or a new timer while the color indicator is enough.
Keep the pure countdown policy fixture-tested for possible future non-tray use,
but do not expose its minute-changing label in the ambient button.

Known risks: the indicator communicates only the presence of an upcoming
favorite, not a total upcoming-game count; the tooltip still reflects the
selected normalized ambient state; and the installed host may require a full
shell restart to replace a cached active widget after source edits.

## Latest handoff — 2026-08-24 icon-only ambient tray presentation complete

The tray presentation change is complete in `/home/joeg/Projects/sportray`.
`BarPresentation` no longer uses `favorite-upcoming` countdown labels as tray
text. Both horizontal and vertical `BarWidget.qml` branches render the sport
icon through `BarIconButton`; upcoming favorites get an accent dot and live
favorites get an urgent dot. Tooltips retain bounded score/start details, and
the panel, normalized providers, polling, settings, notifications, and IPC
remain unchanged.

The fixture-driven suite passes with 185 tests. Plugin validation, full
real-import-path QML lint, and `git diff --check` pass. On actual Omarchy, the
linked plugin was loaded after the supported `omarchy-restart-shell` boundary;
one Quickshell instance remained healthy, geometry was 27x26, and a fresh
screenshot confirmed the countdown text was gone. The fresh instance log has
normal Sportray activity with no exception, QML load failure, or binding-loop
warning. No push, tag, release, Marketplace, or remote action occurred.

Next bounded unit: revisit the external post-rescan summon helper only after a
concrete existing client caller is introduced or an installed Omarchy/Quickshell
update changes the widget-registration/readiness contract. If neither
prerequisite exists, recheck installed sources, record the unchanged blocker,
and stop without speculative runtime changes.

## Latest handoff — 2026-08-24 game-card venue readability

Status: complete. The scoreboard game-card footer now gives venue text its own
metadata line instead of appending it to the status/start-time line that shares
space with the provider source action. `GameRow.qml` renders `At <venue>` with
bounded two-line wrapping, measures the full footer column for card height, and
keeps the ESPN/NHL.com source button in a separate trailing column centered
against the footer. No provider, normalized model, polling, settings,
notification, or host IPC behavior changed.

Evidence:

- The complete fixture-driven JavaScript suite passes with 185 tests.
- `omarchy plugin validate "$PWD"`, real-import-path `qmllint` over every QML
  file, `tests/test-summon-helper.sh`, and `git diff --check` pass. QML lint
  exits 0 with the established standalone import and unqualified-access
  warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` restarted into one healthy
  Quickshell instance (`c0240dfe8c8e8a421e1f8db23a03fc60`, PID 806461).
  `shell ping` returned `ok`, the linked Sportray plugin loaded, and the live
  panel visibly rendered `At LoanDepot Park` on its own line while `ESPN`
  remained a distinct reachable action. The fresh log contains normal
  provider/cache activity and no Sportray exception, QML load failure, or
  binding-loop warning.
- The checkout intentionally still has no `docs/upstream-contract.md`;
  installed Omarchy sources remain the upstream boundary evidence. No push,
  tag, release, Marketplace, or remote action occurred.

Decision log: preserve the existing compact card and source attribution while
using the available vertical space to make venue a readable detail. Keep the
source action outside the metadata flow so long venue labels cannot be
shortened merely because `ESPN` or `NHL.com` is present. Do not add provider
fields, a new detail endpoint, or a separate settings/layout preference.

Known risk: very long venue names can still wrap to the bounded two-line limit
at narrow panel widths, but they no longer compete with the source action on
the same line. The installed host may require a full shell restart to replace
the active plugin component after QML source edits; rescan-only reload behavior
is unchanged.

Next bounded unit: revisit the external post-rescan summon helper only after a
concrete existing client caller is introduced or an installed Omarchy/Quickshell
update changes the widget-registration/readiness contract. If neither
prerequisite exists, recheck installed sources, record the unchanged blocker,
and stop without speculative runtime changes.

## Latest handoff — 2026-08-24 private competition reference

The private `competition.md` reference is complete. It records the current
generalist peers (`Scores`, `Sportsbar`, `Omatchday`, and `OmaSoccer`), focused
MLB/F1/esports/VCT peers, the ideas worth borrowing, Sportray's already-landed
parity work, and a prioritized backlog. The catalog was refreshed on 2026-08-24
from its live `catalog.json` feed. No public README, runtime code, provider,
Marketplace, release, tag, or remote state changed.

The reference deliberately distinguishes existing parity from remaining gaps:
rich sport-specific detail, NHL standings, pregame/close alerts, provider
fallback chains, broader team discovery, calendar context, and specialist
adapters. The recommended next slices are NHL standings, one optional rich
detail section, and one pregame reminder policy, in that order.

This unit preserves the user's unrelated deletion of local
`MARKETPLACE_SUBMISSION.md`; it was not staged or restored. A read-only check
also shows that `origin/main` still contains historical private planning and
Marketplace files, so no push or remote cleanup was attempted. Removing those
files from the public branch requires a separate owner-authorized remote
cleanup unit.

Next bounded unit: implement a verified NHL standings adapter and standings
presentation projection. Stop before rich detail, pregame/close alerts,
provider fallback, broader discovery, specialist sports, packaging, tagging,
pushing, release, or Marketplace work.

## NHL standings adapter/projection — 2026-08-24

Status: complete as a bounded NHL standings vertical slice. NHL league
destinations now use the existing on-demand standings route, with conference
groups, NHL sequence ordering, nullable metrics, canonical current-team
identity, reviewed logo admission, and the existing favorite toggle action.

Evidence:

- The current no-key NHL response was verified from
  `https://api-web.nhle.com/v1/standings/now` on 2026-08-24. It supplies a
  flat `standings` array, Eastern/Western conference metadata,
  `conferenceSequence`/`leagueSequence`, numeric record fields, tri-code
  identity, and `assets.nhle.com` logos. The fixture follows that observed
  shape but remains bounded to five records.
- `providers/NhlProvider.js` maps only the 32 tri-codes in the current
  `NhlTeamCatalog` roster to numeric provider IDs, rejects unknown or missing
  tri-codes, preserves missing optional values as nulls, formats the NHL
  W-L-OT record, and returns the existing provider-neutral standings model.
- `services/StandingsFetch.qml` selects the NHL adapter at the provider
  boundary; `LeagueCatalog.js` enables NHL standings, so the existing header
  action, `StandingsRows` projection, canonical favorite toggle, and neutral
  missing-field display are reused without a new QML view contract.
- `fixtures/nhl/standings.json` and `tests/run-js-tests.js` cover conference
  ordering, NHL OT-loss records, canonical IDs, reviewed logos, missing
  fields, unknown-team rejection, malformed/empty payloads, and favorite
  routing. The live endpoint also parsed to 32 rows, two groups, and zero
  errors during this unit.
- `./tests/run-js-tests.sh`, `omarchy plugin validate "$PWD"`, real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell services/StandingsFetch.qml`,
  and `git diff --check` pass. QML lint retains the known standalone warning
  for the existing `Process.onExited` parameter type.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0.r20 rescanned the linked
  checkout and successfully summoned the Sportray panel. The inspected
  Quickshell log contains normal Sportray fetch activity and no new QML
  exception, binding-loop, or standings error. The installed bar-widget IPC
  does not expose child view methods, and the available desktop input path did
  not complete a reliable popup focus/toggle exercise; no UI-route success is
  claimed from that attempt.

Decision log: use the verified current standings route only, group by
conference in Eastern/Western order, and use `conferenceSequence` as the NHL
display rank with `leagueSequence` as a safe fallback. Resolve tri-codes
through the existing bounded catalog because the standings payload has no
numeric team ID. Keep the generic standings model and favorite action shared;
represent the NHL third record value as the existing generic `ties` slot plus
an explicit W-L-OT label. Do not add a second standings endpoint, division or
wild-card specialist UI, fallback provider, alerts, rich detail, discovery,
packaging, release, tag, push, or Marketplace work.

The private `docs/upstream-contract.md` remains intentionally absent from this
checkout; the installed Omarchy shell sources were inspected directly for the
bar-widget, rescan, IPC, and import-path boundaries. The unrelated deletion of
`MARKETPLACE_SUBMISSION.md` remains untouched and unstaged.

## Latest handoff — 2026-08-24 NHL standings adapter/projection

The NHL standings unit is implemented in the current worktree and passes the
deterministic suite, provider response bounds, fixture checks, plugin
validation, real-import-path QML lint, and diff check. The live NHL standings
response is verified and parses into 32 canonical rows in Eastern/Western
conference groups. The existing NHL score route, favorite/settings behavior,
and generic standings presentation remain provider-neutral.

Actual Omarchy rescanned and summoned the linked Sportray bar widget; logs
show normal fetch activity with no new QML exception, binding-loop, or
standings error. The host IPC can summon/hide bar widgets but cannot call the
child panel's route methods, and no reliable desktop pointer injector was
available for a final visual standings-toggle exercise. Treat that as a
runtime verification limitation, not evidence of a passing UI interaction.

No rich game detail, pregame/close alerts, provider fallback, broader
discovery, specialist sport work, calendar redesign, packaging, release, tag,
push, or Marketplace action occurred. The local deletion of
`MARKETPLACE_SUBMISSION.md` remains preserved and unstaged.

Next bounded unit: add one optional rich-detail section using an already
normalized ESPN fixture, without a new endpoint or NHL standings changes.

## Latest handoff — 2026-08-24 local game-detail route removal

Status: complete. The local game-details page is no longer part of the user
flow. It duplicated the scoreboard projection, exposed the canonical internal
ID (for example `mlb:2039230240`), and offered no additional provider data.

`ResultRows` now labels valid linked game rows as `open-source`; `GameRow`
requires a non-empty string URL for whole-row activation and delegates to the
existing guarded `SourceLinkButton`. `Panel.qml` no longer owns detail state,
detail keyboard routing, detail height calculation, or a `GameDetailView`
instance. The provider-neutral `GameDetailModel` and view source remain
unwired as future groundwork, but no local detail route is reachable.

README behavior text, the row-action fixture, and accessibility/source-routing
coverage now describe and verify the provider game page as the only whole-row
destination. No provider parser, endpoint, settings, polling, standings, or
notification behavior changed.

Evidence: the complete JavaScript suite passes with 185 tests; `omarchy plugin
validate "$PWD"`, real-import-path `qmllint`, and `git diff --check` pass.
Actual Omarchy 4.0.0-1 rescanned the linked checkout, the Sportray summon
helper returned `ok`, shell ping returned `ok`, exactly one Quickshell process
was present, and the current log showed normal fetch activity without a new
Sportray exception, QML load failure, or binding-loop warning. Child-route
IPC and a reliable desktop pointer injector remain unavailable, so no manual
click-through result is claimed.

Decision log: hide the shallow local detail route until a normalized payload
can supply materially richer content. Keep the existing labeled ESPN/NHL.com
source action and make whole-row activation use that same safe browser route;
do not expose internal canonical IDs in a presentation surface.

Known risks: a whole-row tap now opens the provider page when a safe link is
available, so users should use the labeled source button when they want the
destination to be explicit. Games without a valid provider link remain
non-activatable at the row level. The retained detail model/view are not yet a
product contract.

Next bounded unit: add one fixture-driven optional rich-detail projection to
the provider-neutral model from an already normalized ESPN game, without
restoring the local detail route or adding a new endpoint. Stop before any
provider-specific section, second fetch, or UI re-exposure.

## Optional rich-detail projection — 2026-08-24

Status: complete. `model/GameDetailModel.js` now projects one optional,
provider-neutral `outcome` section from the already normalized final-game
scores. It returns only `home`, `away`, or `draw` plus a bounded numeric margin;
scheduled games, missing scores, malformed scores, and scores above the
projection bound return `null`. No canonical identity is added to the
projection, and the retained `GameDetailView.qml` remains unwired.

Evidence:

- `fixtures/espn/raw/game-detail-outcome.json` drives present, missing,
  malformed, and over-bound score cases through the existing ESPN scoreboard
  parser and provider-neutral detail model.
- The complete fixture-driven JavaScript suite passes with 186 tests,
  including the new outcome projection assertions. `omarchy plugin validate
  "$PWD"` passes, full real-import-path QML lint exits 0 with the established
  standalone import/unqualified-access warnings, and `git diff --check` passes.
- No QML file, `Panel.qml`, `ResultRows`, `GameRow`, source action, provider
  endpoint, polling path, standings adapter, or route state changed.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` was inspected directly. The linked
  plugin rescan completed, the summon helper returned `ok`, one shell instance
  remained running, and the log tail showed normal Sportray fetch/cache
  activity with no new exception, QML load failure, or binding-loop warning.
  No UI interaction is claimed because the projection is not mounted and the
  child-route IPC/pointer limitations remain.

Decision log: use a final-result outcome rather than introducing sport-specific
period/inning/leader data or a second endpoint. Keep the section absent in
meaning by returning `null` unless normalized final scores are complete and
within the conservative 9,999-point bound. Leave all presentation and routing
unchanged until a future unit proves a richer view contract.

Boundary note: `docs/upstream-contract.md` remains intentionally absent. The
installed Omarchy/Quickshell bar-widget, rescan, summon, and import-path
contracts were inspected directly; no material upstream boundary deviation
was found. The unrelated deletion of `MARKETPLACE_SUBMISSION.md` remains
untouched and unstaged.

Next bounded unit: add one opt-in, favorite-only pregame reminder policy using
the existing normalized `startTime` and notification pipeline. Keep close-game
alerts, new endpoints, provider fallback, and UI discovery out of scope.

## Latest handoff — 2026-08-24 opt-in pregame reminder policy

Status: complete. Sportray now supports one independently configurable,
favorite-only pregame reminder through the existing notification pipeline.
`model/PregameReminderPolicy.js` admits only normalized, valid, scheduled
favorite games whose `startTime` is a valid future timestamp on the current
local date and no more than 30 minutes away. Missing, malformed, stale,
out-of-window, non-favorite, live, and next-day games fail closed. The policy
does not request a second provider endpoint or expose canonical IDs in the
notification text.

The schema-1 notification settings now include `pregameReminder`, defaulting
to `false`; the existing Notifications destination exposes the single opt-in
toggle. `NotificationService` evaluates the pure policy on the existing
today-game snapshot after the established first-fetch baseline, builds the
existing helper argv, and sends the new event through the existing persisted
transition-dedupe state. A `gameId:pregame` fingerprint suppresses repeats
across polling and state reloads. Existing game-start, score-change, final,
test-notification, favorite-only, and first-fetch behavior remains unchanged.

Evidence:

- `fixtures/transitions/m6-5.json` and the deterministic suite cover an
  eligible upcoming favorite, disabled preference, non-favorite, malformed
  and stale timestamps, a 30-minute out-of-window timestamp, a next-day
  timestamp, non-scheduled status, bounded helper text, canonical-ID text
  exclusion, and persisted duplicate suppression. The complete suite passes
  with 188 tests.
- `omarchy plugin validate "$PWD"` passes. Full
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  exits 0 with the established standalone import and unqualified-access
  warnings. `./tests/test-summon-helper.sh` and `git diff --check` pass.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` remains healthy with one shell
  instance. The linked checkout was rescanned, the helper summoned Sportray
  with `ok`, hide returned successfully, and the fresh log tail contained
  normal provider/cache activity with no Sportray exception, QML load
  failure, binding-loop warning, or notification-helper failure. No manual
  settings click-through is claimed because child-route IPC and a reliable
  desktop pointer injector remain unavailable.

Decision log: keep the reminder as a pure normalized-game projection and
reuse the existing notification helper, queue, settings persistence, and
transition fingerprint store. Use a conservative fixed 30-minute maximum,
local-date matching, and first-fetch silence so enabling the feature cannot
replay startup schedules. Keep pregame text to sanitized team labels plus a
bounded relative lead; do not add calendar, provider, or per-game fetch work.
The private `docs/upstream-contract.md` remains intentionally absent; the
installed Omarchy sources were inspected directly and no material host-boundary
deviation was found. No push, tag, release, Marketplace, or remote action was
performed, and unrelated repository state was preserved.

Known risks: reminders depend on the existing scoreboard refresh cadence, so a
provider snapshot that first arrives after its 30-minute window will not alert;
settings changes take effect on the next existing game snapshot; and regional
provider availability remains unchanged. Close-game alerts, provider fallback,
new endpoints, specialist sports, packaging, and publication remain out of
scope.

Next bounded unit: add one independently configurable, favorite-only close-game
alert using only existing normalized live-game scores/status and the existing
notification/dedupe pipeline. Preserve the new pregame reminder and all
start/score/final behavior; stop before adding a second endpoint, provider UI,
fallback, broader discovery, specialist sports, packaging, tagging, pushing,
releases, or Marketplace work.

## Latest handoff — 2026-08-24 close-game alert and settings-preview wiring

Status: complete. Sportray now supports one independently configurable,
favorite-only close-game alert through the existing normalized-game
notification pipeline. `model/CloseGamePolicy.js` admits only a transition into
an in-progress (`live` or `intermission`) favorite game whose valid normalized
scores are tied or separated by one point, and only when the game's local start
date matches the current local date. It fails closed for disabled preferences,
non-favorites, scheduled/final games, missing or malformed scores/timestamps,
and wider margins. The prior snapshot is required, so first-fetch snapshots
remain silent.

The schema-1 notification settings now include `closeGame`, defaulting to
`false`; the Notifications destination exposes the independent **Close-game
alerts** toggle. `NotificationService` evaluates the pure policy on the
existing today-game snapshot and sends a bounded provider-neutral delivery
through the existing helper and persisted transition dedupe. The new
`gameId:close` fingerprint suppresses repeats across polling and state reloads.
Existing start, score-change, final, test-preview, and pregame behavior remains
unchanged.

The settings-page test-notification report was also reproduced and diagnosed:
the direct helper and prior real Sportray alert history were healthy, but
`Panel.qml` passed an unqualified undefined `notificationService` into
`SettingsHub`, so `SettingsView` silently had no service to call. The singleton
now explicitly exposes its `NotificationService`, and Panel injects that
object. This is a wiring correction within the existing notification boundary;
the helper contract and queue remain unchanged.

Evidence:

- `fixtures/transitions/m6-6.json` and deterministic tests cover an eligible
  close transition, disabled preference, non-favorite, non-live, missing and
  malformed score/date state, wider margin, bounded text, canonical-ID text
  exclusion, and duplicate suppression across state reload. The complete
  JavaScript suite passes with 190 tests.
- `omarchy plugin validate "$PWD"`, real-import-path QML lint over the changed
  QML and all QML files, `./tests/test-summon-helper.sh`, and `git diff --check`
  pass. QML lint exits 0 with the established standalone import, unresolved
  host-type, and unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` was inspected. The installed
  `/usr/bin/omarchy-notification-send` was exercised directly with the exact
  Sportray argv and returned exit 0; the Omarchy notification history recorded
  the resulting `Sportray · Settings-path verification` toast. Existing history also contains
  real Sportray start, score-change, and final notifications. Plugin discovery
  still lists Sportray enabled, the shell ping returns `ok`, and no helper,
  QML-load, exception, or binding-loop error was present in the inspected shell
  log. A child-panel IPC method and reliable desktop pointer injector remain
  unavailable, so no manual settings click-through is claimed.

Decision log: define close as a provider-neutral one-score margin rather than
inventing sport-specific thresholds; include intermission because it is an
in-progress normalized state; require a transition into the margin and reuse
the existing persisted dedupe to avoid a notification on every polling tick.
Keep the setting default-off and preserve schema-1 recovery/future-schema
opacity. Repair the settings preview by exposing the existing service object,
not by adding a second helper or notification route. The private
`docs/upstream-contract.md` remains intentionally absent; installed Omarchy
and Quickshell sources were inspected directly and no material host-boundary
deviation was found.

Known risks: a snapshot that first arrives after a game has already entered the
one-score margin will not alert because the policy requires a prior snapshot;
the alert depends on the existing scoreboard refresh cadence; and actual
settings click-through still needs a host-supported child-route or pointer
test. Provider availability and regional behavior are unchanged. No push, tag,
release, Marketplace, or remote action was performed, and unrelated repository
state remains preserved.

Next bounded unit: perform one actual Omarchy settings-page **Send test
notification** runtime verification against the now-explicit service wiring.
Use the installed host's current child-panel IPC or a reliable desktop input
path if available; inspect the notification history and Quickshell logs. If
the host still cannot expose a reliable settings interaction, record that
external blocker and leave Sportray source unchanged. Stop before adding a
second notification route, provider endpoint, alert type, UI discovery,
specialist sports, packaging, tagging, pushing, release, or Marketplace work.

## Latest handoff — 2026-08-24 Settings-page notification runtime verification

Status: complete. The previously reported missing Settings-page test toast
was reproduced against the live Omarchy bar widget and traced to a stale
already-loaded QML instance, not to the notification helper or the explicit
`NotificationService` wiring completed in `0c128f7`. The stale Settings view
predated the Pregame reminders and Close-game alerts controls, confirming that
the active widget had not loaded the current checkout. `rescanPlugins` and a
successful bar-widget summon did not replace that active instance.

The installed/current Omarchy boundary was inspected directly: `shell call`
only addresses panel/overlay/menu loaders and returns `unknown` for this
bar-widget; bar widgets are managed through the summon/toggle path. Running
the supported `omarchy restart shell` replaced the shell instance, after which
the current Notifications destination rendered all six preferences and the
**Send test notification** control. Keyboard activation through the real
settings route caused Omarchy notification history to record
`Sportray · Test notification` with body `Alerts are working. This is a preview
from Sportray.` The fresh Quickshell log showed normal Sportray startup and
provider/cache activity with no Sportray QML-load, exception, binding-loop, or
notification-helper failure.

Evidence:

- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 revision
  `28771c7c74b42e20afca0b1b63980cb46515537` was used. `omarchy plugin list`
  still reports Sportray enabled, `omarchy-shell shell ping` returns `ok`, and
  the restarted shell has one live Sportray bar widget.
- The current settings screenshot showed Notifications, Game starts, Score
  changes, Game finals, Pregame reminders, Close-game alerts, and Send test
  notification. The notification history recorded six successful preview
  deliveries from the exercised keyboard sequence; the helper path itself is
  therefore confirmed, while repeated-key behavior is not expanded into this
  unit.
- No Sportray source change was required. The public README now documents the
  installed lifecycle boundary and the recovery command. The private
  `docs/upstream-contract.md` remains absent, so installed Omarchy and
  Quickshell sources remain the boundary source of truth.

Decision log: treat an active bar-widget that survives rescan as a host
lifecycle/cache condition. Recover with the supported shell restart rather
than adding a second plugin process, a second notification route, or an
unsupported child-panel IPC path. Preserve the existing explicit service
wiring and `/usr/bin/omarchy-notification-send` queue.

Known risks: a user or developer may need to restart the Omarchy shell after
source changes when rescan leaves an old bar-widget instance alive; no
reliable desktop pointer injector was available in this environment, so the
runtime interaction was completed through real keyboard input rather than a
pointer click. No provider, settings schema, notification policy, packaging,
tagging, pushing, release, Marketplace, or remote state changed.

Next bounded unit: perform one read-only release-readiness consistency audit
of the current notification behavior and its README/roadmap evidence after
the verified shell-restart recovery. Reconcile only directly observed stale
documentation or acceptance claims; do not change provider, notification,
settings, QML, packaging, or Marketplace behavior without a new owner request.

## Latest handoff — 2026-08-24 notification/lifecycle consistency audit

Status: complete. The public README, private roadmap, current notification
source, and installed Omarchy/Quickshell lifecycle boundary were audited after
the verified shell-restart recovery. One stale wording issue was found and
corrected: the underlying shell `summon`/`toggle` functions take a payload
argument, but the installed `/usr/share/omarchy/bin/omarchy-shell` wrapper
automatically supplies `{}` when that argument is omitted. The README now
documents that distinction while keeping Sportray's explicit `{}` examples and
post-rescan helper behavior.

The remaining notification claims agree with the checked-out source and prior
runtime evidence: all six schema-1 notification preferences are exposed,
pregame and close-game alerts are independently opt-in and favorite-only, the
test preview bypasses event preferences and transition dedupe, and the helper
argv remains `/usr/bin/omarchy-notification-send`. The README's shell-restart
recovery guidance also remains supported. Installed `shell.qml` routes
bar-widget summon/hide/toggle through the live bar instance, limits `call` to
panel loaders, and leaves an already-loaded matching widget component in place
during plugin rescan; a shell restart is therefore the supported recovery when
current QML is not visible.

Evidence:

- Direct source inspection covered `/usr/share/omarchy/bin/omarchy-shell`,
  `/usr/share/omarchy/shell/shell.qml`,
  `/usr/share/omarchy/shell/services/PluginRegistry.qml`, the installed
  Omarchy plugin guidance, `/usr/bin/omarchy-notification-send`,
  `services/NotificationService.qml`, `services/SportrayService.qml`,
  `Panel.qml`, and `components/SettingsView.qml`.
- No new shell/widget runtime pass was claimed in this read-only audit. The
  actual Omarchy settings interaction, notification-history entries, and
  clean post-restart log are the preceding 2026-08-24 handoff's evidence.
- The unrelated deletion of `MARKETPLACE_SUBMISSION.md` remains untouched and
  unstaged. No provider, notification policy, settings schema, QML behavior,
  packaging, remote state, tag, release, or Marketplace state changed.

Decision log: describe the wrapper and underlying IPC separately so the public
command contract is accurate without weakening the explicit-argument helper
or implying that a rescan reconstructs a live bar-widget instance. Keep the
prior runtime evidence historical and do not report it as a new verification
for this audit.

Known risks: an active bar-widget can still require `omarchy restart shell`
after source changes; pointer injection and repeated-key behavior remain
unverified as broader contracts; ESPN remains an undocumented provider API.

Next bounded unit: perform one read-only release-candidate metadata consistency
check for the owner-assigned `1.0.0-rc.8` across `manifest.json`, `README.md`,
`CHANGELOG.md`, and local git tags/refs. Do not push, tag, publish, submit to
Marketplace, or alter release metadata unless the owner separately authorizes
that action.

## Latest handoff — 2026-08-24 release-candidate metadata consistency

Status: complete. The owner-assigned `1.0.0-rc.8` metadata is consistent across
`manifest.json`, the README's Marketplace listing section, and the changelog's
`Unreleased` section. The local candidate remains unreleased and untagged; no
release date was added or inferred.

The read-only ref audit found `main`, `origin/main`, and `origin/HEAD` all at
`9942e0f4b6d4ca2cdb5b8652182f31ce26f4c1a4`. The only local version tag is the
unchanged annotated `v1.0.0-rc.7`, which peels to
`de450941b5846914e1f8200f1a74ccf0a301428c`; `HEAD` is 47 commits beyond that
tag. No `rc.8` tag exists. The closing changelog summary had one stale,
ambiguous sentence that said `v1.0.0-rc.7` identified “this release
candidate”; it now explicitly identifies the historical `1.0.0-rc.7` snapshot
and states that `1.0.0-rc.8` is still unreleased and untagged. No other
metadata, historical `rc.7` evidence, or release wording required change.

Evidence: `tests/run-js-tests.sh` passes with 190 deterministic tests;
`omarchy plugin validate "$PWD"` passes on actual Omarchy; real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files exits
0 with the established standalone import and unqualified-access warnings;
`./tests/test-summon-helper.sh` passes; and `git diff --check` passes. This
documentation-only unit performed no new shell/widget runtime check and makes
no new Omarchy runtime claim. The checkout still intentionally lacks
`docs/upstream-contract.md`; no host-boundary inspection was needed. The
unrelated absence/deletion of `MARKETPLACE_SUBMISSION.md` remains untouched.

No tag, push, release, Marketplace submission, issue change, or remote state
change occurred. Known risks remain owner-controlled release authorization,
remote target parity for any future publication, Marketplace verification, and
preview rights.

Decision log: keep the current candidate in `Unreleased`, preserve the
historical `rc.7` tag and evidence, and make only directly contradictory local
release wording precise. Do not infer a release date or promote `rc.8` to a tag
without explicit owner authorization.

Next bounded unit: after explicit owner authorization for a release-related
follow-up, perform one read-only audit of the owner-specified target commit or
ref against `manifest.json`, `README.md`, `CHANGELOG.md`, and the local tags.
If no authorization or target ref is supplied, report that release state is
unchanged and stop. Do not tag, push, publish, submit, edit Marketplace state,
or make provider, notification, settings, QML, or packaging changes.

## Latest handoff — 2026-08-24 optional lines rich-detail projection

Status: complete. The second optional rich-detail section is implemented as a
bounded provider-neutral projection. `model/GameDetailModel.js` now exposes an
optional `lines` record — `{away: [{period, value}...], home: [...]}` or
`null` — projected from already normalized game data without a new endpoint,
without touching `GameModel`'s normalized shape, and without remounting the
retired local detail route.

Evidence:

- On 2026-08-24 the live ESPN NFL scoreboard response was inspected directly
  and confirmed to carry per-competitor `linescores` entries with `value`,
  `displayValue`, and `period`; MLB competitors additionally carry `records`,
  `hits`, and `errors`. No second fetch is required for period lines.
- `GameDetailModel` bounds each side at `MAX_LINE_PERIODS = 12` entries,
  periods at 1–99 (`MAX_LINE_PERIOD_NUMBER`), and values at the existing
  9,999-point outcome bound. Any malformed, duplicate-period, over-bound, or
  length-mismatched side fails closed to `lines: null`. Entries are sorted by
  period ascending. `emptyDetail` carries `lines: null`.
- `providers/EspnProvider.js` extracts linescores from the same payload inside
  `parseGameDetailResponse` only, keyed by provider game ID and merged into the
  detail candidate before normalization. `parseScoreboardResponse`, the
  normalized game shape, polling, and all other consumers are unchanged.
- `fixtures/espn/raw/game-detail-lines.json` covers valid lines, out-of-order
  sorting, malformed entry rejection, side-length mismatch, over-bound values,
  duplicate periods, and missing linescores. One new deterministic test asserts
  the accepted projections, every rejected case as `null`, both new bounds, and
  the absence of raw payload fields. The complete suite passes with 191 tests.
- `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass with the established standalone import/unqualified-access warnings. No
  QML file changed, so no plugin rescan or fresh runtime log claim is needed;
  this mirrors the prior pure model/provider units.

Decision log: keep period lines strictly a detail-section concept fed from the
already fetched scoreboard snapshot; do not add fields to every normalized
game. Fail closed per side and require equal-length sides so a partially valid
table never renders invented rows. Provider labels such as `displayValue` are
not retained; any human-readable period label is later presentation work. The
detail view remains unmounted until it can present materially richer content
than the score row.

Known risks: ESPN is an undocumented site API; linescores presence varies by
league and state (pre-event slates carry none, which projects `null`). NHL's
own score route does not expose equivalent per-period lines, so NHL detail
remains sparse. The owner has also requested a follow-up full-calendar view
with followed-team/league filtering; that remains a separate future unit.

Next bounded unit: remount the local game-detail drill-down as one small
existing-route extension that renders the now materially richer projection
(participants, status/timing, venue, source action, optional outcome, optional
lines) with neutral placeholders for nulls, preserving whole-row source
routing when the detail route is unavailable. Stop before any second endpoint,
box-score/play-by-play adapters, sport-specific sections, calendar views,
provider fallback, packaging, tagging, pushing, release, or Marketplace work.

## Latest handoff — 2026-08-24 game-detail drill-down remount

Status: complete. The local game-detail drill-down is remounted as one small
existing-route extension that renders the materially richer
`GameDetailModel` projection. No second endpoint, provider parser, normalized
shape, polling, settings, or notification behavior changed.

Evidence:

- `model/ResultRows.js` labels valid loaded game rows `open-detail`
  ("View game details") again; invalid games stay non-activatable.
  `components/GameRow.qml` routes whole-row pointer, keyboard, and assistive
  activation of valid games to the local detail route, while the nested
  guarded `SourceLinkButton` remains the only external-page route.
- `components/GameDetailView.qml` renders provider-neutral identity, ordered
  participants with `—` score placeholders, status/timing, venue, the nested
  source action, an optional `Outcome` line from the bounded outcome
  projection, and a bounded `SCORING BY PERIOD` away/home table from the
  optional `lines` projection. Null outcome/lines (pre-event and most NHL
  games) render neutral `—` placeholders and never imply box-score depth.
- `Panel.qml` owns `detailOpen`/`detailGame` local state, Back-first cursor,
  Escape/Back closing the detail route before panel close, detail-bounded
  height (320–600), header chrome suppression while open, and detail state
  cleared on panel close. Scores, standings, settings, and polling routes are
  unchanged.
- `fixtures/game-detail-route/route.json` records the restored row action,
  detail back/escape actions, and extended sparse placeholders;
  `fixtures/accessibility-actions/actions.json` restores the valid-game row
  guard. Four deterministic tests cover row routing, sparse placeholders,
  outcome/lines rendering bounds with fixture-backed projections, and
  back/Escape ordering. The complete suite passes with 194 tests.
- `omarchy plugin validate "$PWD"`, real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  (exit 0 with the established standalone import/unqualified-access
  warnings), and `git diff --check` pass. README now documents the restored
  drill-down and its no-second-fetch boundary.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the first runtime attempt hit
  the documented stale-widget rescan condition (whole-row still opened the
  ESPN page), so the supported `omarchy restart shell` loaded the linked
  checkout into one Quickshell instance (`s4oihlcakt`, PID 871084); shell ping
  returned `ok`. Keyboard Down/Return opened the rendered `Game details` view
  for `mlb:401816655` (BOS @ MIA, scheduled): participants with `—` score
  placeholders, scheduled status, start time, venue, `Outcome —`, and
  `SCORING BY PERIOD —` placeholders with the nested ESPN action. Escape
  returned safely to the scores route. The fresh log contains no Sportray
  exception, QML load failure, or binding-loop warning; only the pre-existing
  unrelated portal registration warning remains.
- One integration defect was found and fixed during runtime verification: the
  detail view was initially nested inside the score content item and was
  hidden together with it; it was moved back to its verified sibling position.

Decision log: the remount stays a presentation-only projection of the
already loaded scoreboard snapshot. Keep the source action nested and
provider-safe, do not fetch a second detail endpoint, and do not add
box-score, play-by-play, or sport-specific sections. Null-heavy games are
intentionally shallow and neutral.

Not exercised: the nested source button was not activated from the detail
view (its browser route is unchanged and separately verified), live per-period
lines were not rendered at runtime because no live linescores game was
available (covered by the fixture path), and the pointer click path was not
exercised (keyboard was used).

No push, tag, release, or Marketplace action occurred. Known risks: ESPN
remains an undocumented API; lines presence varies by league and state; the
detail status line can repeat the state word when the provider detail mirrors
it (pre-existing view logic); pointer activation of the detail route remains
manually unexercised.

## Full-calendar day-list slice — 2026-08-24

Status: complete. The owner-requested calendar is implemented as one bounded
vertical slice: a pure provider-neutral calendar model projecting the
already-fetched bounded date caches into a day list with followed-team and
enabled-league filters, mounted in the existing panel behind a minimal header
action and `C` shortcut. No new polling owner, fetch graph, provider endpoint,
or per-game request was added.

Evidence:

- `model/CalendarModel.js` composes `{leagueId, displayName, days:[{dateKey,
  games}]}` windows into a bounded day list: clamped half-width (default 2,
  max 7) around the selected date, enabled-league admission, valid/identity/
  date-matching game admission, per-day dedupe, deterministic ordering
  (caller orderer or chronological fallback), a 64-game per-day bound, and
  fail-closed handling for malformed windows, days, and games. `flatten`
  reuses the existing scoreboard row vocabulary (section header, game row
  with the guarded `open-detail` action, neutral empty row) so the panel list,
  keyboard routing, and detail drill-down stay unchanged. QML-imported
  fallbacks mirror the `DateModel` boundary because QML cannot `require`.
- `services/LeagueFetch.qml` exposes `calendarSnapshot()`, which reads only
  the existing five-entry `dateCache`; `services/FetchService.qml` publishes
  `calendarStates` from the existing `updateAggregateState` cycle. The
  deterministic suite asserts the boundary: still exactly two `Process`
  objects and zero new `curl` uses, no timers or JSON parsing in the model,
  and the panel binding reads `fetchService.calendarStates` only.
- `Panel.qml` adds `calendarOpen`/`calendarFavoritesOnly`, a header
  Calendar/Scores toggle plus an All games/Favorites filter button (visible
  only while the calendar is open), the `C` text-key shortcut, Escape order
  detail → settings → calendar → panel close, calendar reset on
  open/close/destination change, and height recalculation through the
  existing `PanelLayout` tokens. Scores, standings, detail, settings,
  notification, and ambient-bar behavior are unchanged.
- `fixtures/calendar/calendar.json` and five deterministic tests cover
  window bounds and outside-window exclusion, disabled-league and malformed
  window rejection, favorite-only filtering, chronological versus
  favorite-first ordering, empty days, per-day bounds, invalid centers and
  non-array inputs, flatten row vocabulary and unique row IDs, and the
  no-new-fetch ownership boundary. The suite passes with 199 tests.
- `tests/run-js-tests.sh`, `git diff --check`, `omarchy plugin validate
  "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files pass with the established
  standalone import/unqualified-access and host-type warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into one instance
  (`5ywiedeakt`, PID 882509); shell ping returned `ok`, the plugin is enabled,
  and the summon helper returned `ok`. Keyboard exercise: `C` opened the
  calendar showing Sat Aug 22–Wed Aug 26 with neutral "No games" days and
  Mon Aug 24 listing multi-league games (MLB, Premier League) with league
  context; Down/Return opened the `Game details` drill-down for
  `mlb:401816655` (BOS @ MIA) with neutral placeholders and the ESPN action;
  Escape returned to the calendar, and a second Escape closed the panel. The
  fresh log has normal provider/cache activity and no Sportray exception,
  QML load failure, or binding-loop warning. One integration defect was found
  and fixed during runtime verification: the QML import path has no
  `require`, so the first runtime pass rendered an empty calendar until the
  model's date helpers gained QML-safe fallbacks.

Not exercised: pointer clicks (no reliable injector; keyboard was used), the
All games/Favorites filter button at runtime (header buttons are outside the
panel's keyboard cursor model; the filter is fixture-covered at the model
boundary), and days beyond the five-date cache (the calendar intentionally
fails closed to cached snapshots rather than fetching more).

Decision log: the calendar is a projection of the existing bounded date
caches only — no second fetch graph, lookahead reuse, or new endpoint. Day
rows reuse the scoreboard row vocabulary so detail routing and accessibility
stay shared. Filters live in the pure model; the UI exposes one favorites
toggle and relies on `enabledLeagues` for league admission. Stop before new
provider endpoints, per-game fetches, box scores, month-grid rendering,
provider fallback, packaging, tagging, pushing, release, or Marketplace work.

Known risks: the calendar can only show dates present in the five-entry
per-league caches, so freshly opened panels show one populated day until the
user browses more dates; ESPN remains an undocumented API; the filter toggle
and pointer paths remain manually unexercised.

## Latest handoff — 2026-08-24 keyboard-reachable calendar filter

Status: complete. The calendar All games/Favorites filter is now reachable
through the panel's existing keyboard model without a pointer, a second
interaction surface, or a host-side change.

Evidence:

- `model/KeyboardRoutingPolicy.js` adds the pure `calendarFilterAction`
  decision: only `f`/`F` with the calendar open and settings/detail closed
  returns `toggle-calendar-filter`; every other state fails closed to `none`.
  The pure calendar model, provider boundaries, and cursor routing are
  unchanged.
- `Panel.qml` routes the catcher's existing text-key path through that policy
  into the existing `toggleCalendarFilter()` function, so pointer clicks,
  assistive activation, and the keyboard shortcut all reach one route. The
  header filter button tooltip and accessible name now advertise `(F)`.
- `fixtures/keyboard-routing/filter-shortcut.json` and one deterministic test
  cover the accepted `f`/`F` case, closed-calendar, open-settings, open-detail,
  non-matching-key, and empty-key rejections, plus source assertions that the
  route lives only inside `onTextKey` and calls `toggleCalendarFilter()`. The
  complete suite passes with 200 tests.
- `tests/run-js-tests.sh`, `git diff --check`, `omarchy plugin validate
  "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files pass with the established
  standalone import/unqualified-access and host-type warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into one instance (PID
  889127); `shell ping` returned `ok` and the summon helper returned `ok`.
  Keyboard exercise: `C` opened the calendar showing the "All games" header
  filter with the full Mon Aug 24 slate (MLB, live Premier League, NFL);
  `f` flipped the header to "Favorites" and the day list to favorite games
  only; a second `f` restored "All games" and the full slate; Escape returned
  to the Today scores view and a second Escape closed the panel. Screenshots
  confirmed each state. The fresh log shows normal provider/cache activity and
  no Sportray exception, QML load failure, or binding-loop warning; only the
  unrelated Hyprland xkbcomp noise appears.

Not exercised: pointer clicks on the filter button (no reliable injector; the
keyboard route was used) and the settings-open/detail-open `f` rejection at
runtime (covered by the fixture path). No push, tag, release, Marketplace, or
remote action occurred. The unrelated absence of `MARKETPLACE_SUBMISSION.md`
remains untouched. The checkout intentionally has no
`docs/upstream-contract.md`; installed Omarchy sources remain the boundary
evidence and no upstream deviation was needed.

Decision log: use the panel's existing text-key routing policy rather than
folding the filter into the arrow-cursor model, because the header row is not
a cursor target in the installed `PanelKeyCatcher` contract and a text-key
shortcut adds no new interaction surface. The pure decision lives in
`KeyboardRoutingPolicy.js` so the QML binding stays declarative and
fixture-tested. Stop before new cursor targets, settings persistence for the
filter, month-grid rendering, provider work, packaging, tagging, pushing,
release, or Marketplace work.

## Latest handoff — 2026-08-24 post-filter calendar consistency audit

A read-only consistency audit of the calendar feature found no contradictions
between the README's calendar/keyboard behavior text, the roadmap acceptance
evidence for the calendar and keyboard-filter units, and the current sources.
No documentation or source edit was required beyond this handoff.

Evidence checked against source:

- README `C` toggle, bounded five-day day list around the selected date,
  All games/Favorites filter, neutral "No games" days, detail-drill-down rows,
  and the Escape chain match `KeyboardRoutingPolicy.calendarFilterAction`
  (only `f`/`F` with the calendar open and settings/detail closed),
  `CalendarModel.DEFAULT_HALF_WIDTH_DAYS = 2` (five-day window),
  `MAX_GAMES_PER_DAY = 64`, `emptyDayRow` ("No games"), the `open-detail`
  game-row action, and the panel's `onTextKey`/`onCloseRequested` routes.
- The header filter button tooltip and accessible name advertise `(F)`
  exactly as the keyboard handoff records.
- "Never starts new requests" holds: `LeagueFetch.calendarSnapshot()` reads
  only the existing bounded `dateCache`, and `FetchService.buildCalendarStates()`
  composes those snapshots without any request path.
- The roadmap's keyboard-filter acceptance evidence (200 tests, key names,
  fail-closed rejections, runtime exercise record) matches the current tree.

Gates rerun for this documentation-only outcome: `tests/run-js-tests.sh`
passes with 200 deterministic tests, `git diff --check` passes,
`omarchy plugin validate "$PWD"` passes on actual Omarchy, and real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
exits 0 with the established standalone import/unqualified-access warnings. No
QML changed, so no shell restart or log claim is made. No push, tag, release,
Marketplace, or remote action occurred. The checkout intentionally has no
`docs/upstream-contract.md`. Known limitations remain: pointer clicks on the
filter button are unexercised (no reliable injector), the settings-open/
detail-open `f` rejection is covered only by fixtures, and the calendar shows
only dates present in the five-entry per-league caches.

Next bounded unit: add one pure fixture-driven provider-fallback chain policy
for the existing per-league fetch boundary — the last unimplemented capability
of the recorded minimum competitive baseline — keeping it separate from QML
and timers until its contract is accepted. Stop before wiring it into
services, changing polling, adding endpoints, or publication work.

## Latest handoff — 2026-08-24 provider-fallback chain policy complete

The pure provider-fallback chain policy is complete and ready for its atomic
commit. This was the last unimplemented capability of the recorded minimum
competitive baseline; it remains an unwired pure model slice exactly like the
earlier rotation and countdown policy units.

Evidence:

- `model/ProviderFallbackPolicy.js` takes one league id, an ordered candidate
  list (first entry is primary; at most four unique valid provider ids), a
  caller-supplied health map of consecutive failures capped at threshold 3,
  caller-supplied `nowMs`, and an optional current provider id. It returns
  deterministic `primary` (healthy-primary retention), `current`
  (stay on the healthy current provider), `fallback` (next healthy candidate,
  including a cooled-down primary becoming retryable after the 15-minute
  cooldown), `exhausted` (every candidate cooling), or fail-closed `invalid`.
  Pure `recordFailure`/`recordSuccess` helpers return new state objects so
  callers own storage.
- `fixtures/provider-fallback/chain.json` contains sanitized provider ids and
  failure records only. Five deterministic tests cover healthy-primary
  retention, fallback within the cooldown window, recovery via success
  bookkeeping and cooldown expiry, malformed-input rejection (bad league,
  empty/duplicate/over-bound/non-string candidates, unknown current id,
  missing/NaN time), bounded exhaustion with attempted-provider accounting,
  and source assertions that the module has no timer, request, clock read,
  JSON parsing, require call, or provider import. The suite passes with 205
  tests.
- No QML file, service, provider, endpoint, polling cadence, or settings
  schema changed. The policy owns no timer, request, settings value, or
  provider parsing.
- `tests/run-js-tests.sh`, `git diff --check`, `omarchy plugin validate
  "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over every QML file pass; lint exits 0 with the
  established standalone import/unqualified-access warnings. No QML changed,
  so no shell restart, rescan, or fresh log claim is made for this unit.
- The checkout intentionally has no `docs/upstream-contract.md`; no host
  boundary was touched by this pure model unit, so no installed-source
  inspection was required beyond confirming no Omarchy/Quickshell API is
  involved.

Decision log: keep the chain as ordered unique provider ids with the first
entry primary; skip a provider only after three consecutive recorded failures;
give skipped providers one retry opportunity when their last failure is at
least 15 minutes old; treat all-cooling chains as an explicit bounded
`exhausted` state rather than silently picking a failing provider. Fail closed
on any malformed candidate, unknown current id, or non-finite time. A future
consumer must own persistence of the health state and pass caller-owned time;
this unit intentionally adds no storage, timer, or request path.

Known risks: ESPN remains an undocumented API; the policy cannot distinguish
provider outage classes and treats all failures uniformly until wired; the
cooldown/threshold values are deliberate product constants, not settings; and
runtime fallback behavior is intentionally unverified because the policy has
no consumer yet.

No push, tag, release, or Marketplace action occurred. The unrelated absence
of `MARKETPLACE_SUBMISSION.md` remains untouched and unstaged.

Next bounded unit: wire the accepted `ProviderFallbackPolicy` contract into the
existing per-league fetch boundary (`services/LeagueFetch.qml` and the shared
scheduler) without changing endpoints, request paths, polling cadence bounds,
settings schema, or QML views.

## Latest handoff — 2026-08-24 wired provider-fallback chain admission

The provider-fallback wiring unit is complete in the current worktree. Each
per-league score request is now admitted through its caller-owned fallback
chain, closing out the last unimplemented capability of the recorded minimum
competitive baseline.

Evidence:

- `providers/LeagueCatalog.js` adds `providerChain(leagueId)`: every catalog
  league resolves to one verified candidate (`nhl` → `["nhl"]`, all ESPN-backed
  leagues → `["espn"]`), and unknown leagues return `null`. Provider identity
  stays inside `providers/`.
- `services/LeagueFetch.qml` owns `providerHealth`, `activeProviderId`, and
  `requestProviderId`. `admitProviderRequest(nowMs)` evaluates
  `ProviderFallbackPolicy.evaluate` before every score request; an empty active
  id omits `currentProviderId` entirely because the policy fails closed on an
  explicit empty string. `buildScoreUrl(providerId)`/`parseBody` branch on the
  admitted provider id, so provider parsing stays in the adapters.
- Failed responses (`fail()`, partial-data) record through the pure
  `recordFailure`; full successes clear entries through `recordSuccess`.
  `exhausted` results keep the last-good snapshot visible, mark the existing
  unavailable/stale presentation, and schedule one cooldown-bounded retry via
  `blockForProviderCooldown`/`cooldownRetryDelayMs` (clamped to the existing
  `PollPolicy.RETRY_MAX_INTERVAL_MS`) instead of issuing another failing
  request. Invalid chains fail closed to the existing configuration path.
  The lookahead route is intentionally unchanged; it uses the same verified
  provider and has its own bounded cache/retry behavior.
- `fixtures/provider-fallback/wiring.json` and five deterministic tests cover
  the production chain catalog, healthy primary/current retention, the exact
  wired call order for fallback after three recorded failures on a sanitized
  two-candidate chain, exhausted isolation beside a healthy sibling with
  cooldown-expiry recovery, and source assertions proving no new Process,
  timer, curl use, or JSON parsing entered `LeagueFetch`. The suite passes
  with 210 tests.
- `tests/run-js-tests.sh`, `git diff --check`, `omarchy plugin validate
  "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files pass; lint exits 0 with the
  established standalone import/unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into one instance
  (`rtdjemiakt`, PID 904383); `shell ping` returned `ok`; toggle/hide IPC
  exited 0; and the fresh log shows normal multi-league initialization, fetch,
  and cache activity with no Sportray exception, QML load failure,
  binding-loop warning, or provider-cooldown noise. Only the pre-existing
  unrelated portal registration warning remains.

Decision log: keep health state as caller-owned in-memory state — it is not a
settings field and does not survive restarts, matching the policy's pure
contract. Production chains are single-candidate today because each league has
exactly one verified adapter; exhaustion therefore means the league's one
provider is cooling down, which preserves the documented last-good/isolation
behavior while making multi-provider chains available without further wiring.
Cooldown retries reuse the existing scheduler retry signal rather than adding
a timer or changing documented polling cadence bounds.

Known risks: live multi-provider fallback is intentionally unexercised because
no league currently ships a second verified adapter; ESPN remains an
undocumented API; and a manual refresh during an active cooldown stays blocked
until the cooldown expires. No push, tag, release, Marketplace, or remote
action occurred. The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains
untouched.

Next bounded unit: with all five recorded baseline capabilities now
implemented, perform one read-only consistency audit across `README.md`,
`roadmap.md` acceptance evidence, and the private competition backlog;
record which recorded gaps are closed and present the remaining candidate
product slices for owner direction before implementing any new feature work.

## Latest handoff — 2026-08-24 post-baseline consistency audit and owner decision list

Status: complete as a read-only audit. No feature, source, or runtime
behavior changed.

Audit outcome:

- Every README behavior claim added during the baseline slices was checked
  against current sources and recorded acceptance evidence: standings on
  ESPN-backed and NHL destinations (`services/StandingsFetch.qml`,
  `providers/NhlProvider.js`), bounded detail drill-down with optional
  outcome/per-period lines (`components/GameDetailView.qml`,
  `model/GameDetailModel.js`), calendar view plus favorites filter
  (`model/CalendarModel.js`, `KeyboardRoutingPolicy.calendarFilterAction`),
  icon-only ambient bar with status dots and hover details
  (`BarWidget.qml`, `model/BarPresentation.js`), notification preferences
  including pregame reminders and close-game alerts
  (`model/SettingsModel.js`, `model/PregameReminderPolicy.js`,
  `model/CloseGamePolicy.js`), response bounds (2 MiB / streamed admission /
  256 events in `model/ResponsePolicy.js`), and wired per-league provider
  fallback chains (`providers/LeagueCatalog.providerChain`,
  `services/LeagueFetch.qml`). No contradictory wording was found, so no
  README edit was required.
- `competition.md` backlog reconciled: P0-2 standings coverage closed,
  P0-3 alert depth closed, P0-1 rich detail partially closed (outcome +
  lines shipped; scoring plays/leaders/situation open), P1-4 provider
  fallback wiring closed with live multi-provider open pending a second
  verified adapter, P1-6 calendar largely closed (date jumps/local-time
  choices open), P1-5 discovery and all P2 specialist items open.
- The old "Recommended next slices" section (NHL standings, first rich-detail
  section, pregame reminder) is fully delivered; it was replaced with an
  owner-facing decision list: broader team discovery; a second verified
  provider adapter for live multi-provider fallback; richer detail sections;
  calendar extensions; broadcast/event links; and separate owner-controlled
  release/publication follow-ups for the unreleased `rc.8` candidate.

Evidence — gates rerun to record the unchanged baseline:
`tests/run-js-tests.sh` passes with 210 deterministic tests;
`./tests/test-summon-helper.sh` passes; `omarchy plugin validate "$PWD"`
passes on actual Omarchy; real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
exits 0 with the established standalone import/unqualified-access warnings;
and `git diff --check` passes. This documentation-only audit makes no new
shell rescan or fresh-log claim because no runtime-behavior claim changed.

The checkout intentionally has no `docs/upstream-contract.md`; no host
boundary claim required new installed-source inspection beyond prior verified
evidence. The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains
untouched and unstaged. No push, tag, release, Marketplace, or remote action
occurred.

Known risks unchanged: ESPN remains an undocumented API; live multi-provider
fallback cannot be exercised until a second verified adapter exists; release
metadata/tagging remain owner-controlled.

Next bounded unit: blocked pending an explicit owner selection from the
candidate decision list recorded in `competition.md`. If the owner selects a
slice, implement that single bounded vertical slice under the existing
guardrails; if no direction is given, do not infer one and stop after
recording the still-pending decision.

## Latest handoff — 2026-08-24 team-statistics rich-detail projection

Status: complete. The third optional rich-detail section is implemented as a
bounded provider-neutral projection. `model/GameDetailModel.js` now exposes an
optional `stats` record — `{away: [{key, label, value}...], home: [...]}` or
`null` — projected from the already fetched ESPN scoreboard snapshot without a
new endpoint, without touching `GameModel`'s normalized shape, and without a
new settings schema.

Evidence:

- On 2026-08-24 the live MLB scoreboard response was inspected directly and
  confirmed to carry top-level numeric competitor `hits` and `errors` fields
  (NFL competitors carry `records`/`statistics`, intentionally not extracted in
  this unit). No second fetch is required.
- `GameDetailModel` bounds each side at `MAX_STAT_ROWS = 8` entries, keys at
  32 lowercase-slug characters, labels at 24 characters, and values at the
  existing 9,999 bound; duplicate keys, key/label-shape violations, over-bound
  values, side-length mismatches, and pairwise key mismatches fail closed to
  `stats: null`. `emptyDetail` carries `stats: null`.
- `providers/EspnProvider.js` extracts `hits`/`errors` from the same payload
  inside `parseGameDetailResponse` only, keyed by provider game ID with the
  fixed neutral label table (`Hits`/`Errors`), and merges them into the detail
  candidate before normalization. `parseScoreboardResponse`, the normalized
  game shape, polling, and all other consumers are unchanged.
- `components/GameDetailView.qml` renders a bounded `TEAM STATS` table
  (label, away, home columns) with the same neutral `—` placeholder convention
  when the projection is null. No routing, cursor, source-action, or panel
  state changed.
- `fixtures/espn/raw/game-detail-stats.json` covers valid rows, a partial
  single-key projection, malformed value rejection, over-bound rejection, and
  missing fields. One new deterministic test asserts accepted projections,
  every rejected case as `null`, the new bounds, and the absence of raw
  provider fields; the route fixture and view-source assertions now cover the
  `TEAM STATS` placeholder. The complete suite passes with 211 tests.
- `./tests/test-summon-helper.sh`, `git diff --check`, `omarchy plugin
  validate "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all QML files pass; lint exits 0 with the
  established standalone import/unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported `omarchy restart
  shell` loaded the linked checkout into one instance (PID 911404); shell ping
  returned `ok`, the summon helper returned `ok`, and the plugin is enabled.
  Keyboard exercise: Down/Return opened the rendered `Game details` view for
  `mlb:401816655` (BOS @ MIA, scheduled) showing participants, status, timing,
  venue, `Outcome —`, `SCORING BY PERIOD —`, and the new `TEAM STATS` section
  with its neutral `—` placeholder; Escape returned to the scores route and the
  hide route completed. Populated stats rows were not exercised at runtime
  because today's slate had not started (4:40 PM first pitch); the populated
  path is covered by the fixture-driven suite, matching the earlier per-period
  lines precedent. The fresh log contains normal Sportray provider/cache
  activity (47 lines) and no Sportray exception, QML load failure, or
  binding-loop warning; only the pre-existing unrelated portal registration
  warning remains.

Decision log: keep team statistics strictly a detail-section concept fed from
the already fetched scoreboard snapshot; do not add fields to every normalized
game. Extract only the two verified numeric fields with fixed neutral labels;
season aggregates (`statistics`) and record summaries (`records`) remain
unverified for this boundary and are not projected. Fail closed per side so a
partially valid table never renders invented rows. The detail view stays a
presentation-only projection with no second endpoint.

Known risks: ESPN is an undocumented site API; hits/errors presence varies by
league and state (pre-event slates carry none, which projects `null`), and NHL
detail remains sparse. Scoring plays, leaders, and situation data remain open
P0-1 remainder items requiring their own verified-field review.

Boundary note: `docs/upstream-contract.md` remains intentionally absent. The
installed Omarchy/Quickshell shell restart, summon, and import-path contracts
were used as verified. No push, tag, release, or Marketplace action occurred.
The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains untouched and
unstaged.

Next bounded unit: implement broader team discovery (P1-5) as one bounded
vertical slice — cross-league team search in the favorite picker through
bounded static catalogs or a verified request path with canonical
`<league>:<providerTeamId>` identity, reusing the existing picker UI and
settings persistence without a schema change. Stop before any second-provider
adapter, calendar extension, broadcast links, packaging, tagging, pushing,
release, or Marketplace work.

## Latest handoff — 2026-08-24 broader team discovery complete

The P1-5 broader team discovery unit is complete in the current worktree and
its atomic commit. Cross-league discovery in the existing favorite picker now
matches league display names, ranks direct hits above broader matches, and
stays explicitly bounded, all in the pure picker model with the existing
bounded static catalogs. No new endpoint, provider adapter, settings schema,
or persistence change was made.

Evidence:

- `model/TeamPickerModel.js` gains `MAX_QUERY_LENGTH` (48) with query clamping
  in `normalizeQuery`, `MAX_RESULTS` (60) applied only to non-empty search
  results so unfiltered catalog browsing remains complete, league-name
  discovery through an optional `leagues` metadata argument (a query matching
  a league's `displayName`, `name`, or `id` admits that league's bounded
  catalog), and deterministic ranking tiers (exact abbreviation/id, then
  name/shortName prefix, then substring or league match) beneath the existing
  favorites-first ordering.
- `components/TeamPicker.qml` is the only consumer changed: it passes the
  already-propagated `leagues` metadata (`LeagueCatalog.listLeagues()` shape)
  into `filterAndOrderTeams`. Panel `buildPickerTeams`, SettingsHub, settings
  persistence, canonical `<league>:<providerTeamId>` identities, and schema-1
  behavior are unchanged.
- `fixtures/team-picker/discovery.json` plus two deterministic tests cover
  league-name cross-league discovery ("premier", "ncaa football"), narrowing
  under a specific league chip, no-discovery without metadata, ranked tier
  ordering, query clamping equivalence, the uncapped empty-query browse, the
  60-result search cap, and favorites surviving the cap at the top. The
  complete suite passes with 213 deterministic tests.
- `./tests/test-summon-helper.sh`, `git diff --check`, `omarchy plugin
  validate "$PWD"`, and real-import-path `/usr/lib/qt6/bin/qmllint -I
  /usr/share/omarchy/shell` over all 24 QML files pass; lint exits 0 with the
  established standalone import/unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy-restart-shell` loaded the linked checkout into one instance
  (PID 920442); shell ping returned `ok` and Sportray polling initialized
  normally. Real keyboard exercise: `n` opened Settings, Right/Return selected
  the `Favorite teams` tab, and typing `premier` in the search box rendered
  the Premier League catalog (Aston Villa, AFC Bournemouth, Arsenal,
  Brentford, Brighton) through league-name discovery; Escape closed the
  settings route and the panel. The fresh log contains normal Sportray
  provider/cache activity and no Sportray error, exception, or binding-loop
  warning; only the pre-existing unrelated portal registration warning
  remains.

Decision log: keep discovery entirely on the reviewed static catalogs; the
existing ESPN/NHL team-catalog endpoints remain refresh paths, not a new
request boundary, and no request is issued from the picker. League-name
matching is substring-based over the league's own bounded metadata, so a
query like "college" discovers both NCAA destinations. Search results are
capped at 60 only while a query is active so no static league catalog becomes
unreachable by browsing. Ranking is presentation-only and never reorders
persisted favorite identity.

Known risks: ESPN remains an undocumented API (unchanged); the cap means a
broad query can hide lower-ranked matches beyond 60 rows, which is the
deliberate bounded-discovery trade. A second verified provider adapter
(P1-4 remainder) still requires an explicit terms/region/reliability review.

Boundary note: `docs/upstream-contract.md` remains intentionally absent; the
installed Omarchy restart/summon/IPC and Quickshell import-path contracts
were used as verified. No push, tag, release, or Marketplace action occurred.
The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains untouched and
unstaged.

Next bounded unit: calendar extensions (P1-6 remainder) as one bounded
vertical slice — direct date jumps and/or explicit local-time rendering
choices within the existing cache-only calendar boundary, with no new fetch
ownership and no wider request window. Stop before broadcast/event links,
any second provider adapter, packaging, tagging, pushing, release, or
Marketplace work.

## Latest handoff — 2026-08-24 calendar extensions complete

The calendar-extensions unit (P1-6 remainder) is complete in the current
worktree: direct date jumps and explicit local-time rendering inside the
existing cache-only calendar boundary. No new fetch ownership, no wider
request window, and no provider parsing in QML.

Evidence:

- `model/CalendarModel.js` adds two pure helpers. `nextGamesDateKey(calendar,
  fromDateKey)` returns the first cached day strictly after the given date
  with games, skipping empty days and failing closed to `""` for malformed
  calendars, invalid dates, or no later cached games day. `localTimeLabel`
  renders the normalized `startTime` in the viewer's local timezone as a
  bounded `h:MM AM/PM local` label (max 24 characters) and fails closed to
  `""` for missing or malformed times. `gameRow` now carries that label as
  `timeLabel`; day-list row identity, ordering, bounds, and the row
  vocabulary are unchanged.
- `model/KeyboardRoutingPolicy.js` adds the pure `calendarJumpAction`:
  only `g`/`G` with the calendar open and settings/detail closed returns
  `jump-to-next-games`; every other state fails closed to `none`.
- `Panel.qml` routes the catcher's text-key path through that policy into
  `jumpCalendarToNextGames()`, which jumps through the existing
  `selectDate` path only when the target is a valid cached calendar day.
  The game-row delegate passes `modelData.timeLabel` into the new
  `startTimeTextOverride` property; scoreboard rows without the field keep
  the existing computed local start text.
- `components/GameRow.qml` adds the optional bounded
  `startTimeTextOverride` property used by `detailLabel`; row geometry,
  routing, source action, and accessibility labels are unchanged apart
  from the label text.
- `fixtures/calendar/calendar.json` gains `nextGamesDateKeys` expectations
  and `fixtures/keyboard-routing/calendar-jump.json` covers accepted
  `g`/`G` cases plus closed-calendar, open-settings, open-detail,
  non-matching-key, and empty-key rejections. Three new deterministic
  tests cover the jump target (later-days-only, empty-day skipping,
  malformed-input rejection), bounded local-time labels with fail-closed
  empty results, and the fixture-driven keyboard route with source
  assertions. The complete suite passes with 216 deterministic tests.
- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass; lint exits 0 with the established standalone import and
  unqualified-access warnings. README documents `G` and the explicit
  local-time labels.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into one instance
  (PID 926785); `shell ping` returned `ok` and the summon helper returned
  `ok`. Real keyboard exercise: `C` opened the calendar rendering explicit
  local-time labels (`6:40 PM local`, `7:05 PM local`) on scheduled MLB
  rows; `]` moved one day (real `date-changed` fetches logged); `T`
  returned to today; and `G` jumped from today directly to the next cached
  day with games, logged as `cache-hit date-changed 2026-08-25` on every
  enabled league — no new requests. A second `G` attempt before the target
  day was cached correctly failed closed as a no-op. Escape closed the
  calendar and the panel. The fresh log contains normal Sportray
  provider/cache activity and no Sportray exception, QML load failure, or
  binding-loop warning; only the pre-existing unrelated portal
  registration warning remains.

Decision log: the jump target comes only from the already-composed
calendar state, so it can never select a date outside the five-date caches
or start a request; uncached later days read as "No games" and are skipped
until the user browses them, which is the deliberate cache-only trade. The
explicit "local" suffix removes ambiguity against the UTC default used by
provider timestamps while keeping one shared row component. The route
reuses the existing text-key policy pattern and the existing `selectDate`
path; no new cursor targets, settings fields, or interaction surfaces.

Known risks: the jump only reaches days already present in the bounded
caches, so a freshly opened panel cannot jump past un-browsed empty days;
the local-time label uses the viewer's timezone via local Date getters,
aligned with the existing `DateModel` boundary; pointer clicks remain
unexercised (keyboard was used). The remaining P1-6 item (any window wider
than the five-date caches) stays closed until a verified wider source
exists.

Boundary note: `docs/upstream-contract.md` remains intentionally absent;
the installed Omarchy restart/summon/IPC, `PanelKeyCatcher` text-key, and
Quickshell import-path contracts were inspected directly and no material
host-boundary deviation was found. The unrelated absence of
`MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No push, tag,
release, or Marketplace action occurred.

Next bounded unit: broadcast/event links (P2-8) as one bounded vertical
slice — safe attributable stream/VOD/event URLs where the provider already
supplies them in the fetched payloads, rendered alongside the labeled
source action. Stop before any second provider adapter, packaging, tagging,
pushing, release, or Marketplace work.

## Broadcast/event links slice (P2-8) — 2026-08-24

Status: complete. Where the already-fetched provider snapshot itself supplies
safe attributable pages, the game-details drill-down now renders at most two
labeled event links beside the existing guarded source action. No new
endpoint, request path, provider adapter, settings field, or upstream shell
API was introduced.

Evidence:

- Provider field shapes were verified against live payloads before accepting
  the parsing: the live NFL scoreboard carries
  `events[].competitions[].highlights[].links.web.href` (www.espn.com
  game-highlight video pages on completed games), and the live MLB scoreboard
  carries `events[].links[]` entries whose `rel` array contains `preview`
  (www.espn.com preview articles on scheduled games). NHL payloads carry
  station names only, never stream URLs, so NHL games gain no links.
- `providers/EspnProvider.js` adds a bounded `eventLinks` projection: at most
  one Highlights link (first highlight whose `links.web.href` passes the
  existing `safeGameUrl` HTTPS + espn.com host admission) and at most one
  Preview link (first event link whose `rel` contains `preview` and whose
  `href` passes the same admission). Links attach to the normalized game only
  when non-empty; the canonical game link and labeled source action are
  unchanged.
- `model/GameDetailModel.js` re-admits the provider links through
  `normalizeDetailLinks`: known labels only (`highlights`, `preview`), at
  most 2 entries, deduplicated by key, HTTPS-only, whitespace-free, at most
  2048 characters, malformed or unreviewed input fails closed to `[]`.
- `components/GameDetailView.qml` renders the admitted links as labeled
  `SemanticActionButton`s in the existing source row's trailing action group,
  after the guarded `SourceLinkButton`. Activation reuses the reviewed
  `omarchy-launch-browser` argument-array path with an explicit HTTPS guard;
  the detail cursor now spans Back, the source action (when available), and
  at most two extra links. Row geometry, panel height behavior, pointer
  routing, and accessibility labels are preserved.
- `fixtures/espn/raw/game-detail-links.json` and one new deterministic test
  cover highlights-only, preview-only, both, HTTP-rejected, and
  missing-link games, detail re-admission (dedupe, cap, length, scheme,
  whitespace, malformed rejection), plain-game empty links, and
  source-level QML assertions. The complete suite passes with 217
  deterministic tests.
- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass; lint exits 0 with the established standalone import and
  unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: `omarchy restart shell`
  loaded the linked checkout into one healthy instance; `shell ping` and the
  summon/toggle/hide IPC returned `ok`. Real keyboard exercise: the MLB tab
  was selected through arrow keys, the BOS@MIA detail (no provider links)
  rendered only the ESPN source action, and the TB@DET detail rendered the
  labeled Preview button beside it; arrow-key cursor movement focused the
  Preview button, and Return opened
  `https://www.espn.com/mlb/preview/_/gameId/401816657` through the guarded
  launcher. The fresh log contains normal provider/cache activity and no
  Sportray exception, QML load failure, or binding-loop warning; the
  pre-existing unrelated portal registration warning is unchanged.

Decision log: links are admitted only from the already-fetched scoreboard
snapshot with the same reviewed `safeGameUrl` host boundary as the existing
canonical game link, so no new request path or host is introduced. Two is
the hard link cap; unknown link kinds, duplicate keys, non-HTTPS hosts, and
oversized URLs fail closed. Broadcast streams remain out of scope because
neither provider payload supplies stream URLs — only station names.

Known risks: ESPN remains an undocumented API and link shapes may change;
rejected shapes simply render no extra links. Pointer activation of the new
buttons was not exercised (keyboard was used); the pointer path shares the
same guarded callback.

Boundary note: `docs/upstream-contract.md` remains intentionally absent;
the installed Omarchy launcher/IPC and Quickshell `execDetached` contracts
were rechecked and no material host-boundary deviation was found. The
absence of `MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No
push, tag, release, or Marketplace action occurred.

Next bounded unit: a second verified provider adapter for live
multi-provider fallback (P1-4 remainder) — gated on an explicit
terms/region/reliability review before any implementation; stop if the
review is absent.
