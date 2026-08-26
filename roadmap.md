# Sportray private roadmap

Last reviewed: 2026-08-25

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
- Settings remain bounded schema-2 JSON with canonical
  `<league>:<providerTeamId>` favorite identities.
- Future settings schemas remain opaque: Sportray uses safe schema-2 defaults
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

## Latest handoff — 2026-08-24 calendar week-strip overview

Status: complete. The owner-selected calendar redesign is implemented as one
bounded vertical slice. Calendar mode is now visually distinct from the home
scoreboard: a week-strip overview of the cached window with per-day game
counts and favorite highlights replaces the shared date carousel and sport
picker while the calendar is open, and only the selected day's games are
listed below it for drill-down.

Evidence:

- `model/CalendarModel.js` adds two pure helpers. `daySummaries(calendar,
  options)` projects bounded per-day overview records (`dateKey`, `label`,
  `weekday`, `month`, `dayOfMonth`, `gameCount`, `hasGames`,
  `leagueIds` capped at the new `MAX_LEAGUES_PER_DAY_SUMMARY` = 4,
  `hasFavoriteGames` read only from explicit annotated presentation flags,
  `isToday`, `isCenter`) and fails closed to `[]` for malformed input.
  `flattenDay(calendar, dateKey)` reuses the shared per-day row vocabulary
  (`appendDayRows`, refactored out of `flatten`) for one cached date and
  fails closed to no rows for unknown, outside-window, or malformed dates.
  `PanelPresentation` now exports its pure `annotate` for fixture use.
- `components/CalendarWeekStrip.qml` renders the summaries as one bounded
  cell per cached day (weekday/day, `N games`/`No games` count line, accent
  favorite dot, accent foreground for today, selected-state fill) with
  pointer, assistive, and keyboard-activatable buttons; the view performs no
  filtering, parsing, or date math.
- `Panel.qml` binds the strip to `calendarDaySummaries`, switches
  `displayRows` to `calendarDayRows` (`flattenDay`) while the calendar is
  open, hides the date carousel and tab strip in calendar mode, routes
  Left/Right arrows to `selectRelativeDate` while the calendar is open, and
  moves tab-strip focus out on calendar open (restored on close). The `C`,
  `F`, `G`, `[`/`]`, `T` shortcuts, favorites filter, Escape chain, detail
  drill-down, standings, settings, notification, ambient-bar, and polling
  behavior are unchanged.
- `fixtures/calendar/calendar.json` gains `weekStrip` and `selectedDayRows`
  expectations; two new deterministic tests cover the summaries (weekday/
  month/day parts, counts, league-dot cap, favorite flags from annotation
  only, unannotated compositions projecting no favorite marks, malformed
  rejection) and selected-day rows (vocabulary, identity, empty-day and
  outside-window fail-closed). The ownership test now asserts the new
  bindings, the mounted strip, and the arrow routing. The complete suite
  passes with 219 tests.
- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass; lint exits 0 with the established standalone import and
  unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into exactly one
  instance (PID 955389); `shell ping` returned `ok`, the plugin is enabled,
  and `debugBarGeometry` showed a live right-section Sportray slot. Real
  keyboard exercise with screenshots: summon opened the Today scores view;
  `C` opened the calendar rendering the Sat 22–Wed 26 strip (per-day counts,
  accent favorite dot on Mon 24, "Mon, Aug 24" selected-day list with live
  and scheduled rows, date carousel and sport picker hidden); Right re-
  centered the strip on Tue 25 with real date-changed fetches (15 games,
  favorite dot, "Show Today" appeared); Left returned to Mon 24; `f` flipped
  the header to "Favorites" and re-projected strip counts (Mon 24: 1 game,
  Tue 25: 1 game) and the favorite-only day list; Escape closed the calendar
  and a second Escape closed the panel. The fresh log for the current
  instance contains normal Sportray fetch/cache/polling activity (115 debug
  lines) and no Sportray error, exception, or binding-loop warning; the only
  warnings are the unrelated Hyprland xkbcomp keyboard noise. A pre-restart
  binding-loop warning in the retained journal history belongs to the older
  shell instance and predates this unit.

Not exercised: pointer clicks on strip cells (no reliable injector; the
keyboard and assistive route shares the same guarded `dateSelected` signal)
and `G` at runtime (today is the only cached day with games in this session,
so the jump correctly had no later target; the pure path is fixture-covered).

Decision log: the calendar's identity is density plus drill-down, so the
strip owns the window overview and the list owns only the selected day.
All aggregation stays in the pure model; the QML view renders pre-computed
summaries only. Replacing the shared date chrome in calendar mode makes the
route visually distinct without adding a second interaction surface, and
Left/Right day navigation preserves keyboard reachability now that the tab
strip is hidden. Favorite highlights come only from the existing annotation
boundary, so the strip can never disagree with the favorites filter. Stop
before wider windows, month grids, new fetch ownership, provider work,
packaging, tagging, pushing, release, or Marketplace work.

Known risks: the strip can only show dates present in the five-entry
per-league caches, so unbrowsed days read "No games" until visited; pointer
activation of strip cells remains unexercised; the panel-height chrome token
is a bounded estimate shared across modes. The unrelated absence of
`MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No push, tag,
release, or Marketplace action occurred.

Next bounded unit: with explicit owner direction, either revisit the
gated second verified provider adapter (P1-4 remainder, still requires an
owner-provided terms/region/reliability review) or select another slice
from the `competition.md` decision list. If no direction is given, do not
infer one and stop after recording the still-pending decision.

## Baseball situation rich-detail projection — 2026-08-24

Status: complete. The owner selected the richer-detail slice (P0-1 remainder /
P2-7) for this unit. One bounded sport-specific section — the baseball
situation — is now projected into the game-detail drill-down from the already
fetched ESPN scoreboard snapshot, with no second endpoint and no change to the
normalized game shape or runtime fetch wiring.

Evidence:

- On 2026-08-24 the live ESPN MLB scoreboard response was inspected directly
  and confirmed to carry `competitions[].situation` for in-progress games with
  `balls`, `strikes`, `outs`, `onFirst`, `onSecond`, `onThird`, and a
  `lastPlay.text` summary. The same inspection showed no
  `competitions[].details` scoring plays for the day's completed football
  games, so scoring plays remain unverified and open. Pitcher/batter athlete
  blocks exist but are intentionally not projected.
- `model/GameDetailModel.js` adds an optional `situation` record — counts
  bounded by `MAX_SITUATION_COUNT = 9`, strict boolean bases, optional
  `lastPlay` text capped by `MAX_SITUATION_TEXT_LENGTH = 160` — failing closed
  to `situation: null` for malformed, non-boolean, over-bound, or over-length
  input. `emptyDetail` carries `situation: null`.
- `providers/EspnProvider.js` extracts the situation from the same payload
  inside `parseGameDetailResponse` only (`competitionSituation`,
  `detailSituationByGameId`), truncating over-length last-play text at the
  model bound before normalization. `parseScoreboardResponse`, polling, and
  all other consumers are unchanged, matching the per-period-lines and
  team-stats precedent.
- `components/GameDetailView.qml` renders a `SITUATION` section (count, outs,
  three base-occupancy dots using the existing accent/`transparent` token
  convention, and an optional last-play line) that is visible only when the
  projection exists; a sport-specific section hides rather than rendering a
  permanent placeholder. The bases label exposes
  `situationAccessibleBases()` as its accessible name. No routing, cursor, or
  focusable changed.
- `fixtures/espn/raw/game-detail-situation.json` covers the populated live
  shape, a count-less situation, malformed count, non-boolean base, over-bound
  count, 200-character last play (truncated to 160 by the provider), and a
  missing situation. One new deterministic test asserts the accepted
  projection, every rejected case as `null`, the provider truncation, both new
  bounds, the absence of raw provider fields (`pitcher`, `athlete`), and the
  view-source bindings. The complete suite passes with 220 tests.
- `./tests/run-js-tests.sh` (220 tests), `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass; lint exits 0 with the established standalone import and
  unqualified-access warnings.
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0: the supported
  `omarchy restart shell` loaded the linked checkout into exactly one instance
  (PID 971959); `shell ping` returned `ok`. Real keyboard exercise with
  screenshots: summon opened the Today scores view; `c`/Escape calendar
  round-trip still works; Down/Space and a later Down/Return opened the game
  detail for `mlb:401816655` (BOS @ MIA, Live · Top 7th) rendering the existing
  sections with the new SITUATION section correctly hidden, because runtime
  detail games come from `parseScoreboardResponse`, which does not attach the
  optional detail records — the same documented runtime precedent as the
  populated lines/stats paths, which are fixture-verified. The fresh log
  contains normal Sportray fetch/cache/polling activity and no Sportray error,
  exception, or binding-loop warning (the only error-shaped lines are the
  pre-existing unrelated `xkbcomp` Hyprland keymap messages).

Decision log: keep the situation strictly a detail-section concept fed from
the already fetched scoreboard snapshot; do not add fields to every normalized
game and do not rewire `LeagueFetch` to `parseGameDetailResponse` in this
unit. Extract only the verified count/bases/last-play fields; pitcher/batter
athlete blocks, `dueUp`, and football `details`/`situation` remain unverified
or out of scope for this boundary. A sport-specific section hides when its
projection is null instead of occupying a permanent placeholder row. Counts
are bounded generously (≤9) so transient boundary values never reject an otherwise
valid live snapshot.

Known risks: ESPN is an undocumented site API; situation presence varies by
sport and state, and the populated section is fixture-verified rather than
runtime-observed (no runtime wiring carries detail records today — a known
cross-section follow-up, not a regression of this unit). Scoring plays
(`competitions[].details`) could not be verified live today because no
football game was in progress; they remain open behind a live verification.
The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains untouched and
unstaged. No push, tag, release, or Marketplace action occurred.

Next bounded unit: with explicit owner direction, either revisit the gated
second verified provider adapter (P1-4 remainder, still requires an
owner-provided terms/region/reliability review), pursue live verification of
scoring plays when a football game is in progress, or select another slice
from the `competition.md` decision list. If no direction is given, do not
infer one and stop after recording the still-pending decision.

## Scoring-play live verification — BLOCKED 2026-08-24

Status: blocked. The owner selected the live scoring-play verification unit
(P2-7 prerequisite). Its precondition — an ESPN football game in progress at
inspection time — was unmet during this session's inspection window, so the
verification did not occur and no adapter work was started.

Evidence:

- Inspection time 2026-08-25T00:58Z (Mon Aug 24, ~9:00 PM EDT).
  `https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard`
  returned 16 events, all `post`/`Final`/completed (preseason concluded with
  SEA @ TEN, 2026-08-24T00:00Z); zero events were `in`.
  `https://site.api.espn.com/apis/site/v2/sports/football/college-football/scoreboard`
  returned 25 events, all `pre`, beginning SJSU @ USC 2026-08-29T19:00Z;
  college football had not started.
- Completed-game scoreboard payloads again carried no
  `competitions[].details`: both today's default NFL window and the dated
  `?dates=20260823` window contain zero `details` arrays across all events,
  matching the 2026-08-24 daytime finding. This strengthens the hypothesis
  that `details` populates only while a game is live (or not at all on the
  scoreboard endpoint), but neither case is confirmed.
- No repository source files changed; this entry, the `competition.md` backlog
  note, and `NEXT_SESSION_PROMPT.md` are the only edits. No success commit is
  created for this unit.

Decision log: keep the verification strictly observational — direct reads of
the two documented football scoreboards only; no new endpoint, provider, or
fetch path was inspected beyond them. Retry windows: the next realistic
opportunities are CFB week-0 games from Sat Aug 29 onward and NFL week 1 from
Thu Sep 10 (2026 season), during actual game minutes.

Known risks: even during a live game, `competitions[].details` may never
appear on the scoreboard payload, which would close the scoring-plays idea
under the current single-endpoint boundary rather than open adapter work. The
unrelated absence of `MARKETPLACE_SUBMISSION.md` remains untouched and
unstaged. No push, tag, release, or Marketplace action occurred.

Next bounded unit: retry this verification during live football minutes
(CFB from Aug 29, NFL from Sep 10), or select another owner-directed slice
from the `competition.md` decision list. If no direction is given, do not
infer one and stop after recording the still-pending decision.

## Runtime detail wiring + sport-aware scoring labels — 2026-08-24

Status: complete. The owner selected the runtime detail-wiring slice (plus the
gated live-verification and second-provider candidates for later units). The
runtime scoreboard path and the fixture-verified detail path now produce the
same enriched normalized games, and the scoring header uses sport-aware period
nouns.

Evidence:

- `providers/EspnProvider.js` now attaches the bounded optional `lines`,
  `stats`, and `situation` records inside `parseScoreboardResponse` itself, and
  `parseGameDetailResponse` reuses those enriched games directly. Runtime
  league fetches therefore carry the same records the fixtures verified,
  without a second endpoint, provider payload exposure, or fetch-ownership
  change. Sparse games keep the hidden/placeholder state.
- The user reported that the detail scoring header said "period" for every
  sport. `model/Formatters.js` gains `scoringPeriodUnit` (MLB → Inning,
  NFL/CFB/NBA/NCAAM-BB → Quarter, soccer → Half, default/NHL → Period);
  `GameDetailView.qml` renders it from the game's league.
