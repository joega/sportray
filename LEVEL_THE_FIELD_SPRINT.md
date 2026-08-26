# Level the Field — Feature Catch-Up Sprint

Private implementation plan for `/home/joeg/Projects/sportray`.

Status: **C1 complete; remaining epics planned**

Owner direction recorded: **2026-08-25**

Sprint theme: close the most useful competitor gaps without turning Sportray
into a news, streaming, fantasy, or analytics application.

This file is the source of truth for the sprint. `roadmap.md` remains the
cross-session evidence and decision log; `NEXT_SESSION_PROMPT.md` always names
only the next bounded work unit. Every completed unit must update all three as
applicable and leave the plugin runnable.

## Sprint outcome

Ship five user-visible capabilities:

1. a real month calendar and schedule browser;
2. one-game watches with expiring notifications;
3. followed and ordered leagues, distinct from enabled leagues;
4. bounded scoring-play and leader detail when verified provider data exists;
5. bounded broadcast context and safe official viewing handoffs when verified.

The sprint is complete only when all accepted capabilities are implemented,
fixture-tested, documented, and exercised on actual Omarchy. A provider-gated
capability may finish in an explicitly documented unsupported state only when
the required source cannot be verified safely; it may not be simulated from
guesses or silently omitted.

## Why this sprint exists

Sportray has strong reliability, accessibility, favorites, standings, detail,
and notification foundations, but several competitors now answer common fan
questions more directly:

- Omatchday presents a genuine 6-by-7 monthly calendar with month navigation,
  event-bearing dates, Today, and a selected-date results route. Its default
  collection window is 45 days back and 90 days forward.
- Scores distinguishes team follows from league follows and exposes scoring
  plays and leaders in game detail.
- Sofascore allows users to pin and reorder leagues, filter match lists, and
  separate favoriting a game from enabling its notifications.
- Apple Sports lets users follow teams and leagues, schedule live tracking for
  one upcoming event, and inspect play-by-play and lineup detail.
- FotMob makes complete schedules and television context prominent.

Sportray's existing Calendar button does not yet meet that standard. It
projects five already-fetched dates into a horizontal strip and then reuses the
score screen's row list. Unvisited dates can look empty because there is no
month schedule owner. The old P1-6 conclusion is therefore reopened: the
cache-only calendar slice is complete as historical work, but calendar parity
is not complete as a product outcome.

## Product principles for the sprint

- The bar remains a glance surface. New depth belongs in the panel.
- The month calendar is a schedule surface, not another live polling graph.
- Unknown, loading, partial, empty, stale, and unavailable are distinct states.
  An unqueried day must never be labeled `No games`.
- Team favorites, league follows, and one-game watches express different user
  intent and must not be collapsed into one setting.
- Provider parsing stays in `providers/`; QML renders bounded normalized or
  presentation projections only.
- New remote work is bounded by bytes, item count, request count, time window,
  cache size, string length, retry count, and concurrent processes.
- Existing live-score polling, notification deduplication, last-good state,
  provider isolation, and one-in-flight-request-per-league behavior remain
  intact unless a unit explicitly replaces them with stronger verified rules.
- No account, API key, Sportray backend, telemetry, database, daemon, or
  downloaded executable code.
- Accessibility and keyboard operation are acceptance gates, not cleanup.
- Provider terms, geography, undocumented API risk, and source attribution are
  part of each feature gate.

## Baseline at sprint start

- Branch: `main` at committed detail presentation cleanup `ccfc099`.
- MLB StatsAPI fallback is committed at `cb53ded`.
- Deterministic baseline: 231 passing JavaScript tests.
- Installed host baseline: Omarchy `4.0.0-1`, Quickshell `0.3.0`, revision
  `28771c7c74b42e20afca0b1b63980cb46515537`.
- Generally applicable gates currently pass: JavaScript suite, summon-helper
  suite, `git diff --check`, actual-Omarchy plugin validation, and QML lint
  using `/usr/share/omarchy/shell` as the real import path.
- `docs/upstream-contract.md` is intentionally absent. Each host-boundary unit
  must inspect installed/current Omarchy and Quickshell sources directly.
- Settings are bounded schema 1 with opaque future-schema preservation.
- Score requests are capped at 2 MiB and 256 provider events.
- Each league retains a bounded five-date live-score cache.
- Calendar currently has a five-day strip, selected-day game rows, an
  All/Favorites filter, `C`, `F`, `G`, arrows, `[`/`]`, and Today behavior.
- Live football shapes for scoring plays, weather, and populated leaders have
  not yet passed the required in-progress observation gate.
