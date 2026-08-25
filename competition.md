# Competition and feature ideas

Private product-planning reference. Reviewed 2026-08-24 against the live
[Omarchy plugin catalog](https://omarchyplugins.com/catalog.json) and the
linked public repositories. Backlog status last reconciled 2026-08-24 after
the broader team discovery unit closed P1-5. Keep this file, the Marketplace review, and the
roadmap out of the public product tree unless the owner explicitly chooses to
publish planning material. Backlog reconciled again 2026-08-24 after the
baseball situation detail slice closed part of P2-7.

## Similar apps

### General-purpose scoreboards

| App | What it does | Ideas worth borrowing |
| --- | --- | --- |
| [Scores](https://github.com/meirdick/omarchy-scores) | Broad multi-sport scoreboard with teams, leagues, standings, game detail, alerts, and event sports | Distinguish team follows from league follows; league pages centered on standings; live-game bar rotation; sport-aware standings order; provider fallback chains; conditional requests and watchdogs; pure fixture-tested model layer |
| [Sportsbar](https://github.com/cgmccarron/omarchy-sportsbar) | Lightweight favorite-team cards for the major US leagues and soccer | Simple onboarding; theme-matched team colors; explicit favorite-card focus; graceful logo alternatives |
| [Omatchday](https://github.com/brm-src/omatchday) | Football match center with upcoming, live, results, and calendar views | Calendar navigation; in-panel settings; pull-to-refresh; pregame plus kickoff alerts; last-known state while refreshing |
| [OmaSoccer](https://github.com/Popidge/omasoccer) | Multi-club football ticker spanning many competitions | Cross-competition club discovery; smart/priority/cycle bar behavior; compact and icon modes; adaptive polling around kickoff; schema-documented settings |

### Focused sports and tracking apps

| App | Specialty | Ideas worth borrowing |
| --- | --- | --- |
| [MLB Booth](https://github.com/jeremylongshore/omarchy-mlb-booth-entry) | Deep single-team baseball | Inning line score, R/H/E, count, outs, bases, last play, weekly schedule, division race, and explicit postponed/delayed/doubleheader handling |
| [Pit Wall](https://github.com/jeremylongshore/omarchy-pit-wall-entry) | F1 weekend and live timing | Countdown that becomes live timing; leaderboard gaps; race-control state; schedule plus driver/constructor standings; live-only high-frequency polling |
| [F1 Sessions](https://github.com/matteodevenuto/omarchy-f1-sessions) | F1 session calendar | Next-session alerts, local timezone rendering, fallback APIs, season rollover, and bounded remote data |
| [Next Race](https://github.com/salmun-nister/omarchy-next-race) | F1 race-weekend context | Track map, circuit weather, local/track time toggle, and off-season next-season behavior |
| [Esports](https://github.com/matt-shearing/omarchy-esports-plugin) | Spoiler-free esports schedule | Make spoiler policy a data-layer rule; catch-up masking; direct streams, VOD, and event links. Requires a companion daemon, so this is inspiration rather than a default dependency. |
| [VCT Scoreline](https://github.com/SeeSharpSi/omarchy-vct-scoreline) | Top-tier Valorant | Narrow sport-specific state: map score, series score, current map, round, and attacking side |

## What Sportray already covers

The current checkout now has meaningful parity with the generalists:

- eight leagues, canonical team favorites, a Following home, and stable league
  destinations;
- bounded cross-league team discovery in the favorite picker (league-name
  queries, ranked matches, clamped query and capped results) over the static
  catalogs;
- bounded date navigation and empty-day next-game lookahead;
- grouped standings on ESPN-backed and NHL destinations (verified
  `api-web.nhle.com/v1/standings/now` adapter) with favorite actions;
- a local keyboard-accessible game-detail drill-down projected from normalized
  data, with optional final-outcome, bounded per-period lines, bounded team
  statistics, a bounded live baseball situation section, labeled ESPN event
  links, and no second endpoint;
- a bounded calendar day list projecting the already-fetched five-date
  caches, with favorite-only filtering, an `F` filter shortcut, a `G`
  direct jump to the next cached day with games, and explicit local-time
  row labels; it never starts new requests;
- automatic ambient bar presentation: icon-only tray with accent/urgent status
  dots on horizontal and vertical bars, live-favorite rotation, and countdown
  projection feeding the indicator state;
- adaptive polling, bounded caches and responses (2 MiB transport, streamed
  admission, 256-event cap), last-good snapshots, per-league provider fallback
  chains with cooldown/isolation, source attribution, and fixture coverage;
- settings UI, keyboard/focus/accessibility coverage, and favorite-only,
  first-fetch-silent, deduplicated start/score/final notifications plus opt-in
  pregame reminders and close-game alerts; and
- no account, key, backend, telemetry, database, or daemon.

These are deliberate differentiators and should not be traded away while
chasing feature count.

## Feature-parity backlog

Priority is based on user-visible leverage and fit with Sportray's existing
architecture. Status reconciled 2026-08-24 against the roadmap acceptance
evidence.

### P0 — close the generalist gap

1. **Rich game detail — partially closed.** The local detail route now renders
   an optional final-outcome section, bounded per-period lines, and bounded
   team statistic rows (MLB hits/errors) projected from the already normalized
   ESPN scoreboard snapshot, with neutral placeholders for nulls. The runtime
   scoreboard parse now carries the same optional records the fixtures
   verified (closed 2026-08-24: a live MLB drill-down rendered the situation
   and team-stat sections at runtime, with sport-aware "SCORING BY
   INNING/QUARTER/HALF/PERIOD" headers). Still open:
   scoring plays, leaders, and sport situation data beyond baseball; these
   require verified provider fields before any adapter work.
2. **Complete standings coverage — closed.** The NHL standings adapter is
   implemented and live-verified (conference grouping, `conferenceSequence`
   ordering, tri-code resolution through the bounded catalog); ESPN standings
   were already shipped. Sport-aware ordering beyond conference/league
   sequence remains future depth, not a parity gap.
3. **Alert depth — closed.** Independently configurable, favorite-only pregame
   reminders (30-minute window) and close-game alerts (tied or one-score
   margin on transition) shipped through the existing notification/dedupe
   pipeline, both default-off.

### P1 — reliability and discovery

4. **Provider fallback chains — wiring closed; multi-provider open.** The pure
   chain policy is wired into every per-league score request with cooldown,
   last-good retention, isolation, and exhaustion handling. Production chains
   are single-candidate because each league has exactly one verified adapter.
   Live multi-provider fallback requires a second reviewed adapter (for
   example an MLB or NHL alternative source) and remains open until that
   provider's terms, reliability, and response shape are verified.
5. **Broader team discovery — closed.** The favorite picker discovers teams
   across all eight leagues from the bounded static catalogs: queries match
   league display names (e.g. "premier", "college"), direct hits rank above
   broader matches, the query is clamped at 48 characters, and non-empty
   search results are capped at 60 while unfiltered browsing stays complete.
   No new endpoint; canonical identities and schema-1 settings unchanged.
 6. **Calendar and schedule context — closed for the current cache
    boundary.** The bounded calendar day list with favorite-only filtering,
    the preserved five-day carousel, direct `G` date jumps to the next
    cached day with games, explicit local-time row labels, and the
    week-strip overview (per-day counts, favorite dots, selected-day
    drill-down replacing the shared date chrome while the calendar is
    open) are shipped and runtime-verified. Still open only: any window
    wider than the five-date caches, which requires a verified wider
    source before any new fetch ownership.

### P2 — specialist depth

7. **Sport-specific panels — partially closed.** The baseball situation
   section (count, outs, base occupancy, last-play text) shipped 2026-08-24 as
   a bounded game-detail projection from the already fetched ESPN scoreboard
   snapshot, hidden when the sport has no situation data. Still open: F1
   session/leaderboard, esports series state, racing projections, and scoring
   plays/leaders (scoring plays could not be verified live on 2026-08-24 — no
   football game was in progress). Optional sections only when a provider
   supports them reliably; never fields every normalized game must carry.
   Scoring-play live verification was attempted 2026-08-24 ~9:00 PM EDT and
   blocked: no football game was in progress (NFL preseason concluded, CFB
   begins Aug 29) and completed-game scoreboards again carried no
   `competitions[].details`. Retry during CFB week 0 (from Aug 29) or NFL
   week 1 (from Sep 10); see the roadmap blocked-handoff entry.
8. **Broadcast and event links — closed for the current payload boundary.**
   Completed 2026-08-24: the detail view renders at most two labeled links
   (ESPN **Highlights** video page, ESPN **Preview** article) admitted from the
   already-fetched scoreboard snapshot through the reviewed HTTPS/espn.com
   host boundary, beside the unchanged labeled source action. Broadcast
   streams stay closed because ESPN and NHL payloads carry station names only,
   never stream URLs; any stream/VOD surface would require a verified new
   source.
9. **Venue and competition context — open.** Venue-local time, circuit
   weather/maps, and competition metadata after generic foundations remain
   stable. Venue text itself is already shown on cards and in detail.

## Product principles taken from the scan

- The bar is a glance surface: show live state, the next relevant event, or a
  calm status indicator; put depth in the panel.
- Team following and league following answer different questions and should
  not share alert semantics.
- Empty days are not dead ends: standings, calendar context, or a next-game
  jump should make the league view useful year-round.
- Sport-specific detail is valuable, but a universal model should stay small,
  optional, and provider-neutral.
- Reliability is a feature: adaptive cadence, conditional requests, bounded
  responses, last-good data, explicit stale/unavailable states, and fixture
  coverage matter as much as feature count.
- Beautiful means coherent under every Omarchy theme, bar orientation, dense
  panel width, keyboard path, and degraded network state.

## Recommended next slices — awaiting owner direction

All three previously recommended slices (NHL standings adapter, first optional
rich-detail sections, opt-in pregame reminder policy) plus the close-game
alerts, calendar, provider-fallback, team-statistics, and broader team
discovery follow-ups have landed and passed the runtime/privacy gates. The
owner directed on 2026-08-24 that all candidate slices will be completed in
sequence; the agreed order is calendar extensions, then broadcast/event links,
then a second verified provider adapter (requires explicit terms/region/
reliability review), then owner-controlled release/publication follow-ups.
Remaining candidate slices:

1. **Calendar extensions** (P1-6 remainder): completed 2026-08-24 — direct
   `G` date jumps and explicit local-time labels within the cache-only
   boundary; a wider window stays open only behind a verified wider source.
2. **Broadcast/event links** (P2-8): completed 2026-08-24 — safe attributable
   ESPN Highlights/Preview pages rendered beside the labeled source action;
   streams remain out of scope without a verified new source.
3. **A second verified provider adapter for live multi-provider fallback**
   (P1-4 remainder): requires an explicit provider review (terms, region,
   reliability, response shape) before `providerChain()` gains a second
   candidate for any league.
4. **Richer detail sections** (P0-1 remainder / P2-7): the baseball situation
   projection completed 2026-08-24 from already normalized data with no second
   endpoint, and the runtime detail path was wired through the same enriched
   parse the same day (live-verified on an MLB game). Still open: scoring
   plays (requires live verification while a football game is in progress) and
   leaders; stop before any second endpoint.
5. **Release/publication follow-up**: owner-assigned release actions for the
   unreleased `1.0.0-rc.8` candidate (tagging/release/Marketplace verification)
   remain separate, owner-controlled steps outside feature work.

## Constraints

- Keep provider parsing in `providers/`; QML consumes normalized projections.
- Keep the no-account/no-backend/no-daemon default.
- Bound remote bytes, item counts, display strings, caches, and notification
  text before they reach QML or Omarchy helpers.
- Treat undocumented APIs, provider terms, asset rights, regional coverage,
  and rate limits as acceptance criteria, not documentation footnotes.
- Do not add Marketplace, release, tag, or public-repository work to a product
  feature slice.