- New deterministic tests: a runtime/fixture parity test over all four detail
  fixtures (identical projected details and errors, no raw payload fields, no
  keys added to sparse games, LeagueFetch still parsing through
  `parseScoreboardResponse`), and a sport-aware unit-label test covering all
  eight leagues plus unknown/null input and the QML consumer. The route
  fixture now pins the sport-neutral "SCORING BY " prefix. The suite passes
  with 222 tests.
- All repository gates pass: `tests/run-js-tests.sh`,
  `tests/test-summon-helper.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
  with the established standalone warnings.
- Runtime verification on actual Omarchy: `omarchy-shell shell rescanPlugins`
  did NOT reload the linked plugin's singleton fetch service (cache-hit lines
  appeared immediately after the rescan and the old code kept running), so the
  shell was fully restarted with `omarchy-restart-shell`. The fresh instance
  initialized all leagues with cold fetches, one Quickshell instance remained
  running, and shell ping returned `ok`. Through the real input path (panel
  toggle plus keyboard Down/Return), the live MLB game's drill-down rendered
  the previously hidden sections from runtime data: SITUATION (count, outs,
  bases, last play) and TEAM STATS (hits/errors), while SCORING BY INNING
  replaced the generic header and the lines table kept its safe placeholder
  because the mid-inning sides had unequal lengths (the documented admission
  rule). Escape closed the detail route and the panel toggle restored the bar.
  The fresh log showed normal fetch/polling activity with no new Sportray
  error, exception, or binding-loop warning during this exercise.

Decision log: enrich at the provider parse boundary rather than passing raw
payloads toward QML, keeping provider parsing in `providers/` and the detail
projection in `GameDetailModel`. Reuse one parse path so fixture coverage and
runtime behavior cannot diverge again. The unequal-side mid-inning lines case
stays null by the existing bounded rule rather than being padded.

New known risk (pre-existing, recorded for a future unit): the installed shell
logs a `NotificationService`/`SportrayService.qml:68` `games` binding-loop
warning on the `enabled-leagues-changed` path (observed 2026-08-24 20:45,
20:57, and 21:24 EDT on the pre-restart instance). It did not appear in fresh
startup logs or during this unit's detail-route exercise. This unit did not
introduce or change that binding; a future bounded unit should diagnose and
remove the loop without changing notification ownership.

Two atomic commits were created: `3bdee00` (runtime detail projection) and
`4fa30b5` (sport-aware scoring labels). No push, tag, release, or Marketplace
action was performed. The live scoring-play verification (CFB week 0 from
Aug 29) and the second verified provider adapter (requires the owner's
terms/region/reliability review) remain gated owner-directed candidates.

Next bounded unit: diagnose and remove the recorded `NotificationService`
`games` binding loop on the `enabled-leagues-changed` path while preserving
notification ownership, dedupe, and settings behavior; stop before any
provider, publication, or unrelated interaction work.

## Latest handoff — 2026-08-25 notification games binding-loop fix

Status: complete. The recorded `NotificationService` `games` binding loop on
the `enabled-leagues-changed` path is diagnosed from source and removed at the
smallest boundary, with notification ownership, dedupe fingerprints, schema-1
settings, and the `MonitorOwnership` singleton topology unchanged.

Diagnosis (confirmed from source before editing):

- `SportrayService.qml` binds `NotificationService.games` to
  `fetchService.games` on the today path. `FetchService.updateAggregateState()`
  assigns a fresh `games` array on every `enabledLeaguesChanged` notification.
- `NotificationService.handleGamesChanged()` runs synchronously on that
  change; when transitions are detected it calls
  `SettingsStore.acceptTransitionEvents`, which calls `writeState`.
- `writeState` unconditionally reassigned `root.settings` with a brand-new
  object even when only the transition-dedupe state changed, so the
  `FetchService.enabledLeagues`/`favoriteTeamIds` bindings re-fired
  synchronously inside the still-active `games` binding notification stack,
  re-entering `updateAggregateState()` and recursively re-evaluating the same
  `games` binding — the exact warning Qt logged at `SportrayService.qml:68`.

Fix: `SettingsStore.writeState` now skips the `root.settings` reassignment
when the candidate already is the current normalized settings object
(identity guard). UI toggles and state loads pass fresh candidates and keep
full normalization; the dedupe-write path no longer re-notifies the fetch
bindings, and the persisted dedupe file write is unchanged. Notification text,
fingerprints, favorite gating, first-fetch silence, and polling cadence are
unchanged; the singleton still owns exactly one settings/fetch/notification
graph (pinned by the existing ownership tests).

Deterministic coverage: `fixtures/settings-boundary/binding-loop.json` plus a
new test assert the identity guard, both write paths, the unchanged
`SportrayService` games binding and singleton topology, and the unchanged
FetchService aggregation entry points. The suite passes with 223 tests.

Runtime verification on actual Omarchy 4.0.0-1 with Quickshell 0.3.0:
`omarchy-restart-shell` loaded the linked checkout into exactly one instance
(PID 1000776); `shell ping` returned `ok`. The exact recorded repro path — an
enabled-league change while games were loaded — was exercised repeatedly
(keyboard NHL toggle off at 2026-08-24 22:28 EDT with live MLB games, a
favorite change at 08:30, and the NHL re-enable at 08:32 EDT via the watched
state-file reload). The full fresh-instance log contains zero binding-loop
warnings; the only warnings were transient league `unavailable` retries on
the existing isolated recovery path, which recovered by cache-hit.

Honest exercise notes: the blind keyboard sequence partially misfired — one
stray Return briefly unfavorited Aston Villa (owner noticed, manually
restored it to six favorites) and NHL remained disabled after the first
attempt, so it was re-enabled through a direct schema-1 state-file edit that
the running store reloaded through its supported `watchChanges` path (itself
an `enabled-leagues-changed` under load). Final persisted state matches the
owner's intended configuration: six leagues enabled, six favorites, all
notification preferences unchanged. No state data was lost.

Gates: `./tests/run-js-tests.sh` (223 tests), `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file all
pass with the established standalone import/unqualified-access warnings.

Decision log: break the cycle at the settings-write boundary rather than
deferring the notification handler or changing the `games` binding, because
the reassignment was the only synchronous write back into the fetch graph.
An identity guard is sufficient because settings objects are treated
immutably everywhere (`SettingsModel` functions return new objects); the
guard can never skip a real content change. Do not "fix" this by disabling
the warning, weakening notification gates, or adding timers/deferrals.

Known risks: the identity guard relies on the immutable-settings convention;
a future mutation of `root.settings` in place would silently skip
reassignment, so the new source assertion pins the guard. The binding loop
could only fire when a transition event was actually accepted, so long-run
absence of the warning is corroborating, not primary, evidence — the source
diagnosis and deterministic coverage are primary. `competition.md` has no
backlog line for this reliability fix, so that file is unchanged.

No push, tag, release, or Marketplace action occurred. The unrelated absence
of `MARKETPLACE_SUBMISSION.md` remains untouched and unstaged.

Next bounded unit: retry the blocked scoring-play live verification
(`competitions[].details`) during real football minutes — CFB week 0 begins
Sat Aug 29, NFL week 1 from Thu Sep 10 — strictly observationally as before.
Outside live minutes, or if the owner directs otherwise, select a slice from
the `competition.md` decision list instead; do not infer direction.

## Latest handoff — 2026-08-25 betting-odds context projection

Status: complete. The owner deferred the scoring-play live verification
(outside football minutes) and directed this slice from the decision list:
surface verified provider-supplied context the scoreboard payloads already
carry instead of discarding it. One bounded provider-neutral `odds` record is
now projected from the already fetched ESPN scoreboard snapshot onto the
score card and the game-details drill-down, with no second endpoint.

Verified provider fields (observed directly on 2026-08-25 before any edit):

- `competitions[].odds[0]` exists on `pre` games across CFB and NFL (and the
  live Aug 29 MLS slate at runtime): `details` (for example `USC -38.5`,
  `CLB -110`), numeric `overUnder`, and `provider.name` (DraftKings). The
  deep `moneyline`/`pointSpread`/`total` objects contain draftkings.com
  bet-slip deep links and are intentionally not projected; no sportsbook
  link or disclaimer text enters the projection, and the bookmaker name is
  kept as attribution.
- `competitions[].weather` was absent from every payload inspected today
  (CFB, NFL now, NFL week-1 dated, MLB, EPL). Weather therefore stays
  unverified and out of the projection; retry the observation during the
  live-football window when NFL games approach kickoff.
- `competitions[].leaders` exists but carried zero athlete entries in every
  inspected payload (MLB `MLBRating` groups, NFL `passingYards` groups on
  completed games), so leaders remain unverified and open.

Evidence:

- `model/GameDetailModel.js` adds an optional `odds` record —
  `{details: string ≤ 48, overUnder: finite number with |value| ≤ 999 or
  null, provider: string ≤ 32}` — failing closed to `odds: null` for missing
  details/provider, over-length text, or non-finite/over-bound over-under.
  `emptyDetail` carries `odds: null`.
- `providers/EspnProvider.js` extracts the first odds entry per competition
  inside `parseScoreboardResponse` only (`competitionOdds`,
  `detailOddsByGameId`), truncating over-length details/provider at the model
  bounds and requiring the bookmaker attribution, then attaches the record to
  the enriched normalized game like the existing lines/stats/situation
  records. `parseGameDetailResponse` re-admits it through
  `GameDetailModel.normalizeOdds`; sparse games gain no `odds` key.
- `components/GameDetailView.qml` renders a bounded `ODDS` section
  (`details · O/U <total> — <provider>`) that hides when the projection is
  null, following the situation-section precedent. `components/GameRow.qml`
  appends the bounded `details` text to scheduled score cards' status line
  (for example `SCHEDULED · Aug 29, 7:30 PM · CLB -110`); no row geometry,
  routing, source-action, or accessibility behavior changed beyond the label
  text.
- `fixtures/espn/raw/game-detail-odds.json` covers the attributed projection
  with raw junk fields present, missing-provider rejection, malformed
  over-under demotion to null, over-length truncation, and missing odds. The
  new deterministic test asserts the projections, every bound, raw-field
  exclusion (`moneyline`, `pointSpread`, `awayTeamOdds`, `disclaimer`,
  `sportsbook`), runtime attachment, and the QML view/row bindings; the
  runtime/fixture parity test now includes the odds fixture and sparse games
  are pinned to gain no `odds` key. The suite passes with 224 tests.
- `./tests/run-js-tests.sh` (224 tests), `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass with the established standalone warnings.
- Runtime verification on actual Omarchy 4.0.0-1 with Quickshell 0.3.0:
  `omarchy-restart-shell` loaded the linked checkout into exactly one
  instance (PID 1023762); `shell ping` returned `ok`. Through the real
  keyboard path, the Aug 29 slate rendered attributed odds on the scheduled
  score cards (`CLB -110`, `CHI +120`, `LAFC +100`, `MIA -250`,
  `ATL +130`) and the `usa.1:761758` drill-down rendered the new ODDS
  section as `CLB -110 · O/U 2.5 — DraftKings`. Escape, `T` (today), and
  panel close completed the route. The fresh log contains normal provider
  fetch activity, zero binding-loop warnings, and no Sportray error or
  exception; only the pre-existing unrelated portal registration warning
  remains. The owner's league/favorite/notification configuration was not
  changed during verification.

Decision log: odds are a context projection from the already fetched
snapshot — never a field every normalized game must carry, never a betting
link, and never unattributed. The bookmaker name is required precisely so
the line is attributable; deep sportsbook links stay out because their hosts
are unreviewed and bet-slip activation is not Sportray's surface. Weather
and leaders remain unverified observations for a future live-minutes unit,
not assumptions.

Known risks: ESPN is an undocumented API and odds presence/shape varies by
league and state (post and sparse slates carry none, which hides the
section); odds can go stale between polling refreshes like any snapshot
field; the card line is elided at narrow widths by the existing bounded
footer. The unrelated absence of `MARKETPLACE_SUBMISSION.md` remains
untouched and unstaged. No push, tag, release, or Marketplace action
occurred.

Next bounded unit: during the live-football window (CFB week 0 from Sat
Aug 29; NFL week 1 from Thu Sep 10), perform one combined observational
verification: `competitions[].details` (scoring plays) and
`competitions[].weather` presence/shape, plus `leaders` if any payload
carries athlete entries. Outside live minutes, or on owner direction,
select another `competition.md` decision-list slice instead; do not infer
direction.

## Latest handoff — 2026-08-25 game-detail bounds and ID removal

Status: complete. The owner reported two game-details defects after the odds
slice: the detail content overflowed the panel's bottom boundary, and
internal game IDs (`usa.1:761758`, `#761758`) were visible to end users.
Both are fixed in one bounded presentation unit; no provider, model,
settings, polling, or routing behavior changed.

Evidence:

- `components/GameDetailView.qml` no longer renders `detail.id` or
  `providerGameId` anywhere: the card's internal-ID row is removed and the
  header title is now the human matchup (`AWAY at HOME`) above the existing
  league·source subtitle. This restores the earlier "do not expose internal
  canonical IDs in a presentation surface" decision that the drill-down
  remount had regressed.
- The detail content is now hosted in a clipped `Flickable`
  (`contentHeight: detailColumn.implicitHeight`, vertical-only, interactive
  only when content exceeds the available height, `ScrollBar.AsNeeded`
  following the settings `utilityScroll` pattern), so the bounded panel
  height (320–600) can never be overflowed — taller content scrolls instead.
  Cursor movement scrolls the focused Back/source/link target into view via
  a bounded `ensureVisible` clamp, `resetCursor` returns to the top, and
  wheel scrolling follows the Flickable. The panel's height request still
  uses the full `implicitHeight` clamped to the same bounds.
- A new deterministic test asserts the ID removal (no `root.detail.id`, no
  `gameIdLabel`, zero `providerGameId` renders, matchup header), the
  Flickable/clip/interactive/scrollbar boundary, `ensureVisible`, and the
  reset-to-top behavior. The suite passes with 225 tests.
- `./tests/run-js-tests.sh` (225 tests), `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass with the established standalone warnings.
- Runtime verification on actual Omarchy 4.0.0-1 with Quickshell 0.3.0:
  `omarchy-restart-shell` loaded the linked checkout into exactly one
  instance (PID 1034334); `shell ping` returned `ok`. Through the real
  keyboard path, the NFL Aug 29 slate's drill-down (`nfl` DET @ IND)
  rendered `Back · GAME DETAILS / DET at IND / NFL · ESPN` with no internal
  IDs, the content clipped exactly at the panel's bottom boundary, and
  Down-scroll brought the bottom content into view inside the panel: TEAM
  STATS, `ODDS — IND -3.5 · O/U 35.5 — DraftKings`, and the focused ESPN
  source action. Escape, `T`, and panel close completed the route. The fresh
  log has normal provider activity, zero binding-loop warnings, and no
  Sportray error or exception; only the pre-existing unrelated portal
  registration warning remains.

Decision log: fix the overflow by making the content scroll within the
existing bounded height rather than raising the bound, because the owner
asked for content that fits with scrolling; the settings surface already
uses the identical Flickable pattern. Keep the matchup as the header title
and drop both ID renderings; canonical/provider IDs remain internal model
identity only. Cursor-follow scrolling keeps the keyboard route usable
without a pointer.

Known risks: very dense live games (situation + lines + stats + odds) will
require scrolling on small panels, which is the intended bounded trade; the
pointer wheel path shares the same Flickable and was not separately
exercised (keyboard was used). The unrelated absence of
`MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No push, tag,
release, or Marketplace action occurred.

## Latest handoff — 2026-08-25 viewport-fraction detail height

Status: complete. The owner asked whether the details pane needs a fixed
window height and requested a variable height up to 50% of the screen
viewport. The drill-down now sizes to its content but caps at half the
panel's real screen height, with the existing scroll behavior absorbing the
difference. No provider, model, notification, or routing behavior changed.

Boundary note: the installed Omarchy `KeyboardPanel` (a Quickshell
`PanelWindow`) already hard-fits panel content to the real screen via
`fittedContentHeight`/`availableCardHeight`, so a plugin panel can never
exceed usable screen space regardless of its request. The plugin-side fixed
600px detail cap was therefore a presentation preference, not an overflow
risk; on the owner's scaled display it consumed most of the viewport, which
prompted this change. Best practice applied: content-sized, viewport-
fraction cap, host fit-to-screen as the final boundary.

Evidence:

- `model/PanelLayout.js` adds the pure `detailContentRequest(contentHeight,
  viewportHeight, tokens)` policy: the request is the content height clamped
  to the 320px minimum and a cap of `min(fixedCap 600, floor(viewport ×
  0.5))`; the minimum floor wins over a smaller fraction (the host still
  hard-fits), and invalid/missing viewport input fails closed to the fixed
  cap. `Panel.qml` feeds it `gameDetailView.implicitHeight` and
  `panel.screen.height` from the installed `KeyboardPanel` window.
- A new deterministic test covers content-sized, minimum-floor, fixed-cap,
  viewport-capped, missing/invalid-viewport, and tiny-viewport cases plus
  the Panel wiring. The suite passes with 226 tests.
- `./tests/run-js-tests.sh` (226 tests), `./tests/test-summon-helper.sh`,
  `git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
  `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over all QML files
  pass with the established standalone warnings.
- Runtime verification on actual Omarchy 4.0.0-1 with Quickshell 0.3.0:
  `omarchy-restart-shell` loaded the linked checkout into exactly one
  instance (PID 1051121); `shell ping` returned `ok`. Through the real
  keyboard path, the MLB Aug 29 `BOS at NYY` drill-down opened at roughly
  half the viewport height with the content clipped at the panel boundary,
  and keyboard Down-scroll brought the bottom (TEAM STATS, source action)
  into view inside the pane. Escape, `T`, and panel close completed the
  route. The fresh log has normal provider activity, zero binding-loop
  warnings, and no Sportray error or exception; only the pre-existing
  unrelated portal registration warning remains.

Decision log: cap the detail at 50% of the panel's own screen rather than
replacing the general 640px scores cap, because the owner asked about the
details pane specifically and the scores view is already content-sized and
runtime-accepted. Keep the 320px minimum floor so sparse details remain a
usable panel, and keep the host's fit-to-screen contract as the final
boundary rather than duplicating screen math. The pre-existing duplicated
status word in the detail status line (`Scheduled · Scheduled`) remains a
known cosmetic issue, unchanged by this unit.

Known risks: `panel.screen.height` is read when the height request is
recalculated, so a panel moved between screens mid-open keeps the previous
screen's cap until the next recalculation; multi-monitor detail use remains
otherwise unchanged. The unrelated absence of `MARKETPLACE_SUBMISSION.md`
remains untouched and unstaged. No push, tag, release, or Marketplace
action occurred.

Next bounded unit: during the live-football window (CFB week 0 from Sat
Aug 29; NFL week 1 from Thu Sep 10), perform one combined observational
verification: `competitions[].details` (scoring plays) and
`competitions[].weather` presence/shape, plus `leaders` if any payload
carries athlete entries. Outside live minutes, or on owner direction,
select another `competition.md` decision-list slice instead; do not infer
direction.

## Second-provider candidate reconnaissance — 2026-08-25

Status: complete as a read-only reconnaissance unit. The owner selected the
P1-4 provider reconnaissance slice (outside live-football minutes). No
Sportray production source changed; `providerChain()` still has exactly one
candidate per league. This entry records the owner-review evidence that
gates any later second-adapter work.

Candidate A — MLB StatsAPI
(`https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=YYYY-MM-DD&hydrate=team,linescore`):

- Verified live 2026-08-25: 15 MLB games today (all `Preview`), and the
  2026-08-24 slate (all `Final`) carries `teams.away/home.score` plus a
  `linescore` with `currentInningOrdinal`, `inningState`, and per-side
  `runs`. Bounded shape: `dates[].games[]` entries carry `gamePk`, ISO-8601
  UTC `gameDate`, `status.{abstractGameState, detailedState,
  codedGameState, startTimeTBD}`, `teams.away/home.{team.{id, name,
  abbreviation}, score}`, `venue.name`, and the optional `linescore` — a
  clean match for the normalized `GameModel` contract and the existing
  bounded parse pattern.
- Transport/reliability: plain unauthenticated GET with no key or
  User-Agent requirement, open CORS, ~47 KB JSON for a 15-game day (far
  under the 2 MiB admission bound), Fastly CDN with `cache-control:
  max-age=20, public, stale-while-revalidate=30, stale-if-error=86400` — a
  bounded-polling tolerance signal stronger than ESPN's `max-age=1`. No
  rate-limit headers are published; community guidance is cache and backoff.
- Terms (the gate): every payload embeds a copyright pointer to
  `gdx.mlb.com/components/copyright.txt` — "Only individual, non-commercial,
  non-bulk use of the Materials is permitted and any other use of the
  Materials is prohibited without prior written authorization from MLBAM."
  The general MLB.com terms (last updated 2025-03-11) permit personal
  non-commercial single-copy use and prohibit redistribution/derivative
  works without written permission; the API is officially undocumented and
  partner-gated. Whether a personal, no-account, attribution-preserving bar
  widget making roughly one request per bounded polling cadence fits
  "individual, non-commercial, non-bulk use" is an owner legal
  determination, not an engineering one.
- Identity: MLB StatsAPI team ids differ from ESPN ids (Tigers 116 vs 3), so
  canonical `mlb:<providerTeamId>` favorites would change identity on a
  provider switch unless the adapter translates; both payloads carry team
  abbreviations (`TB`, `DET`) usable as a join key against the existing
  `EspnTeamCatalog`.
- Region: reachable from this US machine; other regions were not verifiable
  from here.

Candidate B — ESPN NHL scoreboard
(`https://site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard`):

- Verified live 2026-08-25 via dated queries (20260110: 14 events; 20260115:
  10 events including Utah as ESPN id `129764`): the
  event/competition/competitor shape is the same family the verified
  `EspnProvider` adapter already parses for the seven ESPN-backed leagues,
  on the already-reviewed host. No new third-party terms, endpoint family,
  or auth requirement would be introduced.
- Identity blocker: ESPN NHL team ids do not match the NHL.com ids in
  `NhlTeamCatalog` (BOS 1 vs 6, NYR 13 vs 3, TOR 21 vs 10, UTA 129764 vs
  68, SEA 124292 vs 55), and tri-code conventions differ (`TB` vs `TBL`,
  `SJ` vs `SJS`, `LA` vs `LAK`). A provider switch would break canonical
  `nhl:<id>` favorite identity unless the adapter gains an explicit 32-team
  ESPN-id↔NHL-id translation map; a naive abbreviation string join cannot
  work.
- Transport matches the existing ESPN endpoints (`cache-control:
  max-age=1`, no rate-limit headers). The current offseason query returns
  zero events — the same safe empty state the ESPN standings adapter
  already handles.

Owner review required before any adapter work (the P1-4 gate): (1) accept
or reject the MLB StatsAPI terms framing for Sportray's personal
non-commercial use; (2) choose the first second-candidate league (MLB via
StatsAPI, or NHL via ESPN); (3) accept the explicit id-translation
requirement so canonical favorite identities survive provider switches.

Evidence: gates rerun to record the unchanged baseline —
`./tests/run-js-tests.sh` passes with 226 deterministic tests,
`./tests/test-summon-helper.sh` passes, `git diff --check` passes,
`omarchy plugin validate "$PWD"` exits 0, and real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
exits 0 with the established standalone warnings. No QML or provider source
changed, so no shell restart, rescan, or fresh-log claim is made. The
unrelated absence of `MARKETPLACE_SUBMISSION.md` remains untouched. No push,
tag, release, or Marketplace action occurred.

Decision log: keep the reconnaissance strictly read-only — no adapter, no
`providerChain()` change, no fixture — until the owner answers the three
review questions. Record the MLB terms near-verbatim rather than summarizing
them away, and treat the ESPN-NHL identity translation as a mandatory part
of any later unit, because canonical favorite identity is a persisted
product contract. The ESPN-NHL candidate's zero-new-terms advantage is
real, but it cannot be adopted without the translation map.

Known risks: both APIs are undocumented site APIs that may change without
notice; the MLB terms determination is owner-owned legal review; region
coverage outside the US is unverified; and the reconnaissance observed no
live in-progress MLB game state today (evening slate was all `Preview`), so
the live-state field variety (for example `abstractGameState: "Live"`) was
not directly observed from the schedule endpoint this session — the status
vocabulary is documented by the same endpoint family's Final/Preview states
and would be pinned by fixtures in any adapter unit.

Next bounded unit: on the owner's answers to the three review questions,
implement the first second-candidate adapter as one bounded vertical slice
(provider parsing in `providers/`, the explicit id translation table,
fixture coverage including live-state variants, `providerChain()` gaining
its second candidate, bounded polling unchanged). Without owner answers,
the standing live-football observational verification
(`competitions[].details`, weather, leaders) remains the prepared unit for
the CFB week-0 window from Sat Aug 29; do not infer direction.

## Latest handoff — 2026-08-25 MLB StatsAPI second candidate

Status: complete. The owner answered all three review gates: MLB's
"individual, non-commercial, non-bulk use" framing is accepted for Sportray's
personal use, MLB via StatsAPI is the first second-candidate league, and the
explicit team-id translation requirement is accepted. The MLB fallback slice is
implemented without changing settings, notifications, QML views, or polling
cadence bounds.

Evidence:

- `providers/MlbStatsProvider.js` parses the verified
  `statsapi.mlb.com/api/v1/schedule?sportId=1&date=YYYY-MM-DD&hydrate=team,linescore`
  response into normalized MLB games. It admits the 30 current StatsAPI team
  ids only through an explicit table to the ESPN id space observed on
  2026-08-25, rejects unknown team ids, builds safe `https://www.mlb.com/gameday/`
  links, preserves venue and scores, and projects live inning state without
  passing raw payload fields onward.