- Live multi-provider failover selection is fixture-verified only.
- ESPN/static MLB team-ID drift remains unresolved and outside this sprint.

## Sprint-wide non-goals

- New sports or leagues, including WNBA, tennis, golf, racing, combat sports,
  or tournament expansion.
- News feeds, transfers, fantasy, predictions, social/chat, player ratings,
  xG, shot maps, or editorial personalization.
- Embedded video/audio, authenticated streaming, piracy-adjacent links, or
  claiming a station label is a playable stream.
- A per-game database, background daemon, or separate Quickshell process.
- Replacing provider fallback policy or reconciling existing team-ID drift.
- Packaging, tagging, pushing, GitHub Releases, Marketplace updates, or any
  other remote publication action.
- Opportunistic visual redesign outside the surfaces touched by an epic.

## Architecture map

```text
provider range/schedule payloads
          |
          v
 providers/*Provider.js       provider-specific validation/normalization
          |
          v
 services/CalendarFetch.qml   low-frequency visible-month ownership
          |
          v
 model/CalendarModel.js       pure month geometry, state, filters, summaries
          |
          v
 components/MonthCalendar.qml + existing selected-day GameRow/detail route

settings schema migration
          |
          +--> ordered followed leagues --> Following + destination order
          |
          +--> bounded watched games ----> existing transition/dedupe pipeline

verified scoreboard/detail payloads
          |
          +--> scoring plays/leaders --> GameDetailModel --> GameDetailView
          |
          +--> broadcast labels/links -> GameDetailModel --> rows/detail
```

The exact file names above are planning names, not mandates. Prefer extending
an existing owner when that preserves single ownership and clarity; do not
force all behavior into `Panel.qml` merely to avoid a new focused component.

## Epic 1 — Real month calendar and schedule browser

Priority: **P0**

Sprint order: **first**

Competitor pattern: Omatchday monthly calendar plus FotMob-style schedule
context.

### User outcome

Opening Calendar shows a conventional month rather than a five-card strip:

```text
‹  August 2026  ›                       Today
Mon   Tue   Wed   Thu   Fri   Sat   Sun
27    28    29    30    31     1     2
 3     4     5     6     7     8     9
10    11    12    13    14    15    16
17    18    19    20    21    22    23
24    25    26    27    28   [29]   30
31     1     2     3     4     5     6

All games | Favorites | Leagues
SAT, AUG 29 · 3 GAMES
[existing bounded selected-day game rows]
```

Each cell contains the day number and a restrained summary:

- selected and today have different, theme-safe treatments;
- a known day may show a bounded game count;
- a favorite-game marker is visually distinct from general schedule density;
- an empty day is marked empty only after a successful complete response;
- unknown/loading/partial/unavailable days never claim `No games`;
- adjacent-month dates remain visible and selectable.

Selecting any valid cell changes the selected date through the existing date
route. The selected day's games render below the grid and keep the existing
whole-row detail action, guarded source action, favorite tint, status, local
time, retry, and empty-state behavior.

### Interaction contract

- Calendar header action and `C` open/close the route.
- Left/Right move one day; Up/Down move one week while grid focus is active.
- Enter/Space selects the focused day.
- PageUp/PageDown move one month. Header previous/next buttons expose the same
  actions for pointer and assistive input.
- `T` returns to local today and its month.
- `F` toggles All games/Favorites.
- League filtering is reachable without requiring a pointer. The initial
  implementation may use a bounded menu rather than persistent chips.
- Escape closes game detail first, then a league-filter menu, then Calendar,
  then the panel.
- Existing `[`/`]` day navigation remains available unless fixture and runtime
  evidence shows an unavoidable conflict; do not silently repurpose it.
- Focus returns predictably to the invoking control or selected date.

### Month model contract

Keep date arithmetic pure and local-time aware. The model must:

- build exactly 42 cells for a requested month using a documented first-day-
  of-week choice;
- carry stable `YYYY-MM-DD` keys and reject impossible dates;
- distinguish `inMonth`, `isToday`, `isSelected`, `known`, `loading`, `partial`,
  `empty`, `stale`, and `unavailable` without deriving network truth in QML;
- deduplicate games by canonical normalized identity;
- cap per-day game counts and displayed league markers;
- expose filtered selected-day rows without duplicating `ResultRows` behavior;
- handle DST boundaries, year rollover, leap years, locale display strings,
  and adjacent-month cells deterministically;
- never infer empty from absent cache data.

### Fetch ownership contract

Calendar density requires a new low-frequency schedule concern; it must not
reuse live polling as a month crawler.

