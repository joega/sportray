Work in `/home/joeg/Projects/sportray` on exactly one bounded work unit:
runtime-verify multi-league calendar range hydration and the existing vertical
month scroll/edge transition.

Before editing or testing, read `AGENTS.md`, `README.md`, `roadmap.md`, and
this prompt with the latest roadmap handoff. If `docs/upstream-contract.md` is
absent, inspect the installed/current Omarchy and Quickshell sources directly
and record any material boundary deviation.

Verified current state:

- ESPN's existing `/scoreboard?dates=YYYYMMDD-YYYYMMDD` route is implemented
  by `EspnProvider.buildNextGamesUrl()` and its normalized response is grouped
  into complete local-date buckets by `parseCalendarRangeResponse()`.
- `CalendarFetch.qml` queues bounded seven-day chunks for enabled NHL, NFL,
  NBA, Premier League, and MLS month hydration through one cancellable
  `Process`; `FetchService.qml` merges per-league schedule snapshots with live
  and disk state.
- MLB and both NCAA leagues remain selected-day-only because their range
  profiles are not admitted. NHL retains its rolling background schedule.
- Deterministic tests, plugin validation, diff check, summon-helper tests, and
  real-import-path QML lint pass. No live interaction has yet verified that
  the opened calendar visibly receives the multi-league range data.

Bounded outcome: on actual Omarchy, obtain a live Sportray bar-widget,
enable or use at least one ESPN calendar league, open Calendar, and verify
that known game and empty days populate without clicking each day. Verify
that the vertical week stream still scrolls in both directions, that reaching
an edge requests the adjacent month, and that unknown days remain unknown.
Inspect fresh Quickshell logs for exceptions, duplicate graphs, or binding
loops. Do not change provider profiles, admit MLB/NCAA ranges, widen limits,
alter polling/notifications/settings, or change packaging/release/remote
state.

Required checks: `./tests/run-js-tests.sh`, `./tests/test-summon-helper.sh`,
`git diff --check`, `omarchy plugin validate "$PWD"`, and
`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell` over every QML file.
If the live widget or supported input path cannot be obtained, record the
blocker and stop without a success commit. When the runtime gate passes,
update `roadmap.md`, refresh this prompt for the next single unit, and create
one atomic Conventional Commit.

Known risks: widget registration may race after rescan; Wayland pointer and
AT-SPI injectors may be unavailable; a full month requires multiple sequential
range requests per enabled provider; and ESPN remains an undocumented API.
Request subagents only for independent read-only source or log inspection.

Current fix context: the calendar owner preserves the requested month across
an enabled-league readiness race and retries the bounded request through the
same owner. The panel opens Calendar before requesting its month, the panel
height reserves the real six-week viewport, and `MonthCalendar.qml` suppresses
edge callbacks until its three-page list is recentered. These fixes pass all
source gates, but the actual pointer/scroll interaction gate is still blocked
on this host because the summoned panel did not receive keyboard focus and no
supported pointer injector is installed.

The latest correction also synchronizes `Panel.calendarOpen` into the shared
`FetchService.calendarOpen` lifecycle. The service derives the selected month
and starts the existing `CalendarFetch` owner when that route opens, and
cancels it when the route closes. This was added after the actual cache showed
only selected-day files, proving that the earlier view-only trigger had not
been observed in runtime.

The latest projection fix adds `knownLeagueIds`: the calendar still displays
all enabled leagues' cached games, but only leagues admitted by
`CalendarFetch.eligibleLeagues()` are required to certify a date as known.
This prevents enabled selected-day-only MLB/NCAA leagues from making all
hydrated ESPN/NHL dates appear Unknown.
