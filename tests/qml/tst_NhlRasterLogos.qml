import QtQuick
import QtTest
import "../../providers/NhlProvider.js" as NhlProvider
import "../../providers/NhlTeamCatalog.js" as NhlTeamCatalog

TestCase {
  name: "NhlRasterLogos"

  function fixture(name) {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../fixtures/nhl/" + name + ".json"), false)
    request.send()
    return JSON.parse(request.responseText)
  }

  function init() {
    failOnWarning(/.?/)
  }

  function test_mapping_data() {
    return fixture("raster-logos").teams.map(function(team) {
      team.tag = team.abbreviation
      return team
    })
  }

  function test_mapping(data) {
    // Actual QML imports have no CommonJS require or TeamModel/AssetUrlPolicy.
    var expected = "https://a.espncdn.com/i/teamlogos/nhl/500/" + data.suffix + ".png"
    var raw = {id: Number(data.nhlId), abbrev: data.abbreviation, name: {default: data.name},
      logo: "https://assets.nhle.com/logos/nhl/svg/" + data.abbreviation + "_light.svg"}
    var event = {id: 2026020010, awayTeam: raw, homeTeam: raw, gameState: "LIVE"}
    var score = NhlProvider.parseScoreResponse({games: [event]}).games[0].awayTeam
    var scheduled = NhlProvider.parseScheduleResponse({gameWeek: [{games: [event]}]}).games[0].awayTeam
    var standing = NhlProvider.normalizeStandingsEntry({teamAbbrev: data.abbreviation}).team
    var discovered = NhlTeamCatalog.normalizeTeamRecord({id: Number(data.nhlId),
      fullName: data.name, triCode: data.abbreviation, teamLogo: raw.logo})
    var bundled = NhlTeamCatalog.listTeams().filter(function(team) {
      return team.providerTeamId === data.nhlId
    })[0]
    ;[score, scheduled, standing, discovered, bundled].forEach(function(team) {
      compare(team.id, "nhl:" + data.nhlId)
      compare(team.providerTeamId, data.nhlId)
      compare(team.logoUrl, expected)
    })
  }

  function fallbackTeam(url) {
    return NhlTeamCatalog.normalizeTeamFallback({league: "nhl", providerTeamId: "6", logoUrl: url})
  }

  function test_fallbackHostPolicies() {
    var policy = fixture("raster-logo-policy")
    policy.acceptedHosts.forEach(function(url) {
      compare(NhlProvider.safeLogoUrl(url), url)
      compare(fallbackTeam(url).logoUrl, url)
    })
    policy.rejectedUrls.forEach(function(url) {
      compare(NhlProvider.safeLogoUrl(url), null)
      compare(fallbackTeam(url).logoUrl, null)
    })
  }

  function test_unmappedAndMalformed() {
    var policy = fixture("raster-logo-policy")
    policy.unmappedIds.forEach(function(id) {
      var team = NhlProvider.normalizeTeam({id: id, name: {default: "Unmapped team"},
        abbrev: "UTA", logo: policy.acceptedHosts[0]})
      compare(team.name, "Unmapped team")
      compare(team.abbreviation, "UTA")
      compare(team.logoUrl, null)
      compare(NhlTeamCatalog.normalizeTeamRecord({id: id, fullName: "Unmapped team", triCode: "UTA"}), null)
    })
    policy.malformedIds.forEach(function(id) {
      compare(NhlProvider.normalizeTeam({id: id}), null)
      compare(NhlTeamCatalog.normalizeTeamRecord({id: id, fullName: "Malformed team", triCode: "UTA"}), null)
    })
    policy.untrustedFeedLogos.forEach(function(url) {
      compare(NhlProvider.normalizeTeam({id: 68, logo: url}).logoUrl,
        "https://a.espncdn.com/i/teamlogos/nhl/500/utah.png")
    })
  }
}