- Fetch only the visible 42-day grid plus, at most, one bounded adjacent cached
  grid in each direction.
- Cache by provider/league/window with a bounded LRU and explicit completeness.
- Historical complete windows revalidate no more often than 24 hours.
- Future schedule windows revalidate no more often than six hours unless a
  verified provider contract requires a longer interval.
- Today and selected-day live state continue to come from existing league
  score fetches; schedule hydration must not generate notifications.
- Closing Calendar cancels or ignores obsolete generations and prevents late
  responses from replacing a newer visible month.
- Only one calendar schedule request per league/provider owner may be in
  flight. Global concurrency must remain bounded.
- Retain last-good month summaries on transient failure and label them stale.
- A partial range response marks affected dates partial, never empty.

### Provider feasibility gate

The existing ESPN range URL builder is evidence that range-shaped scoreboards
exist, but it is not proof that one 42-day request is safe for every league.
MLB and college basketball can exceed the 256-event or 2 MiB boundary.

Before Calendar fetch implementation:

1. inspect installed code and current documented provider builders;
2. issue bounded, read-only range requests only to already accepted provider
   hosts and routes;
3. record status, content length when available, event count, date span, next-
   page/continuation shape, and elapsed time—never long-lived raw payloads;
4. verify ESPN range behavior for every ESPN-backed league family, NHL
   schedule continuation behavior, and MLB StatsAPI only if it is considered
   for schedule fallback under the already accepted owner terms;
5. derive a pure per-provider chunk planner with hard request ceilings;
6. stop instead of raising byte/event limits merely to make a month fit.

If safe full-month all-game density is impossible for a league, preserve the
month UI and degrade honestly: populate verified summaries where available,
show unknown elsewhere, and fetch a selected day through the existing path.
Favorite-only schedule endpoints may be considered only after the same
terms/shape/bounds review.

### Calendar work units

#### C1 — Month grid vertical slice

Status: **complete — 2026-08-25**

- Extend the pure calendar model with 42-cell month geometry and explicit
  known-versus-unknown summaries.
- Replace the five-day strip in Calendar mode with a focused month component.
- Use existing date caches for known summaries and existing selected-date
  fetching on cell selection; add no schedule crawler yet.
- Preserve selected-day rows, filters, details, and failure states.
- Fixture-test geometry, state distinctions, filters, routing, and bounds.
- Runtime-test pointer, keyboard, focus, height, themes, and panel edges.

Implemented evidence: CalendarModel now produces exactly 42 Monday-first
local-date cells with adjacent-month dates, selected/today flags, bounded
counts, favorite markers, and explicit unknown versus empty state. Cache
entries carry complete true only when admitted from a successful zero-error
score snapshot; absent dates remain unknown. MonthCalendar.qml replaces the
old week strip and routes pointer, Accessible, grid keyboard, month, and Today
actions through the existing selected-date path. The selected-day list keeps
the existing row/detail/source vocabulary and neutral loading/error/unknown
states. No new fetch, Process, timer, endpoint, polling, response, or cache
owner was added. Fixture coverage and actual Omarchy verification are recorded
in the roadmap handoff below.

This is the first sprint unit and must produce a visibly genuine calendar even
before background month hydration exists.

#### C2 — Provider range reconnaissance and chunk policy

Status: **complete — 2026-08-25**

- Bounded in-memory observations covered every ESPN-backed family, NHL schedule
  continuation, and the already owner-accepted MLB StatsAPI candidate. No raw
  response was retained.
- ESPN range responses had no continuation field: NFL and CFB were empty
  off-season responses; MLB, NBA, and MLS returned 100-event capped ranges;
  EPL returned 50 events. The men's college basketball route returned 404,
  so its in-season range behavior is unresolved.
- NHL returned seven `gameWeek` dates, 56 games, and `nextStartDate`; the
  continuation is suitable for a later bounded owner. The 42-day MLB StatsAPI
  request exceeded the existing 2 MiB admission boundary before inspection.
- `model/ChunkPolicy.js` is pure and fixture-tested. It plans at most 42 days,
  eight requests, one concurrent request, and seven-day chunks for accepted
  profiles; ESPN MLB is limited to one-day chunks. It rejects unsupported
  providers, invalid or oversized spans, status/byte/event violations,
  incomplete ranges, observed ESPN 100-event caps, and missing NHL
  continuation. Existing 2 MiB and 256-event limits are unchanged.
- C1 ownership remains unchanged: no QML, endpoint, Process, Timer, polling,
  cache, response-limit, or runtime range-fetch change was made. C3 must keep
  unresolved CFB/NCAA Men's Basketball range behavior unsupported and must not
  infer completeness from a capped or off-season response.