- The direct endpoint observation confirmed 15 Preview/Scheduled games on
  2026-08-25, ten Final games on 2026-08-24, an empty offseason response with
  `dates: []`, `totalGames: 0`, and the CDN headers
  `max-age=20`, `stale-while-revalidate=30`, and `stale-if-error=86400`.
  No in-progress MLB game was available during this session, so the Live
  fixture pins the documented `Live`/`In Progress` shape rather than claiming
  live runtime observation. MLB.com gameday links were checked to resolve from
  a game id, and the shared game-link boundary now admits `mlb.com`.
- `providers/LeagueCatalog.js` now gives only MLB the ordered
  `['espn', 'mlb-stats']` chain. `services/LeagueFetch.qml` adds only the
  provider URL/parser branches; it still owns exactly two `Process` objects,
  two curl command arrays, two JSON parses, and the existing response bounds.
  Lookahead remains on the existing ESPN route.
- `fixtures/mlb-stats/` and the deterministic suite cover all 30 translation
  pairs, URL validation, scheduled/final/live/administrative states,
  empty/offseason slates, malformed/unknown teams, and the 256-event bound.
  The complete suite passes with 230 tests.
- `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and the real-import-path QML lint over all
  QML files pass with the established warnings.
- Actual Omarchy 4.0.0-1 with Quickshell `28771c7c74b42e20afca0b1b63980cb46515537`
  was restarted into one shell instance (`yvanxb9ckt`), `shell ping` returned
  `ok`, toggle/hide IPC completed, and the fresh log showed normal MLB and
  sibling-provider initialization with no Sportray exception, QML-load error,
  or binding-loop warning. The unrelated portal registration warning remains.
  No forced ESPN failure was injected, so live fallback selection itself is
  fixture-verified rather than runtime-claimed.
- The completed source unit is committed as `cb53ded` (`feat: add MLB StatsAPI
  fallback`).

Decision log: retain ESPN as MLB's primary provider and append StatsAPI as the
second candidate so existing behavior changes only after the primary provider
reaches its established failure threshold. Use the live ESPN id space as the
translation target because the current ESPN scoreboard and current ESPN team
endpoint agreed on those ids for all 30 teams; unknown StatsAPI ids fail closed.
Do not add StatsAPI detail sections, a second lookahead endpoint, or a provider
specific settings field in this unit.

Known risks and follow-ups:

- The current live ESPN scoreboard/team endpoint was observed to differ from
  the checked-in static `EspnTeamCatalog` MLB snapshot for ten team assignments
  (ATL, DET, LAA, MIA, MIL, MIN, PHI, SF, STL, and TB). The owner currently
  follows `mlb:2` (BOS), which is unaffected. This pre-existing identity drift
  needs a separate owner-directed reconciliation; do not change persisted
  settings or the static catalog as part of this adapter unit.
- The MLB fallback has not been exercised by injecting a failed ESPN response;
  doing so against the live shell would alter the provider-health path and was
  not necessary for the bounded gate. StatsAPI detail fields beyond the core
  scoreboard shape remain neutral when the fallback is active.
- ESPN and MLB StatsAPI are undocumented provider interfaces; terms, regional
  availability, response shapes, and rate limits may change. No push, tag,
  release, Marketplace, or remote action occurred. The unrelated absence of
  `MARKETPLACE_SUBMISSION.md` remains untouched.

Next bounded unit: during live-football minutes (CFB week 0 from Sat Aug 29;
NFL week 1 from Thu Sep 10), perform the prepared read-only observation of
`competitions[].details` (scoring plays), `competitions[].weather`, and
`competitions[].leaders` while at least one football game is in progress. If
outside those minutes and no owner selects another unit, record the unchanged
window blocker and stop; do not reconcile the MLB catalog drift, inject a
provider failure, add detail fields, or change release/publication state.

## Latest handoff — 2026-08-25 football observation missed window

The prepared read-only football observation was attempted once at
2026-08-25 14:53:54 EDT (18:53:54 UTC). The documented ESPN NFL scoreboard
endpoint returned 16 events, all with status state `post`; the documented ESPN
college-football scoreboard endpoint returned 25 events, all with status state
`pre`. Neither payload contained an event with status state `in`, so the live-
minutes gate was not met.

No `competitions[].details`, `competitions[].weather`, or populated
`competitions[].leaders` observation was made. This is intentional: no raw
provider payload was stored, no field presence was inferred from non-live
games, and no scoring-play, weather, or leader direction was changed. The
missed window should be retried during CFB week 0 from 2026-08-29 or NFL week
1 from 2026-09-10.

The checkout remains at committed MLB StatsAPI fallback `cb53ded` with 230
deterministic tests. The full suite, summon-helper checks, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path QML lint over every QML
file pass. Installed Omarchy `4.0.0-1` and Quickshell `0.3.0` revision
`28771c7c74b42e20afca0b1b63980cb46515537` remain the inspected host boundary;
no upstream deviation was found. No source, fixture, QML, endpoint, setting,
notification, catalog, fallback, runtime, or release state changed. The
absence of `MARKETPLACE_SUBMISSION.md` remains untouched.

Known follow-ups remain unchanged: live fallback selection is fixture-verified
only, current ESPN/static MLB team-id drift must not be reconciled without a
separate owner-directed unit, and no provider detail fields should be added
from this missed window. No success commit was created for this pure
observation/documentation update.

Next bounded unit: during the next actual live-football minutes (first CFB week
0 game from 2026-08-29, or NFL week 1 from 2026-09-10), repeat one read-only
observation of `competitions[].details`, `competitions[].weather`, and
`competitions[].leaders` only while at least one NFL or college-football event
has status state `in`. If no game is live, record the missed window and stop.
Do not change providers, catalogs, settings, notifications, polling, QML,
fixtures, endpoints, release state, or MLB/static-team-id drift.

## Latest handoff — 2026-08-25 football observation recheck

A second same-day read-only check was completed at 2026-08-25 15:12:41 EDT
(19:12:41 UTC). The documented ESPN NFL scoreboard endpoint again returned 16
events, all with status state `post`; the documented ESPN college-football
scoreboard endpoint again returned 25 events, all with status state `pre`.
There were zero events in state `in`, so the live-minutes gate remained closed.

No `competitions[].details`, `competitions[].weather`, or populated
`competitions[].leaders` shape was inspected. No raw payload was stored and no
provider behavior was inferred from this recheck. The required unchanged
baseline passed: 230 deterministic JavaScript tests, summon-helper tests,
`git diff --check`, actual-Omarchy `omarchy plugin validate`, and real-import-
path QML lint over every QML file (exit 0 with established warnings).

No source, fixture, QML, endpoint, setting, notification, catalog, fallback,
runtime, or release state changed. The unresolved ESPN/static MLB team-id drift
and fixture-only fallback selection remain unchanged. The next eligible unit is
the same live-football observation during CFB week 0 from 2026-08-29 or NFL
week 1 from 2026-09-10; outside those minutes, stop rather than infer fields or
select an owner-gated release, identity, or provider unit.

## Latest handoff — 2026-08-25 football observation third missed window

A third same-day read-only check was completed at 2026-08-25 16:23:31 EDT
(20:23:31 UTC). The documented ESPN NFL scoreboard endpoint returned 16 events,
all with status state `post`; the documented ESPN college-football scoreboard
endpoint returned 25 events, all with status state `pre`. There were zero events
in state `in`, so the live-minutes gate remained closed.

No `competitions[].details`, `competitions[].weather`, or populated
`competitions[].leaders` shape was inspected. No raw payload was stored, no
provider behavior was inferred from non-live games, and no scoring-play,
weather, or leader direction changed. Installed Omarchy 4.0.0-1 and Quickshell
0.3.0 revision `28771c7c74b42e20afca0b1b63980cb46515537` remain the directly
inspected host boundary with no material deviation.

The unchanged baseline gates remain required after this documentation-only
observation. No source, fixture, QML, endpoint, setting, notification, catalog,
fallback, runtime, or release state changed. The unresolved ESPN/static MLB
team-id drift and fixture-only fallback selection remain unchanged. The
absence of `MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No
success commit is created for this pure observation.

Next bounded unit: during the next actual live-football minutes, beginning with
the first CFB week-0 game from 2026-08-29 or NFL week 1 from 2026-09-10, perform
one read-only observation of `competitions[].details`,
`competitions[].weather`, and `competitions[].leaders` only while at least one
ESPN NFL or college-football event has status state `in`. If no game is live,
record the missed window and stop. Do not change providers, parsing,
endpoints, polling, settings, notifications, catalogs, fixtures, QML,
normalized fields, release state, fallback behavior, or MLB/static-team-id
drift.

## Latest handoff — 2026-08-25 detail presentation cleanup

Status: complete. This bounded presentation slice removes duplicate and empty
status/timing labels from the local game-details card without changing
providers, normalized fields, routing, polling, settings, or notifications.

Evidence:

- `model/Formatters.js` now owns `formatDetailStatus(status)`, which suppresses
  case-insensitive duplicates across the state, detail, period, and clock
  values. `Scheduled · Scheduled` now renders as `Scheduled`, and missing
  status detail no longer produces a trailing `· —`.
- `formatDetailTiming(start, end)` renders complete timing, start-only, or
  end-only labels and uses `Timing unavailable` when both values are absent.
  `components/GameDetailView.qml` consumes both pure presentation formatters;
  provider parsing and the normalized detail model remain unchanged.
- The game-detail route fixture now keeps sparse-placeholder assertions at the
  QML wiring boundary, while the deterministic formatter test covers scheduled,
  live duplicate-period, final duplicate-detail, unknown, complete timing,
  partial timing, and missing timing cases. The suite passes with 231 tests.
- Required checks pass: `./tests/run-js-tests.sh`,
  `./tests/test-summon-helper.sh`, `git diff --check`,
  `omarchy plugin validate "$PWD"`, and real-import-path QML lint over every
  QML file (exit 0 with the established standalone warnings).
- Actual Omarchy 4.0.0-1 with Quickshell 0.3.0 was restarted into one shell
  instance (`hpznhufckt`, PID 1119365); `shell ping` returned `ok` and the
  summon helper returned `ok`. The real keyboard path opened the BOS at MIA
  details card and the inspected render showed one `Scheduled` label and a
  single start-time line. The fresh log contains normal Sportray polling and
  no Sportray exception, QML-load error, or binding-loop warning; only the
  pre-existing unrelated portal registration warning remains.

Decision log: keep these strings in the shared formatter layer so every detail
view state is deduplicated consistently while QML remains a projection-only
view. Treat a missing end time as partial timing rather than an error, and use
one neutral `Timing unavailable` label only when neither endpoint exists.

Known risks and follow-ups remain unchanged: live football verification of
`competitions[].details`, weather, and populated leaders still requires an
actual event in state `in`; live fallback selection remains fixture-verified
only; and the ESPN/static MLB team-id drift remains unresolved and must not be
changed in the live-observation unit. The absence of
`MARKETPLACE_SUBMISSION.md` remains untouched and unstaged. No push, tag,
release, or Marketplace action occurred.

Next bounded unit: during the next actual live-football minutes, beginning with
the first CFB week-0 game from 2026-08-29 or NFL week 1 from 2026-09-10,
perform one read-only observation of the documented ESPN NFL and
college-football scoreboard payloads only while at least one event has status
state `in`. Inspect bounded shapes for `competitions[].details`, weather, and
populated leaders. If no game is live, record the missed window and stop; do
not add provider fields or change catalogs, settings, polling, notifications,
fixtures, QML, normalized fields, fallback behavior, or release state.

## Latest handoff — 2026-08-25 live-football window not yet eligible

Status: blocked pending the owner-defined live-football window. This unit was
checked at 2026-08-25 17:52:56 EDT, before the first eligible CFB week-0 game
from 2026-08-29 or NFL week-1 game from 2026-09-10. No ESPN NFL or
college-football scoreboard payload was queried, so no non-live field shape was
inspected or inferred and no raw payload was stored.

Evidence: the working tree was clean on `main` at `ccfc099`, with committed
MLB StatsAPI fallback `cb53ded` and the previously recorded 231-test baseline.
Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 remain the directly inspected
host boundary: `KeyboardPanel` is still a `PanelWindow` with `screen`,
`availableCardHeight`, and `fittedContentHeight`, and no material deviation
from the documented repository contract was found. The required unchanged
baseline passed: `./tests/run-js-tests.sh` (231 tests),
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
(exit 0 with established standalone warnings).

No provider, parsing, endpoint, polling, settings, notification, catalog,
fixture, QML, normalized field, fallback, release, or team mapping changed.
The unresolved ESPN/static MLB team-id drift and fixture-only live fallback
selection remain unchanged. The absence of `MARKETPLACE_SUBMISSION.md`
remains untouched and unstaged. No success commit was created for this
blocked documentation-only handoff.

Decision log: do not turn a pre-window clock check into football payload
evidence. The next agent must wait for an actual NFL or college-football event
with status state `in`, inspect only the bounded `details`, `weather`, and
populated `leaders` shapes, and record a missed eligible window if no such
event is present.

