# Competition and feature ideas

Private product-planning reference. Reviewed 2026-08-24 against the live
[Omarchy plugin catalog](https://omarchyplugins.com/catalog.json) and the
linked public repositories. Keep this file, the Marketplace review, and the
roadmap out of the public product tree unless the owner explicitly chooses to
publish planning material.

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
- bounded date navigation and empty-day next-game lookahead;
- ESPN-backed standings views with favorite actions;
- a local keyboard-accessible game-detail view projected from normalized data;
- automatic compact/full ambient bar presentation and live-favorite rotation;
- adaptive polling, bounded caches and responses, last-good snapshots, source
  attribution, and isolated provider failures;
- settings UI, keyboard/focus/accessibility coverage, and favorite-only,
  first-fetch-silent, deduplicated start/score/final notifications; and
- no account, key, backend, telemetry, database, or daemon.

These are deliberate differentiators and should not be traded away while
chasing feature count.

## Feature-parity backlog

Priority is based on user-visible leverage and fit with Sportray's existing
architecture.

### P0 — close the generalist gap

1. **Rich game detail.** Extend the existing local detail route with optional
   period/inning lines, scoring plays, leaders, and sport situation data. Keep
   the base record provider-neutral; providers may contribute bounded optional
   sections. Do not fetch a second endpoint until the provider contract and
   freshness behavior are explicit.
2. **Complete standings coverage.** ESPN standings work today, but NHL remains
   scores-only. Add a verified NHL standings adapter and preserve sport-aware
   ordering, neutral missing fields, and favorite actions.
3. **Alert depth.** Add independently configurable pregame reminders and
   close-game alerts. Keep team alerts separate from league browsing so a
   followed league does not become noisy by default.

### P1 — reliability and discovery

4. **Provider fallback chains.** Allow a league to name an ordered set of
   reviewed adapters, retaining last-good data and clearly identifying the
   active source. Start with a concrete, legally and operationally reviewed
   MLB or NHL fallback rather than building an abstract registry first.
5. **Broader team discovery.** Add search across supported competitions where
   the provider can return canonical identity, crest, and league metadata
   safely. Keep the catalog bounded and never persist provider display data as
   identity.
6. **Calendar and schedule context.** Add a bounded calendar view or larger
   schedule window for league destinations, with local-time rendering and
   direct date jumps. Preserve the existing five-day carousel as the fast path.

### P2 — specialist depth

7. **Sport-specific panels.** Add focused projections only when a provider
   supports them reliably: baseball situation, F1 session/leaderboard, or
   esports series state. These should be optional projections, not fields every
   `Game` must carry.
8. **Broadcast and event links.** Expose streams, VODs, standings pages, or
   event pages when the provider supplies safe, attributable URLs. Keep the
   existing labeled provider source action for every game.
9. **Venue and competition context.** Consider venue-local time, circuit
   weather/maps, and competition metadata after the generic detail and
   calendar foundations are stable.

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

## Recommended next slices

1. Implement and fixture-test the NHL standings adapter.
2. Add the first optional rich-detail section using an existing normalized
   ESPN fixture, without a new endpoint.
3. Add one opt-in pregame reminder policy and its notification deduplication
   coverage.
4. Reassess provider fallback and broader discovery only after those three
   slices have passed the existing runtime and privacy gates.

## Constraints

- Keep provider parsing in `providers/`; QML consumes normalized projections.
- Keep the no-account/no-backend/no-daemon default.
- Bound remote bytes, item counts, display strings, caches, and notification
  text before they reach QML or Omarchy helpers.
- Treat undocumented APIs, provider terms, asset rights, regional coverage,
  and rate limits as acceptance criteria, not documentation footnotes.
- Do not add Marketplace, release, tag, or public-repository work to a product
  feature slice.

