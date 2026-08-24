# Changelog

All notable changes to Sportray are documented here.

## Unreleased

- Assigned the local next release candidate as `1.0.0-rc.8` after the
  post-`1.0.0-rc.7` hardening work. The tree remains unreleased and untagged;
  no release date is asserted.
- Recorded the owner's confirmation that the personally captured `preview.png`
  may be submitted as shown, including its visible provider and team marks.
- Kept Omarchy's interactive safety confirmations in the documented install
  and removal commands, and clarified runtime dependencies, network access,
  privilege boundaries, and retained preference state.
- Reduced provider traffic with per-league due checks, bounded five-date and
  next-game caches, schedule-aware long polling windows, failure backoff, and
  per-session jitter. Score requests remain whole league/day slates rather
  than per-game calls, and fresh snapshots survive panel and date navigation.
- Removed completed planning records, obsolete QML components, a test-only
  lifecycle model, machine-specific test paths, and nonessential supporting
  screenshots from the public tree.
- Added repository ignore rules and restricted provider game actions to exact
  HTTPS ESPN and NHL hosts.
- Fixed clean-start popup placement so a right-side tray widget opens beneath
  its icon instead of being clamped to the top-left corner.
- Added inline venue names and restrained home-team color tints to score
  rows and next-game cards, with validated color and neutral fallback paths.
- Added labeled ESPN and NHL.com source actions to game rows and next-game
  cards. They open the provider game page in the Omarchy browser, with safe
  provider URL fallbacks when an event omits its optional link.
- Added a next-game lookahead for empty league days. The empty message remains
  first, followed by the first upcoming game and a one-click jump to its active
  league date.
- Added a **Send test notification** action under Settings → Notifications so
  users can preview the Omarchy alert channel without changing preferences or
  notification deduplication state.

## 1.0.0-rc.7

- Refreshed the local release candidate after provider-efficiency hardening:
  per-league request admission, bounded score and next-game caches,
  schedule-aware polling windows, failure backoff, and session jitter remain
  covered by the verified candidate.
- Updated the public preview to a focused 834×962 panel capture.
- Prepared the verified candidate and its Git tag for public availability. A
  GitHub Release and Marketplace submission remain separate publication steps.

## 1.0.0-rc.6

- Completed the public-release UI/UX pass with a current 16:9 Omarchy preview,
  light-theme, settings, and next-game supporting captures, plus favorite-first,
  eight-league, and no-account Marketplace copy.
- Kept sparse panels compact while resizing after a date or destination fetch
  settles, so navigating from a short slate to a dense slate grows the attached
  card without letting ordinary polling churn its height.
- Updated the local release candidate metadata to `1.0.0-rc.6`; no tag, push,
  GitHub release, or Marketplace submission was performed.

## 1.0.0-rc.5

- Added a compact date carousel for previous, current, and upcoming daily
  score slates; selected dates now drive provider queries and result filtering.
- Moved refresh into the fixed header and tightened score/settings hierarchy by
  removing repeated date, sport, destination, and Following/team labels.
- Refined the settings close action, settings helper copy, and score-only
  refresh visibility for a cleaner utility flow.
- Removed the redundant live-scores status row, added relative date labels and
  a clear return-to-today action, and prioritized the next scheduled favorite
  game in the ambient bar when available.
- Marked the verified local release candidate as a stopping point; no tag,
  push, GitHub release, or Marketplace submission was performed.

## 1.0.0-rc.4

- Added a bounded vertical sport chooser and virtualized grouped score slate
  for Following plus all eight supported leagues.
- Added stable scoreboard rows for scheduled, live, final, stale, and
  unavailable states with fixed team/logo and score columns.
- Unified sports, favorite-team, and notification preferences behind one
  settings hub with searchable favorites and canonical IDs.
- Added local semantic Omarchy icons, restrained sport atmosphere, and
  theme-aware light/dark and increased-text-scale layouts.
- Refreshed the release preview and completed the U2 actual-Omarchy runtime
  matrix; direct pointer/wheel injection remains an environment limitation.

## 1.0.0-rc.3

- Added the disabled-by-default MLS league with canonical `usa.1` routing,
  normalized soccer edge states, a bounded 30-team team catalog, soccer-aware
  formatting, and isolated polling/recovery.
- Added the disabled-by-default NCAA Men's Basketball league with canonical
  `mens-college-basketball` routing, normalized scheduled/live/halftime/final
  states, half-based formatting, a bounded 50-team provider-owned catalog, and
  isolated polling/recovery.
- Added the disabled-by-default NCAA Football league with canonical ESPN
  routing, normalized fixtures, bounded FBS-focused team selection, sport-
  correct football states, and isolated polling/recovery.
- Added the disabled-by-default English Premier League with canonical
  `eng.1` routing, normalized soccer edge states, a bounded current-season
  team catalog, soccer-aware formatting, and isolated polling/recovery.
## 1.0.0-rc.2

- Added a favorites-first Following home and stable per-league navigation.
- Pinned favorite games above each league slate and refreshed the compact
  score-card/header visual system.
- Separated Teams and notification preferences into nested utility
  destinations with keyboard focus and Escape restoration.
- Added stale-age/retry presentation and completed current-source dense-scroll
  and four-side Omarchy runtime verification.
- Refreshed the Marketplace preview for the redesigned panel.

## 1.0.0-rc.1

- Prepared the first release candidate for final fresh-install and Marketplace
  verification.

## 0.0.1

- Added a native Omarchy Quattro bar widget and nested scores panel.
- Added NHL, NFL, MLB, and NBA normalized scoreboard adapters.
- Added favorites, persistent settings, adaptive polling, stale/error
  isolation, and favorite-team notifications.
- Added keyboard navigation, theme-aware layouts, bounded dense panels, and
  fixture-driven verification.

The `v1.0.0-rc.7` Git tag identifies the `1.0.0-rc.7` release-candidate
snapshot. The current `1.0.0-rc.8` remains unreleased and untagged. A GitHub
Release and Marketplace submission are separate publication steps.