Next bounded unit: during the first actual eligible live-football minutes from
CFB week 0 on 2026-08-29 or NFL week 1 on 2026-09-10, query the documented ESPN
NFL and college-football scoreboards read-only. Proceed only when at least one
event has status state `in`; inspect bounded shape summaries for
`competitions[].details`, `competitions[].weather`, and
`competitions[].leaders` only when a group contains athlete entries. Do not
store raw payloads or change any provider, model, fixture, QML, settings,
polling, fallback, catalog, release, or team-mapping behavior. Run all five
baseline gates afterward, update this handoff and `competition.md` if the
observation changes the backlog evidence, replace `NEXT_SESSION_PROMPT.md`,
and create no success commit for a pure observation.

## Latest handoff — 2026-08-25 live-football window still not eligible

Status: blocked at 2026-08-25 18:08:50 EDT because the owner-defined live-
football observation window has not opened. The first eligible CFB week-0
window begins 2026-08-29; the alternative NFL week-1 window begins
2026-09-10. No ESPN NFL or college-football scoreboard request was made, so
no `competitions[].details`, `competitions[].weather`, or populated
`competitions[].leaders` shape was inspected or inferred and no raw payload was
stored.

Evidence: the source tree remains at committed presentation cleanup `ccfc099`
with MLB StatsAPI fallback `cb53ded`; the worktree's only changes are the
private handoff files already being preserved. Installed Omarchy `4.0.0-1` and
Quickshell `0.3.0` revision `28771c7c74b42e20afca0b1b63980cb46515537` remain
the directly inspected host boundary. `Panel.qml` still declares the host
`settings` property, and `KeyboardPanel.qml` still provides the `PanelWindow`,
screen, and bounded card-height contract; no material upstream deviation was
found.

The unchanged baseline gates passed: `./tests/run-js-tests.sh` (231 tests),
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file
(exit 0 with established standalone warnings). No provider, parsing, endpoint,
polling, settings, notification, catalog, fixture, QML, normalized field,
fallback, release, or team mapping changed. The unresolved ESPN/static MLB
team-ID drift and fixture-only fallback selection remain unchanged. The
absence of `MARKETPLACE_SUBMISSION.md` remains untouched; no success commit was
created for this blocked documentation-only handoff.

Decision log: a pre-window check is not football payload evidence. Do not
query or summarize non-live football payload fields. During the first actual
eligible live minutes, query the documented ESPN NFL and college-football
scoreboards read-only and proceed only if at least one event has status state
`in`. If an eligible window passes with no live event, record that missed
window in this roadmap and the matching `competition.md` backlog line, then
stop without inferring field behavior.

Next bounded unit: during the first actual eligible live-football minutes from
CFB week 0 on 2026-08-29 or NFL week 1 on 2026-09-10, inspect bounded
`competitions[].details`, `competitions[].weather`, and
`competitions[].leaders` shapes only for live events, without storing raw
payloads or changing provider, model, fixture, QML, settings, polling,
fallback, catalog, release, or team-mapping behavior. Run all five baseline
gates afterward, update the roadmap and `competition.md` only if the evidence
requires it, replace `NEXT_SESSION_PROMPT.md`, and create no success commit for
a pure observation. Stop before fallback injection, MLB catalog
reconciliation, packaging, tagging, pushing, release, or Marketplace work.

## Latest handoff — 2026-08-25 Level the Field sprint planned

Status: planning complete; implementation not started. The owner selected the
named **Level the Field** feature catch-up sprint and directed the coding team
to ship five competitor-parity outcomes: a real month calendar, expiring
one-game watches, followed and ordered leagues, verified scoring-play/leader
detail, and verified broadcast context. `LEVEL_THE_FIELD_SPRINT.md` is the
detailed sprint source of truth with product contracts, architecture,
dependencies, bounded work units, acceptance gates, regression matrix, risks,
and definition of done.

Decision log: reopen P1-6 calendar parity. The shipped five-day cache strip is
valid historical work but does not satisfy the owner's product expectation of
a calendar. Calendar must become a conventional 42-cell month surface with
honest unknown/loading/partial/empty states and a selected-day agenda. Wider
schedule hydration will be a separate low-frequency fetch concern gated by
provider-volume evidence; it must not crawl live polling or raise the 2 MiB/
256-event limits merely to fit a month. Watches, followed leagues, and their
ordering will share one deliberate schema-2 migration that preserves schema-1
preferences and future-schema opacity. Scoring plays/leaders remain live-data
gated and do not block the calendar. Broadcast labels are useful without a
stream URL and must not imply regional availability.

Current verified source baseline remains `ccfc099` with 231 deterministic
tests and the previously passing summon-helper, diff, actual-Omarchy validator,
and real-import-path QML-lint gates. This planning unit changed no runtime,
provider, model, QML, settings, notification, endpoint, fallback, catalog, or
release behavior, so runtime checks were not required. Installed Omarchy
`4.0.0-1` and Quickshell `0.3.0` remain the current host boundary; no new host
claim was introduced. Existing unresolved live-football evidence, MLB team-ID
drift, and fixture-only live fallback risks remain recorded and outside C1.

Next bounded unit: implement `LEVEL_THE_FIELD_SPRINT.md` unit **C1 — Month
grid vertical slice** only. Extend the pure calendar projection with 42-cell
month geometry and explicit known-versus-unknown state; replace the five-day
Calendar strip with a keyboard- and accessibility-reachable month surface;
reuse existing cached summaries, selected-date fetching, selected-day rows,
filters, and detail routing. Add no schedule crawler, new endpoint, settings
schema, watched game, followed league, scoring-play/leader, broadcast,
fallback, catalog, packaging, release, or Marketplace change. Pass the complete
deterministic and actual-Omarchy gates, update sprint/roadmap evidence, refresh
the next prompt, and commit the source unit atomically.

## Latest handoff — 2026-08-25 Level the Field C1 month grid complete

Status: complete as one bounded C1 vertical slice. Calendar now renders a
Monday-first 6-by-7 month grid with exactly 42 stable local YYYY-MM-DD cells,
adjacent-month dates, selected and today states, previous/next month controls,
Today, bounded cached game counts, favorite markers, and explicit unknown
versus known-complete-empty presentation. The old CalendarWeekStrip consumer
was removed after source inspection showed no remaining consumer.

Implementation evidence:

- DateModel.js adds pure local month-key and month-step helpers.
  CalendarModel.js adds exact 42-cell geometry, month projection,
  completeness-aware state, bounded counts/league markers, favorite filtering,
  and selected-day loading/unknown/unavailable row states. QML performs no
  date arithmetic, provider parsing, raw filtering, or URL construction.
- LeagueFetch.qml marks a date-cache entry complete true only when it was
  written after a successful zero-error normalized snapshot. Missing dates
  remain unknown; C1 adds no schedule owner, request, Process, timer, polling,
  response-limit, or cache-width change.
- MonthCalendar.qml owns only presentation and intent signals. Pointer and
  Accessible buttons converge on the same date/month/Today functions; the
  installed PanelKeyCatcher routes grid Left/Right and Up/Down focus movement,
  Enter/Space activation, and PageUp/PageDown month movement through the
  existing panel focus owner. Selected-day rows continue through the existing
  game/detail/source route and list scroll ownership.
- Fixture-driven tests cover ordinary, six-week, leap-day, year-rollover,
  adjacent-cell, invalid-input, local-DST, completeness, filters, selected
  day loading/unknown, keyboard routing, bounds, and no-new-owner assertions.
  The deterministic suite passes with 234 tests. Summon-helper, diff check,
  plugin validation, and full real-import-path QML lint pass.

Host evidence and boundary decision:

- The private docs/upstream-contract.md remains intentionally absent.
  Installed Omarchy 4.0.0-1 and Quickshell 0.3.0 revision
  28771c7c74b42e20afca0b1b63980cb46515537 were inspected directly.
  KeyboardPanel still provides availableCardHeight, fittedContentHeight,
  and four-edge clamping; PanelKeyCatcher remains a Keys.BeforeItem semantic
  dispatcher. No material upstream deviation was found or introduced.
- Actual Omarchy was restarted into exactly one Quickshell instance
  (c0240dfe8c8e8a421e1f8db23a03fc60), plugin discovery showed Sportray
  enabled, shell ping returned ok, rescan returned ok, and the summon helper
  returned ok. A fresh screenshot showed the current August 2026 42-cell
  grid, adjacent July/September cells, neutral Unknown cells, the selected
  cached Aug 25 count, month controls, and bounded selected-day rows. Real
  l/j focus movement plus Enter selected adjacent September 2 and triggered
  the existing enabled-league date-changed fetch path. Fresh logs contain
  normal fetch activity and no Sportray error, QML-load failure, exception,
  binding-loop warning, late callback, or duplicate graph; the unrelated
  portal-registration warning remains.
- No reliable pointer injector or child-panel accessibility injector is
  available in this host session. Pointer and Accessible routes are source
  verified and share the same guarded button signals, but those two direct
  runtime activations are not claimed as manually exercised. The grid fit
  within the current top-bar available-card-height contract; the existing
  host fitting/clamping contract remains applicable to bottom/left/right
  bars and no orientation-specific code was added.

Decision log: C1 uses only existing successful five-date score caches for
month density and deliberately leaves unvisited dates unknown. A known empty
day requires complete entries for every enabled league, so a missing sibling
league cannot be mistaken for a verified empty slate. Wider month hydration
and provider feasibility work remain C2/C3; no false completeness or new
fetch ownership was added. The unresolved live-football evidence, ESPN/static
MLB team-ID drift, and fixture-only runtime fallback selection remain outside
C1.

Known risks: cache-only month density is intentionally sparse until C2/C3;
pointer/accessibility direct runtime activation remains host-input limited;
and changing bar orientation still needs the usual actual-Omarchy exercise in
a later runtime-polish pass. No push, tag, release, Marketplace, or remote
action occurred. The unrelated absence of MARKETPLACE_SUBMISSION.md remains
untouched and unstaged.

Next bounded unit: implement C2 — Provider range reconnaissance and chunk
policy only. Inspect accepted provider range/schedule behavior read-only,
derive fixture-tested bounded pure chunk planning, and update provider
strategy evidence. Do not add QML, a schedule fetch owner, month hydration,
new endpoints, timers, polling changes, response-limit changes, cache
widening, settings schema 2, watched games, followed leagues, detail
providers, packaging, release, or Marketplace work.

## Latest handoff — 2026-08-25 Level the Field C2 complete

Status: complete as one policy-only work unit. Bounded in-memory observations
were made against the already accepted ESPN site API, NHL API, and the
owner-accepted key-free MLB StatsAPI route. No raw provider response was
retained in the repository.

Evidence: a 2026-04-01 through 2026-05-12 range (42 requested days) returned
ESPN NFL and college-football empty off-season responses, ESPN MLB at 100
events/~1.86 MiB, NBA at 100/~1.34 MiB, EPL at 50/~556 KiB, and MLS at
100/~1.22 MiB; none advertised continuation. The ESPN men's college
basketball route returned 404, so its in-season range behavior remains
unresolved. The NHL schedule route returned seven `gameWeek` dates, 56 games,
and `nextStartDate: 2026-04-08`. The 42-day MLB StatsAPI request exceeded the
existing 2 MiB curl admission boundary before a response body could be
inspected. Elapsed times were approximately 0.10–0.39 seconds for ESPN,
0.57 seconds for NHL, and 0.55 seconds for the rejected MLB StatsAPI request.

`model/ChunkPolicy.js` and `fixtures/provider-range/c2.json` add the pure
policy/evidence slice. Accepted profiles plan at most seven-day chunks, eight
requests, one concurrent request, a 42-day total window, the existing 2 MiB
byte bound, and the existing 256-event bound; ESPN MLB is conservatively
one-day because its observed range was capped. CFB, NCAA Men's Basketball,
and MLB StatsAPI range hydration remain unsupported. Admission rejects bad
status, bytes, event counts, date spans, incomplete results, observed ESPN
100-event caps, and missing NHL continuation. Source assertions prove the
policy has no QML/network/process/timer ownership and that C1's two-process,
zero-timer, two-curl LeagueFetch topology and five-date cache remain intact.

Decision: no provider has yet earned safe 42-day all-game completeness.
ESPN capped responses without continuation, off-season observations, the
unavailable NCAA Men's Basketball route, and the oversized MLB StatsAPI range
remain unknown/partial rather than complete. C3 may add an owner only for
profiles revalidated against current responses and must keep existing limits
and the one-in-flight boundary.

All required gates pass: JavaScript now passes with 238 tests, summon-helper,
diff check, actual Omarchy plugin validation, and full real-import-path QML
lint pass with established warnings. Installed Omarchy 4.0.0-1 and Quickshell
0.3.0 remain the directly inspected boundary with no material deviation; no
runtime shell exercise was needed because QML/service/runtime behavior did not
change. The pre-existing unrelated `competition.md` and `roadmap.md` edits
were preserved. `MARKETPLACE_SUBMISSION.md` remains absent and untouched. No
push, tag, release, or Marketplace action occurred.