#### C3 — Low-frequency calendar fetch and cache

Status: **complete — 2026-08-25**

- `services/CalendarFetch.qml` owns one low-frequency NHL schedule process,
  plans the visible 42-day grid through `ChunkPolicy`, caps the cache at three
  windows, and keeps the existing live `LeagueFetch` processes unchanged.
- `NhlProvider.parseCalendarScheduleResponse` emits bounded normalized day
  buckets outside QML. `CalendarCachePolicy.js` merges canonical game IDs,
  preserves 42-day/request bounds, applies six-hour future and 24-hour
  historical freshness, and distinguishes loading, partial, stale, empty, and
  unavailable coverage.
- `FetchService` merges schedule and selected-day live snapshots for calendar
  projection; no schedule result enters notification state or replaces live
  polling ownership. Month open, navigation, and Today request only the
  visible-month schedule owner.
- Fixtures/source assertions cover provider normalization, missing-day partial
  coverage, live identity merge, freshness/cache bounds, generation-safe
  cancellation, one-process/zero-timer ownership, and no notification route.
- Deterministic JavaScript suite passes with 242 tests; summon-helper,
  `git diff --check`, actual Omarchy plugin validation, and full real-import-
  path QML lint (exit 0 with established warnings) pass.
- Actual Omarchy verification completed after the asynchronous widget-component
  load settled: one Quickshell shell remained running, ping returned `ok`, and
  rescan followed by the bounded summon helper produced a live Sportray slot
  at `right` (27x26). A fresh shell restart loaded the checkout and the
  changed Calendar route rendered a 42-cell September grid with unqueried
  dates labeled `Unknown`; PageDown/PageUp month navigation and rapid
  cancellation/replacement were exercised. Fresh logs contained normal
  Sportray startup with no plugin-load exception, QML error, or binding loop;
  only the unrelated pre-existing desktop-portal warning remained.

The prior registration blocker was a readiness race in the supported rescan /
summon sequence, not a broken manifest or a need to replace the symlink. No
second shell or other host process was started, and no destructive host change
was required. The registry's `active:false` field is not the live bar-instance
signal for ordinary bar widgets; `debugBarGeometry` and successful summon are
the relevant host evidence.
- Actual Omarchy has one Quickshell shell, enabled discovery, shell ping, and
  rescan success. The host's installed checkout is currently a symlink at
  `~/.config/omarchy/plugins/io.github.joega.sportray`; the shell reports the
  plugin `active:false`, and summon returns `no live bar widget`. Therefore
  first-open month hydration, fresh runtime logs, and changed-behavior
  exercise cannot be honestly claimed until the host plugin registration is
  restored. No success commit is created while this gate is blocked.

#### C4 — Calendar completion and polish

- Add bounded league filtering and complete keyboard/accessibility routes.
- Verify month navigation, year rollover, today reset, favorites filter,
  selected-day detail, partial provider failure, and cache reuse on Omarchy.
- Remove or retire the old week strip only when no other route consumes it.
- Update public README only after runtime behavior passes.

### Calendar acceptance gate

- A first-time Calendar open visibly renders a 42-cell current month.
- Any valid visible date can be selected, including adjacent-month dates.
- Unknown dates are not shown as empty.
- Favorite and league filters produce deterministic, bounded summaries.
- Month navigation cannot create unbounded requests or caches.
- Switching months rapidly cannot admit a late obsolete response.
- Existing live polling and notification transitions are unchanged.
- The selected-day list and detail route remain usable at the panel's bounded
  height on top, bottom, left, and right bars.

## Epic 2 — Watch one game

Priority: **P1**

Sprint order: after Calendar and the shared settings migration

Competitor pattern: Sofascore event favorite/bell separation and Apple Sports
scheduled live tracking.

### User outcome

A scheduled, live, or postponed game exposes a `Watch game` bell from its row
and detail view. Watching does not favorite either team. An active watch is
visible and can be removed from the same action.

Watched games enter the existing notification pipeline and may emit only the
globally enabled notification types:

- pregame reminder;
- game start;
- score change;
- close game;
- final;
- meaningful administrative change such as postponement only if a dedicated
  verified transition is added in its own unit.

If global notifications are disabled, the UI may store the watch but must say
that alerts are off and provide a direct Settings route; it must not silently
promise delivery.

### State contract

- Persist at most 32 watched games.
- Store only bounded normalized identity: canonical game ID, league, provider
  game ID when needed, normalized start time, created time, and expiry state.
- Never persist raw provider records, scores, team payloads, URLs, or arbitrary
  provider text.
- Deduplicate by canonical game identity.
- Expire after a verified final/canceled transition plus a short recovery
  window, or after a hard maximum when the provider never reports a terminal
  state. The pure expiry policy must cover postponements and clock skew.
- Restart recovery must remain first-fetch silent for already-active games.
- Watches must not broaden provider polling beyond enabled/fetched leagues
  without a separately accepted bounded rule.

### Notification contract

- Reuse existing transition detection, sanitization, argument-array delivery,
  deduplication, and notification settings.
- Extend favorite admission to `favorite game OR explicitly watched game` in
  one pure policy. Do not duplicate notification generation.
- A team favorite and watch for the same game produce one notification.
- Removing a watch stops future watch-derived notifications but does not remove
  team-favorite notifications.
- A watched-game final expires safely without mutating favorite teams.

### Watch work units

#### W1 — Watch policy and durable-state integration

- Consume the already-landed shared settings-schema migration described below.
- Add watch normalization, bounds, expiry, dedupe, and persistence fixtures.
- No row/UI or notifications in this unit.

#### W2 — Notification admission

- Extend pure notification, reminder, and close-game admission.
- Cover favorite-only, watch-only, both, removed, expired, malformed, restart,
  and disabled-notification cases.

#### W3 — Watch UI and runtime

- Add one semantic action shared by rows and detail.
- Provide active/inactive state, disabled reason, accessible name, and keyboard
  route.
- Exercise persistence, duplicate suppression, removal, and one safe stubbed
  delivery path on actual Omarchy.

### Watch acceptance gate

- A non-favorite game can be watched and survives a shell restart.
- Watch-derived and favorite-derived notifications deduplicate.
- Expired watches are removed within their bounded policy.
- Future-schema state remains opaque and unmodified.
- No notification is emitted from calendar schedule hydration alone.

## Epic 3 — Followed and ordered leagues

Priority: **P1**

Sprint order: after the shared settings migration; may follow or precede Watch
UI depending on file overlap

Competitor pattern: Scores team/league separation and Sofascore league pinning.

### Intent model

- **Enabled league:** available as a destination and eligible for ordinary
  score fetching under existing rules.
- **Followed league:** intentionally promoted on Following and Calendar and
  ordered relative to other followed leagues.
- **Favorite team:** promotes that team's games and enables favorite-aware
  alerts under existing settings.
- **Watched game:** temporary notification interest in one event.

Following a league is not equivalent to favoriting all teams. Followed leagues
remain silent by default during this sprint; league-wide notifications are a
separate future decision because they can be extremely noisy.

### User outcome

- Sports & Leagues settings show Enable and Follow as distinct semantic
  actions.
- Followed leagues can be moved up/down with pointer, keyboard, and assistive
  controls. Dragging is optional; accessible move buttons are mandatory.
- Following home shows favorite-team games first, then followed-league sections
  in user order, without duplicating games already shown as favorites.
- League destinations list followed leagues first in that order, followed by
  remaining enabled leagues in stable catalog order.
- Calendar's league filter follows the same ordering.
- Disabling a followed league either removes it from the followed set in one
  explicit atomic update or presents a clear confirmation; it must not retain
  unreachable ghost state.

### Followed-league model contract

- Persist one ordered, deduplicated, bounded array of canonical league IDs.
- Every followed league must be in `enabledLeagues` after normalization.
- Unknown, duplicate, disabled, malformed, and over-bound IDs fail closed.
- Migration from schema 1 starts with no followed leagues so existing users do
  not unexpectedly gain new home sections or polling.
- Reordering changes presentation only; it must not trigger notification
  transitions or bypass a fresh cache.
- Existing favorite-first ordering remains dominant within each destination.

### League work units

#### L1 — Pure intent/order model

- Extend settings normalization and presentation composition.
- Fixture-test subset enforcement, ordering, dedupe, migration, game dedupe,
  and stable non-followed catalog order.

#### L2 — Settings and navigation UI

- Add Enable, Follow, Move up, and Move down actions without nested-pointer or
  inaccessible toggle regressions.
- Apply followed order to Following, destinations, and calendar filter.

#### L3 — Runtime and documentation

- Exercise enabling, following, reordering, disabling, persistence, restart,
  and no-duplicate Following rows on Omarchy.

### League acceptance gate

- Team favorites, followed leagues, and enabled leagues remain visibly and
  behaviorally distinct.
- User order survives restart and cannot contain unavailable IDs.
- Following home never renders the same game twice.
- League reordering causes no provider or notification side effect beyond the
  already required enabled-league data.