Next bounded unit: implement **C3 — Low-frequency calendar fetch and cache**
only, using `ChunkPolicy` as a feasibility gate. Read AGENTS.md, README.md,
roadmap.md, the latest handoff, LEVEL_THE_FIELD_SPRINT.md, competition.md,
and NEXT_SESSION_PROMPT.md; inspect installed/current Omarchy and Quickshell
sources again. Add one focused schedule owner only for an explicitly admitted
profile, a bounded window cache, normalized provider results, generation-safe
late-response rejection, and honest stale/partial/empty/unavailable states.
Do not widen bytes/events/requests/cache, enable unsupported CFB/NCAA Men's
Basketball/MLB StatsAPI ranges, alter live polling/notifications/fallbacks,
or add watches, followed leagues, scoring plays, leaders, broadcasts,
packaging, release, or Marketplace work. Run all deterministic/repository
gates plus actual Omarchy validator and every-file real-import-path QML lint;
because C3 changes runtime ownership, also perform one-shell discovery, ping,
summon, and fresh clean-log checks on actual Omarchy. Stop if current provider
responses no longer satisfy policy or partial data could be mistaken for
complete. Update roadmap, sprint evidence, and this prompt, then commit
atomically only after all gates pass.
## Latest handoff — 2026-08-25 Level the Field C3 implementation blocked on host registration

The C3 implementation is present in the worktree but is not marked complete
and has no success commit because the required actual-Omarchy changed-behavior
gate is blocked by host plugin registration.

Implementation evidence: `services/CalendarFetch.qml` is one low-frequency,
generation-safe NHL schedule owner. It plans the visible 42-day month through
the pure `ChunkPolicy`, keeps one `Process` and zero timers, caps the in-memory
window cache at three entries, and preserves the existing two `LeagueFetch`
processes and five-date live caches. `NhlProvider.js` normalizes calendar day
buckets outside QML. `model/CalendarCachePolicy.js` merges canonical game IDs,
uses six-hour future/24-hour historical freshness, and preserves explicit
loading, partial, stale, empty, and unavailable states. `FetchService` merges
schedule state with the selected-day live snapshot without changing polling or
notification ownership. Panel month open/navigation/Today routes request only
the visible month.

Fixture/source evidence covers normalized provider buckets, missing-day
partial coverage, live identity merge, cache freshness and bounds,
generation-safe cancellation, one-process/zero-timer ownership, and absence of
notification routing. The JavaScript suite passes with 242 tests; summon-helper,
`git diff --check`, actual Omarchy plugin validation, and all-file real-import-
path QML lint exit 0 with established warnings.

Host evidence: installed Omarchy 4.0.0-1 / Quickshell 0.3.0 has exactly one
running shell, enabled Sportray discovery, shell ping `ok`, and rescan `ok`.
However, `~/.config/omarchy/plugins/io.github.joega.sportray` is a symlink to
this checkout, the registry reports Sportray `active:false`, and summon returns
`no live bar widget`. No direct first-open hydration, fresh changed-behavior
exercise, or clean post-change log can therefore be claimed. The symlinked
host checkout must be restored to an actual loaded bar-widget registration
before C3 can pass its runtime gate. Do not change host installation state,
push, publish, release, or create a success commit to bypass this blocker.

Decision log: NHL remains the only C3 runtime profile. ESPN capped/no-
continuation observations and unsupported CFB, NCAA Men's Basketball, and MLB
StatsAPI range hydration remain excluded. Partial provider coverage never
becomes an empty day. The public README remains unchanged until C4 runtime
completion.

Next bounded unit: resolve only the actual Omarchy Sportray registration
blocker, then rerun the C3 runtime gate against this worktree. Preserve one
shell and the no-second-process rule; do not widen provider bounds or begin C4,
watches, followed leagues, scoring/leader detail, broadcasts, packaging,
release, or Marketplace work.

## Latest handoff — 2026-08-25 Level the Field C3 runtime gate complete

Status: complete. The actual-Omarchy registration blocker was resolved without
changing host installation state: the installed symlink checkout and manifest
were valid, while the supported rescan needed to finish its asynchronous
widget-component load before summon could succeed. After `omarchy restart
shell`, exactly one Quickshell process remained. Shell ping returned `ok`; a
rescan followed by the bounded summon helper returned `unknown` once during the
load window and then `ok`. `debugBarGeometry` confirmed a visible Sportray
bar-widget slot in the right region at 27x26. The registry `active:false` value
was not used as live-instance evidence because it is false for ordinary live
bar widgets on this host.

Changed behavior was exercised on actual Omarchy from the loaded checkout:
Calendar opened as a 42-cell September 2026 grid with unqueried dates visibly
marked `Unknown`, selected-day rows remained available, and PageDown/PageUp
month navigation was exercised with rapid replacement to cover cancellation
and late-response protection. The existing NHL schedule owner was used through
the visible-month route; no timer or notification route was added. One shell,
the existing live league processes, and the single calendar `Process` boundary
remained intact.

Required gates pass: 242 JavaScript tests, summon-helper tests, `git diff
--check`, `omarchy plugin validate "$PWD"`, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file (exit 0 with established
warnings). Fresh post-restart logs show normal Sportray initialization and no
plugin-load exception, Sportray QML error, or binding-loop warning. The only
remaining warning is the unrelated desktop-portal registration warning.
`MARKETPLACE_SUBMISSION.md` remains absent and untouched; no provider bounds,
unsupported profiles, C4 work, release, push, or Marketplace action occurred.

Decision log: keep NHL as the only C3 runtime profile. Do not treat ESPN
capped/no-continuation ranges, CFB, NCAA Men's Basketball, or MLB StatsAPI
range hydration as complete. Keep partial and unknown calendar coverage
honest, and retain the one-shell/no-second-process rule. The registration race
does not justify a plugin-runtime retry process or destructive host repair.

Next bounded unit: **C4 — Calendar completion and polish** only. Read the
current sprint handoff and inspect the installed host boundary first. Do not
add watches, followed leagues, scoring/leaders, broadcasts, provider profiles,
wider bounds, packaging, release, push, or Marketplace work.

## Latest handoff — 2026-08-25 C4 calendar filter implementation blocked at runtime

Status: blocked; no success commit created. C4 adds a bounded calendar league
filter without widening provider or cache ownership. `CalendarModel.monthGrid`
accepts an optional enabled-league `leagueId` and narrows only the existing
enabled set. `Panel.qml` cycles `All leagues` and each enabled league through
the semantic header action and `L`/`l` route. Fixture-driven tests cover the
projection, accepted/rejected keyboard states, and panel route/source guards.
The old week-strip component has no remaining consumer; its model helper is
retained only because existing historical fixture coverage still exercises it.

Deterministic evidence: `./tests/run-js-tests.sh` passes, including the new
calendar league cases; `./tests/test-summon-helper.sh` passes; `git diff
--check` passes; `omarchy plugin validate "$PWD"` passes; and real-import-path
QML lint passes over all 26 QML files with the established warnings.

Actual Omarchy evidence: after `omarchy restart shell`, exactly one
`quickshell -n -p /usr/share/omarchy/shell` remained and shell ping/rescan
returned `ok`, but the supported summon helper could not obtain a live bar
widget. The fresh log records `summon: no live bar widget for:
io.github.joega.sportray`; no `omarchy-bar` process was present. Therefore
pointer, keyboard, focus, panel-height, all-edge, and fresh changed-behavior
claims remain unverified. The unrelated desktop-portal registration warning
also remains present. No README update was made and no provider, polling,
notification, second-process, destructive-host, release, push, or Marketplace
change was made.

Decision log: keep the league filter as a bounded cycle over enabled catalog
IDs rather than introducing a persistent menu or new fetch path. Resume C4
only after the installed bar-widget registration is restored; then summon the
loaded checkout, exercise pointer/keyboard/focus and top/bottom/left/right
placement, inspect fresh logs, and commit the source plus handoff atomically
only if the full gate passes.

## Latest handoff — 2026-08-25 Level the Field C4 calendar completion

Status: complete. The C4 calendar league filter and keyboard/accessibility
routes are complete, and the prior runtime registration blocker was restored
through the supported Omarchy lifecycle. No success commit had been created
before this handoff; the source and private handoff changes are ready for one
atomic commit after this evidence update.

Implementation evidence: `CalendarModel.monthGrid` accepts only an enabled
catalog league ID and `Panel.qml` cycles All leagues and enabled leagues from
the semantic header action and `L`/`l`. The existing month owner, selected-day
route, filters, detail route, polling, notifications, and one-shell boundary
are unchanged. The old week-strip component has no remaining consumer; its
model helper and historical fixtures remain intentionally retained.

Required deterministic gates pass: `./tests/run-js-tests.sh` reports 243
tests, `./tests/test-summon-helper.sh` passes, `git diff --check` passes,
`omarchy plugin validate "$PWD"` passes, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` exits 0 over all 26
QML files with the established standalone import/unqualified-access warnings.

Actual host evidence: Omarchy `4.0.0-1`, Quickshell `0.3.0`, revision
`28771c7c74b42e20afca0b1b63980cb46515537`. After `omarchy restart shell`,
exactly one `quickshell -n -p /usr/share/omarchy/shell` remained. Discovery
listed Sportray enabled; shell ping and rescan returned `ok`; the bounded
summon helper returned `ok`; and `debugBarGeometry` showed a visible Sportray
slot in the right region at 27x26. The calendar opened from that loaded
widget; the 42-cell August 2026 grid, month replacement via PageUp/PageDown,
arrow focus movement, visible focus ring, Space activation of an adjacent
date, selected-day rows, and existing date-change fetch path were exercised.
Fresh screenshots covered top, bottom, left, and right bar positions; panel
height stayed within the installed `KeyboardPanel` fitted-card contract; the
bar was restored to top. Fixture/source checks cover favorites/league filters,
partial-provider failure, cache reuse, selected-day detail, and Accessible
action convergence.

No reliable pointer-click or child-panel accessibility injector is installed
in this host session. Pointer and Accessible handlers are source/fixture
verified and converge on the guarded routes, but direct injected click
activation is not claimed as manually exercised. This is a remaining host
input limitation, not a registration failure. The fresh post-restart log
(`k1cp6qpckt`) contains normal Sportray startup and date-change activity with
no Sportray error, QML-load failure, exception, binding loop, late callback,
duplicate graph, or registration failure. The unrelated desktop-portal
registration warning remains.

Decision log: the registration issue was the supported asynchronous
rescan/component-load race. A restart followed by rescan and bounded summon
is sufficient; no plugin retry process, second shell, destructive host repair,
provider-bound change, or new upstream API is justified. Public README text
does not need changing because C4 completes and verifies existing documented
calendar behavior without changing its public contract.

Next bounded unit: **W2 — Notification admission** only.

## Latest handoff — 2026-08-25 W2 notification admission complete

Status: complete. W2 extends the existing pure notification admission path so
favorite-team alerts and active explicit watches share one bounded
favorite-or-watch gate. Transition deliveries, pregame reminders, and
close-game admission all use the persisted `watchedGames` projection. A watch
must be active, canonical (`<league>:<providerGameId>`), and unexpired at the
admission timestamp; malformed, removed, expired, or absent watches fail
closed. Favorite admission remains independent, so removing a watch does not
silence a favorite-team alert.

The existing global and per-event notification settings remain authoritative.
First-fetch suppression remains in `NotificationService`; transition
fingerprints remain owned by the existing persistent dedupe state, so a game
matching both favorite and watch criteria produces one delivery. Calendar
hydration has no notification-service connection. The installed Omarchy
notification helper was inspected directly; its existing positional
argument-array boundary remains unchanged.

Fixture evidence covers favorite-only, watch-only, overlap without duplicate
delivery, removed, expired, malformed, restart-safe active watch, disabled
global/event settings, first-fetch silence, pregame, close-game, and no
calendar-hydration admission. No UI, provider parsing, fetching, polling,
watch mutation, or new notification type changed.

Validation: `./tests/run-js-tests.sh` passes with 249 deterministic tests;
`./tests/test-summon-helper.sh` passes; `git diff --check` passes;
`omarchy plugin validate "$PWD"` passes; and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` exits 0 over all QML
files with the established standalone import/unqualified-access warnings.
Actual Omarchy runtime exercise was not required because no QML wiring or
host-boundary behavior changed.

Decision: keep W2 admission validation local to the pure notification policy
inputs and do not normalize or persist watches from the notification path.
W3 owns watch UI/runtime actions and any resulting mutation boundary.

## Latest handoff — 2026-08-25 W1 watch policy and durable state complete

Status: complete. W1 adds only pure watch normalization/expiry and the
existing settings-store persistence projection. The state schema remains 1 so
schema-1 round trips stay compatible; `watchedGames` is a known bounded state
field, while schema versions greater than 1 retain their exact raw text and
never write defaults over it.

`model/WatchPolicy.js` rejects malformed or provider-shaped records,
canonicalizes league/game identity, deduplicates by game ID using the newest
created record, keeps at most 32 records, strips all fields not needed by the
watch contract, and applies a six-hour terminal recovery window or 30-day
hard maximum. No UI, notification admission, provider fetch, polling,
calendar, or followed-league behavior changed.