## Shared settings migration — schema 2

Watches and followed leagues both require durable state. Perform one deliberate
migration rather than weakening schema 1 or adding unversioned keys.

### S1 — Migration foundation work unit

- Upgrade pure settings defaults, normalization, persistence projection, and
  state composition without adding watch or followed-league UI.
- Migrate schema 1 to schema 2 while preserving all compatible values.
- Add empty bounded `followedLeagues` and `watchedGames` fields for later units.
- Preserve future-schema write suppression, reload recovery, permissions, and
  atomic replacement.
- Exercise a real schema-1 state copy through migration and restart on Omarchy
  only after fixture and permission gates pass.

Proposed schema 2 shape:

```json
{
  "schemaVersion": 2,
  "enabledLeagues": ["nhl"],
  "favoriteTeamIds": [],
  "followedLeagues": [],
  "watchedGames": [],
  "notifications": {
    "enabled": false,
    "gameStart": true,
    "scoreChange": true,
    "gameFinal": true,
    "pregameReminder": false,
    "closeGame": false
  }
}
```

Final field names may change during the schema unit, but these rules may not:

- valid schema 1 migrates deterministically to schema 2 in memory and is
  persisted only through the existing safe write path;
- corrupt or missing state uses schema 2 defaults;
- schema greater than 2 remains opaque, uses safe defaults in memory, and is
  never rewritten until a compatible reload;
- permissions remain owner-only and atomic replacement remains intact;
- every array and record has explicit count and string bounds;
- existing notification values and canonical favorite IDs survive migration;
- downgrade behavior is documented; do not claim an older release can safely
  write schema 2;
- schema fixtures cover valid 1, valid 2, missing fields, invalid fields,
  future schema, corrupt JSON, permission behavior, and external reload.

Do not begin W1 or L1 until S1 has its own accepted commit and tests,
unless the team proves a smaller durable-state design that preserves every
future-schema and permissions guarantee above.

## Epic 4 — Scoring plays and leaders

Priority: **P1/P2**

Sprint order: after calendar and settings-backed features; reconnaissance can
run independently only when an eligible live event exists

Competitor pattern: Scores scoring-play/leader detail and Apple Sports
play-by-play.

### User outcome

Game detail may add two optional sections:

- **Recent scoring plays:** newest or most relevant bounded events with period,
  clock, team, score-after-play, and sanitized description when supplied.
- **Leaders:** bounded provider-defined categories with player/team identity and
  a concise display statistic.

These sections are absent, not placeholder-heavy, when the provider does not
support them. Existing lines, team stats, baseball situation, outcome, odds,
venue, and links remain independent optional sections.

### Evidence gate

- Observe only accepted providers and only the minimal payload shapes needed.
- The pending ESPN football inspection may proceed only while an NFL or
  college-football event is state `in`.
- Record keys, types, optionality, maximum observed counts, ordering, and
  identity relationships; do not retain a raw live payload.
- Existing sanitized fixtures may be expanded only from verified shapes.
- If scoreboard payloads remain insufficient, stop for an explicit terms,
  request-volume, and privacy review before considering a per-game summary
  endpoint. The old no-second-endpoint boundary is not silently waived by this
  sprint.

### Data bounds

Initial bounds to validate, not blindly implement:

- at most 12 scoring plays retained and at most 8 displayed initially;
- descriptions at most 160 characters after sanitization;
- period and clock use existing normalized timing vocabulary where possible;
- at most 6 leader categories and 3 entries per category;
- names and display values use existing safe-text bounds;
- unknown team/player identity remains neutral and never becomes a favorite ID;
- malformed one-off entries are rejected without discarding a valid whole
  game unless structural integrity requires it.

### Detail work units

#### D1 — Live shape observation

- Complete the bounded live-football observation when eligible.
- Decide scoreboard-only support independently for scoring plays and leaders.
- Update this plan and competition evidence; do not infer absent shapes.

#### D2 — Provider and pure detail projection

- Parse verified optional records outside QML.
- Add bounded model normalization and sanitized fixtures.
- Keep fields out of the universal game model if only detail consumes them.

#### D3 — Detail UI and runtime

- Add optional sections with bounded height and coherent headings.
- Exercise a real supported game when available; otherwise report fixture-only
  status explicitly and leave the unit incomplete if runtime is a stated gate.

### Detail acceptance gate

- Verified supported games show useful scoring/leader context.
- Unsupported games remain clean and do not imply missing data is an error.
- No raw provider text, unbounded collection, or unsafe player/team identity
  reaches QML.