Fixture evidence covers malformed entries, duplicates, bounds, clock skew,
postponement, terminal recovery, hard expiry, active restart recovery,
schema-1 persistence, future-schema opacity, and raw provider-field absence.
The JavaScript suite passes with 246 tests. Summon-helper tests, `git diff
--check`, `omarchy plugin validate "$PWD"`, and real-import-path QML lint over
all 26 QML files pass.

Actual Omarchy evidence: after `omarchy restart shell`, exactly one
`quickshell -n -p /usr/share/omarchy/shell` remained; the supported summon
helper returned `ok`; and the fresh instance log showed normal Sportray
initialization and league fetches with no Sportray QML error, exception, or
binding loop. The unrelated desktop-portal registration warning and one
generic FileView dropped-operation warning remain. An initial runtime pass
exposed and fixed a missing explicit QML JS-module injection for
`WatchPolicy`; the final fresh log is clean of that error.

Decision: because the planned schema-2 migration is not present in this
checkout, W1 kept the existing schema-1 boundary rather than introducing a
version upgrade or rewriting future state. W2 must reuse this projection and
extend admission only through the existing normalized transition pipeline.
No push, tag, release, Marketplace, or destructive host action occurred.

## Latest handoff — 2026-08-25 W3 watch UI and runtime complete

W3 is complete as one bounded UI/runtime unit. `components/WatchAction.qml` is
the single semantic watch control shared by `GameRow.qml` and
`GameDetailView.qml`. It derives active/inactive state from the canonical
`WatchPolicy` projection, presents accessible names and explicit disabled
reasons, and routes pointer, keyboard, and installed QtQuick
`Accessible.onPressAction` activation through the existing semantic button.
The detail cursor reserves one watch action before the source and extra-link
actions; row nested-pointer suppression includes the watch control, so a watch
press cannot also open local detail.

`SettingsStore.toggleWatch(game)` is the only mutation owner. It rejects
malformed games, blocks adds for disabled leagues, ended games, unsupported
future-schema state, and the 32-record bound, prunes expired entries before
adding, deduplicates by `<league>:<providerGameId>`, permits removal of an
existing watch even if its league was later disabled, and uses the existing
owner-only permission repair plus atomic state write. `WatchPolicy` now exposes
pure identity, active lookup, and expired-pruning helpers. No provider request,
polling timer, calendar owner, notification admission rule, or new notification
type was added.

Evidence: the deterministic suite passes with 251 tests, including W3
malformed/expired/duplicate guards, schema-1 restart persistence, future-schema
opacity, settings-store source guards, row/detail routing, accessibility
convergence, and safe disabled-state coverage. `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
`qmllint` over every QML file pass. README documents the watch contract.

Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 was restarted through supported
commands and left with exactly one shell. Discovery, shell ping, rescan, and
bounded summon passed; `debugBarGeometry` showed Sportray in the right bar slot.
Fresh instance logs contain normal startup/polling only, with no Sportray error,
QML-load failure, exception, binding loop, late callback, or duplicate graph.
The installed `/usr/bin/omarchy-notification-send` path was exercised with a
temporary safe `notify-send` stub; the captured argv preserved the expected
headline/description and helper options. This session has no pointer injector,
and the summoned child panel did not expose an injectable input surface, so
direct manual add/remove and visual watch-state claims are not made; those
routes are source/fixture verified. No second shell, provider fetch, push,
release, or Marketplace action occurred.

Decision log: keep watch mutation provider-neutral and behind SettingsStore;
allow active removal from disabled leagues without implicitly re-enabling them;
keep future-schema files opaque; and treat UI watches as notification interest
only. The next unit is L1 — followed/ordered league intent model.

## Latest handoff — 2026-08-25 L1 followed and ordered league intent model complete

Status: complete. L1 adds only the pure followed-league intent/order model and
its normalized persistence projection. The checkout deliberately remains on
schema 1: `followedLeagueIds` is an optional known schema-1 field, and legacy
schema-1 state starts with no followed leagues. Future numeric schemas retain
their existing exact raw text and remain unwritable.

`SettingsModel` now canonicalizes, bounds, deduplicates, and intersects
followed IDs with enabled catalog IDs. Unknown, malformed, duplicate,
disabled, and over-bound values fail closed. Pure toggle, move-up, move-down,
and disable cleanup helpers preserve the invariant. `StateModel` and
`SettingsStore` include the field without adding a new schema version.
`PanelPresentation` accepts an optional followed-order input, exposes stable
followed-first destination order, and projects Following sections after
favorite games while deduplicating by canonical game identity. Existing
favorite ordering remains dominant. No UI, provider parsing/fetching,
polling, notifications, calendar ownership, watch behavior, detail,
broadcast, packaging, release, or Marketplace work changed.

Deterministic evidence: `./tests/run-js-tests.sh` passes with 253 tests,
including L1 migration, subset/bounds, ordering, disable cleanup, stable
catalog order, section projection, and duplicate-game fixtures. The source
uses no new host boundary or QML behavior, so no Omarchy runtime claim is
made for this pure unit.

Required repository gates pass: `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
QML lint over all QML files. No push, tag, release, or Marketplace action was
performed.

Decision log: keep followed intent separate from enabled leagues, favorite
teams, and watched games; keep migration-to-followed behavior empty rather
than implicitly following enabled leagues; and defer all user-facing actions
and runtime wiring to L2/L3. Next bounded unit: **L2 — followed-league
settings and navigation UI** only.

## Latest handoff — 2026-08-25 L2 followed-league settings and navigation UI

L2 implementation is complete. `SportsSettings.qml` now presents Enable and
Follow as separate actions, with Follow unavailable until a league is enabled.
Each catalog league has bounded Move up/Move down controls whose enabled state
tracks its normalized followed position. Keyboard cursor activation, pointer
press, and the shared Qt Accessible press route converge on the same
`SettingsStore` mutation functions. Settings revision invalidation refreshes
the action state after every write; disabling a followed league continues to
use the existing atomic pure cleanup and cannot leave a ghost destination.

`Panel.qml` now passes followed IDs into `PanelPresentation`, so Following
sections and league destinations use normalized followed-first order while
favorite games remain first and canonical game identities remain deduplicated.
The calendar league-cycle options use the same followed-first order. No
provider, polling, notification, watch, calendar-fetch, or new host boundary
was added. README now documents the enabled-versus-followed distinction.

Evidence: `./tests/run-js-tests.sh` passes with 254 deterministic tests,
including fixture/source coverage for intent distinction, keyboard/pointer/
Accessible convergence, disabled guards, followed-first destinations and
calendar filtering, settings refresh, and Following deduplication.
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and real-import-path `qmllint` over all QML
files pass; qmllint exits 0 with the established standalone host/import
warnings.

Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 was restarted and rescan/summon was
attempted. Exactly one `quickshell -n -p /usr/share/omarchy/shell` remained,
Sportray stayed enabled, and shell ping returned `ok`. Fresh PID
`1203375` logs show normal Sportray initialization and league cache/fetch
activity with no Sportray QML error, exception, or binding-loop warning, but
also report `summon: no live bar widget for: io.github.joega.sportray`.
Therefore direct pointer, keyboard, Accessible, focus, and edge-placement
interaction was not claimed. This is the remaining L3 runtime gate, not a new
API assumption or a reason to weaken fixture/source acceptance.

Decision log: preserve schema 1 and the empty legacy followed default; keep
followed ordering presentation-only; route every UI action through the
existing settings and semantic-control boundaries; and defer runtime
enable/follow/reorder/restart persistence evidence to L3. No push, tag,
release, Marketplace, or destructive host action occurred.

## Latest handoff — 2026-08-25 L3 followed-league runtime verification blocked

Status: blocked; no success commit created. A fresh supported `omarchy restart
shell`, shell ping, rescan, and bounded summon completed on Omarchy 4.0.0-1 /
Quickshell 0.3.0 with exactly one `quickshell -n -p /usr/share/omarchy/shell`
process. `debugBarGeometry` showed one visible Sportray slot in the right
section at 27x26, so live-widget evidence was established and the panel was
opened from the loaded widget.

Runtime evidence: screenshots showed the live score panel, Calendar route,
Settings route, separate Enable/Follow controls, keyboard cursor focus, and
the real panel edge placement on the current top bar. Keyboard activation of
NCAA Football changed the live settings model and emitted the expected
isolated college-football fetch. The state file immediately before and after
the action remained unchanged: the original six enabled league IDs and an
empty `followedLeagueIds` array. Restarting through supported Omarchy commands
restored that original state. Therefore persistence across restart failed in
this runtime attempt; Follow, Move up/down, disable cleanup, followed-first
Following/destination/calendar ordering, duplicate-row absence, pointer, and
direct Accessible activation are not claimed as manually exercised. No
`no-live-widget` result was treated as UI success.

Repository evidence: `./tests/run-js-tests.sh`,
`./tests/test-summon-helper.sh`, `git diff --check`,
`omarchy plugin validate "$PWD"`, and `/usr/lib/qt6/bin/qmllint -I
/usr/share/omarchy/shell` over every QML file all passed. The fresh post-
restart Quickshell log contains normal Sportray startup and fetch activity
with no Sportray exception, QML-load failure, binding loop, duplicate graph,
or registration failure. The unrelated desktop-portal registration warning
remains.

Decision: preserve the source and schema unchanged and diagnose the existing
SettingsStore/FileView permission/write-readiness boundary before another L3
runtime pass. The supported lifecycle restored the temporary runtime state;
no host config, provider, polling, notification, watch, calendar-fetch, schema,
release, push, or Marketplace change was made.

## Latest handoff — 2026-08-25 L3 persistence readiness fixed; host-input gate blocked

The existing SettingsStore/FileView readiness race is fixed in the current
worktree. `SettingsStore` retains the latest normalized settings,
transition-dedupe, and watch projection when a mutation arrives while the
existing permission repair or asynchronous FileView write is in flight, then
flushes it after the supported repair/saved boundary completes. Schema and
ownership boundaries are unchanged.

Actual Omarchy 4.0.0-1 / Quickshell 0.3.0: after supported restart/rescan/
summon established one visible 27x26 Sportray slot, keyboard Enable added
`college-football` to the state file and a second supported restart restored
it. Keyboard Disable restored the original six enabled leagues and zero
followed leagues. The file remained `0600`. Fresh PID `1217539` logs show
normal startup and isolated college-football fetch activity with no QML
exception, binding loop, duplicate graph, or FileView save failure. One early
bounded summon logged the known registration race before the visible slot was
confirmed; the desktop-portal warning is unrelated.