- Detail remains within the half-screen panel cap and keyboard scrolling/focus
  remains usable.

## Epic 5 — Broadcast context and official handoff

Priority: **P2 quick win after provider verification**

Sprint order: last unless source evidence can be gathered independently

Competitor pattern: FotMob TV schedules and Apple Sports viewing handoff.

### User outcome

When a provider supplies broadcast information, scheduled and live game detail
shows a concise row such as:

```text
Broadcast · ESPN, ABC
```

A direct action appears only when the payload supplies or the provider contract
defines a verified safe official URL. A station name alone is useful and does
not require a link. Sportray must never construct arbitrary streaming URLs or
claim that a provider listing guarantees regional availability.

### Data contract

- Parse provider broadcast structures only after fixtures or bounded live
  evidence confirm their shape.
- Retain at most 3 deduplicated labels, each at most 40 characters.
- Sanitize control characters and option-like text through existing safe-text
  boundaries.
- Prefer provider order; do not guess primary versus secondary networks.
- Admit links only over HTTPS and only through explicit reviewed host/path
  allowlists. Reuse the existing browser launcher argument-array boundary.
- Label information as provider-supplied and document that availability varies
  by region. Sportray remains tested only in the United States.
- Do not add a new endpoint solely to discover television information without
  a separate provider/terms/request-volume decision.

### Broadcast work units

#### B1 — Source verification and model

- Inspect ESPN and NHL station-name shapes across scheduled/live fixtures.
- Add provider-specific parsing and pure bounded normalization.
- Decide separately whether any official link is actually supportable.

#### B2 — Presentation and runtime

- Render broadcast labels in detail; add a compact scheduled-row suffix only
  if it fits all panel widths without displacing score/status essentials.
- Add a guarded official action only if B1 accepted a URL boundary.
- Exercise scheduled and absent-broadcast cases on Omarchy.

### Broadcast acceptance gate

- Known station labels render clearly and deduplicate.
- Missing data renders no section rather than `Broadcast unavailable` noise.
- No unverified stream URL or regional promise is exposed.
- Browser routing remains host/path guarded and argument-array based.

## Cross-epic UX rules

- Use one semantic action per outcome. Pointer, keyboard, and assistive routes
  must converge on the same guarded function.
- Do not nest broad row MouseAreas over interactive child controls.
- Every toggle exposes current state and the action that activation will take.
- New icons require a reviewed semantic fallback letter/text and accessible
  name; icon-only meaning is insufficient.
- Keep focus visible under every theme and restore focus after drill-down,
  menus, and settings.
- Panel height is content-derived but bounded by the installed host's available
  card-height contract. Long sections scroll inside the existing panel rather
  than expanding the window off-screen.
- Top, bottom, left, and right bars must remain supported. Center placement
  remains centered; edge placement remains host-clamped.
- Theme colors may convey emphasis but never be the sole carrier of selected,
  live, favorite, watched, empty, or error state.

## Cross-epic testing matrix

Every applicable unit adds deterministic fixtures before runtime claims.

### Pure/model/provider checks

- happy path and every documented empty/unavailable/partial state;
- malformed records, wrong types, oversized arrays/strings, duplicate IDs,
  unknown IDs, invalid dates, and out-of-order responses;
- local dates around DST start/end, leap day, month/year rollover;
- provider response byte/event/request bounds;
- cache LRU, freshness, stale retention, generation cancellation, and retry;
- schema migration, future-schema opacity, corrupt recovery, and permissions;
- notification first-fetch suppression, dedupe, expiry, favorite/watch overlap;
- presentation ordering and no duplicate game rows;
- source/URL admission and rejected-host cases.

### QML/source checks

- provider parsing does not move into QML;
- new QML components contain no network URL construction or raw JSON parsing;
- Process count and ownership match the accepted architecture;
- semantic actions have pointer, keyboard, and Accessible routes;
- no source action is shadowed by a parent row action;
- bounded width/height and scroll ownership are explicit;
- destruction-time callbacks and stale signals fail closed.

### Required general gates

Run after every source-changing unit:

```bash
./tests/run-js-tests.sh
./tests/test-summon-helper.sh
git diff --check
omarchy plugin validate "$PWD"
/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell <every QML file>
```

On actual Omarchy after any runtime/QML/service/settings/notification change:

1. confirm exactly one Quickshell/Omarchy shell instance;
2. confirm plugin discovery and enabled state;
3. ping the shell and use the bounded summon helper;
4. restart the shell when rescan does not replace a live widget instance;
5. exercise the changed pointer and keyboard paths;
6. inspect fresh Quickshell logs for Sportray errors, QML load failures,
   exceptions, binding loops, late callbacks, or duplicate graphs;