The full L3 gate remains blocked because this environment provides keyboard
injection but no supported pointer injector or direct accessibility-event
injector. Pointer, Accessible, Follow/reorder, followed-first runtime ordering,
and edge-placement interaction claims remain unverified. Repository gates pass:
`./tests/run-js-tests.sh` (254 tests), `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
QML lint (exit 0 with established warnings). No success commit was created.

## Latest handoff — 2026-08-26 persistent calendar day cache complete

Status: complete for this bounded calendar persistence unit. Added
`CalendarDiskCache` as a separate cache-state owner. It stores only normalized,
complete fetched league/date snapshots as one atomic JSON file per league/date,
with a versioned manifest, sequential read/write FileViews, malformed-input
recovery, explicit file cleanup, and a rolling 30-days-past/30-days-future
window. The policy caps storage at 488 day files and 8 MiB serialized data.
Live snapshots take precedence over disk fallback, so cached scores cannot mask
fresh provider data. Provider parsing, polling, notifications, watches,
calendar-fetch ownership, settings schema, and host APIs are unchanged.

Validation: JavaScript fixtures (including restart-readable normalization and
bounds), summon-helper, diff check, plugin validation, and all-file QML lint
with `/usr/share/omarchy/shell` imports pass. On actual Omarchy 4.0.0-1 /
Quickshell 0.3.0, a clean supported shell restart created matching per-league
day files and a manifest; a second supported restart retained the files and
manifest. Fresh PID `1248293` logs show normal startup and no cache FileView
drop, QML exception, binding loop, or duplicate graph. The unrelated desktop
portal warning and one pre-existing non-cache FileView warning remain.

Decision: persistence is now durable across Quickshell crash/restart and host
reboot insofar as the user cache survives; broad 30-day background hydration
remains a separate next unit and must not invent a provider range endpoint or
second fetch owner. No success commit has been created yet for this worktree.

## Latest handoff — 2026-08-26 background hydration provider gate blocked

Status: blocked; no implementation or success commit was created. The C5
background 30-day hydration review rechecked the current provider evidence
and the installed/current Omarchy 4.0.0-1 / Quickshell 0.3.0 boundaries.

Only NHL has a verified range-compatible schedule continuation: bounded
`gameWeek` pages expose `nextStartDate`, and the existing `CalendarFetch.qml`
owner already admits that contract through `ChunkPolicy`. ESPN range
responses were observed without continuation and with 100-event caps; ESPN
MLB is conservatively one-day only, ESPN NCAA Men's Basketball returned 404,
and the accepted MLB StatsAPI range exceeded the existing 2 MiB response
boundary before inspection. There is therefore no verified provider-safe path
for a complete 30-day background hydration across the documented catalog.

The stop condition was honored: no speculative endpoint, response-limit
increase, second fetch owner, live-polling reuse, timer burst, provider parser,
host API, or cache/schema change was introduced. Unsupported and partial days
remain honest unknown/partial states. The durable per-day cache and visible
month NHL schedule owner are unchanged. No source gates were rerun because
the blocked unit made no source or runtime changes; no actual-Omarchy
hydration behavior is claimed. The upstream boundary inspection found no
material deviation and `docs/upstream-contract.md` remains intentionally
absent.

Decision log: a future C5 attempt must be explicitly scoped to the verified
NHL continuation path (with other leagues remaining unknown) or wait for new
provider evidence/owner direction. Do not claim broad 30-day hydration from
the existing ESPN or MLB observations.

## Latest handoff — 2026-08-26 C5 owner-scope decision still absent

The C5 decision was rechecked. The current request makes NHL-only partial
coverage conditional on explicit owner acceptance, but does not state that the
owner accepts the reduced scope. Since this would change the product contract,
acceptance was not inferred. C5 therefore remains blocked and no source or
runtime behavior changed.

The verified boundary remains unchanged: only NHL's bounded `gameWeek` /
`nextStartDate` continuation is admitted for rolling hydration. ESPN and MLB
range limitations remain documented, and unsupported leagues must remain
explicitly unknown. No repository or actual-Omarchy gates were rerun because
this blocked recheck made no source changes; no success commit was created.

Decision log: resume only after explicit owner acceptance of NHL-only partial
coverage or new provider evidence. If accepted, implement one low-frequency
path through the existing `CalendarFetch.qml` owner and `ChunkPolicy`,
preserving all bounds, cache readiness, polling, notification, cancellation,
and provider ownership. Otherwise keep the blocker documented and stop.

## Latest handoff — 2026-08-26 C5 NHL-only rolling hydration complete

Status: complete for the explicitly accepted NHL-only partial-coverage scope.
`ChunkPolicy.planRolling` admits only `nhl`, plans 30 days in five bounded
seven-day-or-shorter windows, and retains the existing eight-request,
one-concurrent, 2 MiB, and 256-event limits. `CalendarFetch.qml` remains the
sole schedule owner and Process; a single 15-minute Timer starts one rolling
chunk only after `CalendarDiskCache.ready`, gives visible-month requests
priority, and uses the existing generation/cancellation path. Normalized
successful chunks merge into the existing state and durable day-cache flow;
partial or failed chunks never become complete or empty. Unsupported leagues
remain unknown to background hydration.

The implementation adds no endpoint, provider parser, response-limit change,
live-polling reuse, notification route, host API, settings/schema change, or
second owner. The README now documents the accepted partial product scope.
The complete JavaScript suite passes with 256 tests, summon-helper tests,
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
QML lint. Actual Omarchy 4.0.0-1 / Quickshell 0.3.0 was restarted with one
shell; plugin discovery, summon, and shell ping succeeded. Fresh logs showed
normal NHL polling with no QML exception, binding loop, duplicate graph, or
second shell. The timer cadence is source-verified; the full 15-minute
interval was not waited out. The existing L3 pointer/accessibility gate
remains blocked by the host input limitation.

Decision log: NHL-only partial coverage is accepted for C5. Do not extend
background crawling to ESPN or MLB without new provider evidence and an
independent bounded work unit.

## Latest handoff — 2026-08-26 L3 host-input verification blocked

The remaining L3 interaction gate was rechecked on the actual host and remains
blocked. The session is Wayland/Hyprland 0.56.2 on Omarchy 4.0.0-1 /
Quickshell 0.3.0. `wtype` is available for keyboard injection, but no
supported pointer injector (`ydotool`, `dotool`, `xdotool`, or equivalent) is
installed. The session accessibility bus reports `IsEnabled=false`; no
AT-SPI event-driving client is installed. `/dev/uinput` is `0600 root:root`,
and Hyprland's dispatch surface has no click-injection operation, so neither is
a supported user-level fallback.

No source or runtime behavior changed. Existing actual-Omarchy evidence still
covers the live widget, Calendar, settings, keyboard focus, and persistence;
pointer, direct Accessible activation, and the remaining L3 interaction claims
remain unverified. No second shell, privilege escalation, host configuration
change, or product workaround was attempted.

Decision log: preserve the existing product and host boundaries. Proceed with
the independent shared schema-2 migration foundation (S1); revisit L3 only
when a supported pointer/accessibility injector is available.

## Latest handoff — 2026-08-26 S1 schema-2 migration complete

S1 is complete. `SettingsModel` and `StateModel` now emit schema 2 and accept
schema 1 as a deterministic migration input. Valid compatible enabled leagues,
followed leagues, canonical favorites, notifications, transition-dedupe
fingerprints, and watched-game records survive migration; missing or malformed
fields recover to bounded defaults. Schema versions greater than 2 remain
opaque, use safe schema-2 defaults, and are never rewritten until a compatible
reload. README documents the schema-2 contract and that older releases must
not downgrade-write it.

Evidence: `./tests/run-js-tests.sh` passes with 257 deterministic tests,
including complete schema-1 state migration and schema-2 reload coverage;
summon-helper tests, `git diff --check`, `omarchy plugin validate "$PWD"`,
and all-file `/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` pass.
On actual Omarchy 4.0.0-1 / Quickshell 0.3.0, one supported shell restart
migrated the real 0600 schema-1 state to schema 2 and a second restart
preserved all compatible values; shell ping succeeded. Fresh logs contain
normal polling and no Sportray exception, QML-load failure, binding loop,
duplicate graph, or second shell. The dropped FileView-operation and
desktop-portal warnings are unrelated host warnings.

No UI, provider, polling, notification, calendar, hydration, cache, or host
API changed. Decision log: accept S1 and schedule D1 live-football shape
observation for the next eligible in-progress event; keep L3 pointer and
direct-Accessible claims blocked until a supported injector exists.

## Latest handoff — 2026-08-26 D1 live-football gate not eligible

A bounded read-only request to the accepted ESPN college-football scoreboard
route at 2026-08-26 12:48 EDT returned HTTP 200, 21,197 bytes, and 25
scheduled events. No event was live, in progress, or at intermission; the
nearest listed event was USC–SJSU on 2026-08-29 at 15:00 EDT. No scoring-play
or leader shape was inferred and no raw live payload was retained.

D1 remains incomplete pending the first actual eligible in-progress event.
No source or runtime behavior changed after S1. Decision log: do not add a
second endpoint, raise response limits, or start D2/D3 from scheduled-only
evidence. L3 pointer/direct-Accessible verification remains blocked on the
host input limitation.

## Latest handoff — 2026-08-26 D1 live-football gate still not eligible

D1 was rechecked at 2026-08-26 13:23 EDT with one bounded, read-only request
to the accepted ESPN college-football scoreboard route. The response was HTTP
200, 315,934 bytes, and 162.612 ms elapsed; it contained 25 events, all in
provider state `pre`, with zero `in` or intermission events. No live scoring
play or leader shape was observed, inferred, or retained. No raw payload was
retained.

D1 remains incomplete pending the first actual eligible in-progress event. No
source, fixture, test, runtime, provider, endpoint, response-limit, polling,
notification, calendar, cache, settings, or host behavior changed, so no
success commit was created and implementation gates were not rerun. Do not add
a second endpoint, raise limits, or begin D2/D3 from scheduled-only evidence.
L3 pointer/direct-Accessible verification remains blocked by the host input
limitation.

## Latest handoff — 2026-08-26 calendar scroll and prefetch boundary

The owner-requested calendar interaction slice is implemented in the current
worktree. `MonthCalendar.qml` now renders a vertically scrollable week stream
with one previous and one next month page around the active month. Reaching
either list edge emits the existing bounded month request, recenters on the
middle page, and keeps Today, date selection, keyboard focus, faded
adjacent-month cells, and selected-day rows intact. The previous/next month
buttons are removed because scrolling is now the primary navigation path.

`Panel.qml` projects the three pages from the existing normalized calendar
state; no provider parsing, new process, timer, or unbounded model was added.
The broad prefetch question remains provider-gated: only the existing NHL
calendar owner hydrates a rolling schedule, while other leagues still use the
existing selected-day scoreboard request and their bounded date caches. ESPN
range responses and MLB range limits remain insufficient evidence for a broad
all-league calendar crawl, so this unit does not invent that behavior.

Evidence: the deterministic suite passes with 258 tests, including source
assertions for the three-page projection and vertical edge navigation.
`git diff --check`, `omarchy plugin validate "$PWD"`, and real-import-path
QML lint for all files pass; lint exits 0 with the established standalone
import and unqualified-access warnings. Actual Omarchy 4.0.0-1 /
Quickshell 0.3.0 restarted and loaded the revised component with no Sportray
QML exception, binding loop, or duplicate shell. Direct scroll and pointer
exercise remains unclaimed because this host again returned `no live bar
widget` after summon; the existing keyboard-injection limitation remains.

Decision log: use a bounded three-month visual runway and the existing
CalendarFetch owner; do not add broad prefetch endpoints or reinterpret
unknown days as empty. The next unit is runtime verification of this scroll
path once a supported live widget registration/input path is available.

## Latest handoff — 2026-08-26 verified ESPN calendar range hydration

The requested schedule prefetch slice is implemented in the worktree. ESPN's
existing scoreboard range route is now used by the calendar owner for enabled
NFL, NBA, Premier League, and MLS leagues. `EspnProvider` groups the normalized
range response into complete local-date buckets, including empty dates;
`CalendarFetch.qml` queues each enabled eligible league's bounded seven-day
chunks through its one cancellable `Process`; `FetchService.qml` merges the
per-league schedule snapshots beside live and disk state. NHL behavior remains
available, while MLB and both NCAA leagues remain excluded from calendar range
hydration by the provider profile map.

Evidence: deterministic JavaScript tests pass with the new fixture-backed ESPN
range parser and calendar-owner source assertions; `git diff --check`,
`omarchy plugin validate "$PWD"`, `./tests/test-summon-helper.sh`, and
real-import-path QML lint all pass. A live Omarchy interaction pass remains
needed to confirm the month opens with range-populated days and to inspect
fresh Quickshell logs after the multi-league owner change.

Decision log: use the already verified ESPN range route only for the four
bounded seven-day profiles. Do not admit MLB or NCAA range hydration, widen
response/cache limits, or change selected-day polling until new provider
evidence supports those profiles. The next unit is actual Omarchy runtime
verification of multi-league month hydration and the existing scroll/edge
transition.

## Latest handoff — 2026-08-26 calendar hydration and scroll fixes

The calendar follow-up fixes are implemented in the current worktree. The
calendar owner now records a requested month before checking the enabled-league
boundary and retries that bounded month plan when settings finish enabling the
owner, so opening Calendar cannot silently leave range hydration waiting for a
selected-day click. `Panel.qml` opens the route before issuing the request and
reserves the actual six-week calendar viewport in the fitted panel height.
`MonthCalendar.qml` suppresses beginning/end callbacks while the three-page
model is initially populated and recentered, preventing an unsolicited edge
month request and subsequent scroll geometry drift.

Evidence: 258 deterministic JavaScript tests pass, including source assertions
for first-open hydration retry, calendar sizing, and edge suppression; summon
helper, diff check, plugin validation, and real-import-path QML lint pass. The
linked plugin was rescanned and summoned on actual Omarchy 4.0.0-1 /
Quickshell 0.3.0; the shell remained healthy with no Sportray QML exception,
binding loop, duplicate graph, or second shell. Full pointer/scroll and
calendar-visible range completion remain unverified because the host input
path did not focus the summoned panel and no supported pointer injector is
installed. No provider profile, endpoint, response limit, polling,
notification, settings schema, or packaging behavior changed.

Decision log: retain the bounded ESPN seven-day range profiles and the
NHL-only rolling background policy. The next eligible check is a supported
live-widget interaction confirming known multi-day cells appear immediately
after Calendar opens and both list edges recenter without overflow; do not
claim that manual runtime gate from source tests alone.

## Latest handoff — 2026-08-26 calendar-open trigger correction

The real machine's persistent cache showed only selected-day files after the
previous summon, so the calendar range owner was not demonstrably receiving a
month-open request. The trigger is now synchronized through
`FetchService.calendarOpen`, with `Panel.qml` mirroring the actual Calendar
route state. The service derives the selected month from its shared selected
date and calls the existing bounded `CalendarFetch` owner; closing the route
cancels it. Month navigation continues to use the same owner and range
profiles.

Evidence: JavaScript fixtures, summon-helper tests, diff check, plugin
validation, and real-import-path QML lint pass. Actual Omarchy 4.0.0-1 /
Quickshell 0.3.0 restarted and summoned the linked plugin successfully with
no Sportray exception, binding loop, duplicate graph, or second shell. The
remaining manual calendar interaction could not be driven from this agent
session because the layer-shell popup did not retain keyboard focus and the
host has no supported pointer injector; no claim is made that visible calendar
cells were manually confirmed here.

Decision log: the calendar range path is implemented and now has an explicit
service lifecycle trigger. The next check should open Calendar through a real
pointer/focused interaction, confirm month cache files and visible known game
or empty cells, then scroll to both edges. Do not broaden unsupported MLB or
NCAA range hydration.