7. record host version, instance identity, exercised state, and known unrelated
   warnings in `roadmap.md`.

Never report an actual-Omarchy gate from fixture or lint evidence alone.

## Sprint work-unit order

The expected order is:

1. **C1:** true month-grid vertical slice using current caches and selected-day
   fetching;
2. **C2:** schedule provider reconnaissance and pure chunk policy;
3. **C3:** low-frequency visible-month fetch/cache;
4. **C4:** calendar filters, accessibility, runtime completion, and docs;
5. **S1:** shared schema-2 migration foundation;
6. **W2/W3:** watched-game notification admission and UI;
7. **L1/L2/L3:** followed-league model, UI, ordering, and runtime;
8. **D1:** eligible live scoring-play/leader observation;
9. **D2/D3:** supported detail parsing and UI;
10. **B1/B2:** broadcast verification, model, and presentation;
11. sprint-wide regression audit and public README reconciliation.

Watches and followed leagues may swap after S1 to reduce file overlap, but one
must finish before the other starts. D1 may run during an eligible live event
without delaying unrelated work, but it must not edit files concurrently with
another unit. Subagents are appropriate only for independent, read-only source
reconnaissance or separate test/log investigation.

## Commit and handoff discipline

- One bounded work unit per commit.
- Use imperative Conventional Commit-style subjects where practical.
- Do not mix opportunistic cleanup with a feature unit.
- Do not weaken bounds or acceptance tests to finish a unit.
- A source-changing unit is committed only after its gate passes.
- A blocked unit records the blocker without marking its epic complete.
- After each unit, update:
  - this file's status and relevant evidence;
  - `roadmap.md` milestone status, evidence, decision log, risks, and handoff;
  - `competition.md` only when parity evidence or priority changes;
  - `NEXT_SESSION_PROMPT.md` with exactly one self-contained next unit.
- Do not push, tag, release, or update Marketplace state during the sprint.

## Sprint definition of done

- Calendar is a real 42-cell month schedule browser with honest completeness,
  selected-day drill-down, filters, bounded background hydration, keyboard,
  accessibility, and actual-Omarchy verification.
- Any game can be watched independently of favorite teams; watches persist,
  deduplicate, expire, and reuse notification safety guarantees.
- Leagues can be followed and ordered independently of enabling them; home,
  navigation, and calendar honor the order without duplicate games.
- Verified providers expose bounded scoring plays/leaders where supported;
  unsupported games remain clean.
- Verified broadcast labels render with region-safe wording and only guarded
  official links.
- Schema 1 migrates safely to schema 2 and future schemas remain opaque.
- All deterministic and runtime gates pass at the sprint head.
- README accurately documents shipped behavior and limitations.
- Roadmap contains evidence for every epic and a final sprint decision log.
- The final sprint tree is committed atomically by unit and remains unpushed
  unless the owner separately authorizes remote action.

## Known sprint risks and decisions still open

- ESPN is an undocumented website API and may change without notice.
- A 42-day all-game range can exceed current byte/event limits, especially for
  MLB and college basketball. Chunking must be evidence-driven and request-
  bounded; raising limits is not the default answer.
- NHL schedule pagination/continuation was verified for C3 through the current
  `gameWeek`/`nextStartDate` contract; historical/provider coverage remains a
  bounded runtime risk and must not be treated as complete beyond admitted
  windows.
- Month density from partial providers must not be mistaken for complete data.
- Settings schema 2 is a one-way feature upgrade unless downgrade behavior is
  explicitly implemented and tested.
- Watched games may refer to disabled leagues; the schema unit must decide
  whether to reject, auto-enable with explicit consent, or retain silently but
  not poll. Default recommendation: reject the watch with a clear enable-league
  action rather than mutating settings implicitly.
- Live scoring-play/leader support remains gated on an actual in-progress
  event. Do not delay Calendar or settings work while waiting.
- Provider station names are not regional availability guarantees and are not
  stream URLs.
- The current ESPN/static MLB team-ID drift and fixture-only runtime fallback
  selection remain outside sprint scope.
- Release metadata, asset rights, and publication remain owner-controlled
  follow-ups after the feature sprint.

## Current handoff

C1, C2, and C3 are complete. Begin with **C4 — Calendar completion and
polish** only. The C3 runtime gate was verified on actual Omarchy with one
shell, one NHL calendar `Process`, bounded hydration, honest unknown/partial
states, and generation-safe month replacement. The self-contained prompt is
maintained in `NEXT_SESSION_PROMPT.md`.
