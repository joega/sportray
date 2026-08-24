import QtQuick
import Quickshell.Io
import "../providers/EspnProvider.js" as EspnProvider
import "../providers/NhlProvider.js" as NhlProvider
import "../model/StandingsModel.js" as StandingsModel
import "../model/ResponsePolicy.js" as ResponsePolicy

// One shared, on-demand standings request. It intentionally does not join the
// scoreboard scheduler: opening a league table is an explicit view action and
// this first slice owns at most one active standings request.
Item {
  id: root

  property string leagueId: ""
  property var groups: []
  property var rows: []
  property bool hasData: false
  property bool loading: false
  property bool stale: false
  property string errorCode: ""
  property string errorSummary: ""
  property int partialErrorCount: 0
  property string lastSuccessAt: ""
  property string requestLeagueId: ""
  property string pendingResponseBody: ""
  property bool responseTooLarge: false
  property int requestGeneration: 0
  property int activeRequestGeneration: 0
  property bool ownerDestroyed: false

  function clear() {
    root.leagueId = ""
    root.groups = []
    root.rows = []
    root.hasData = false
    root.loading = false
    root.stale = false
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.lastSuccessAt = ""
  }

  function userSafeError(code) {
    if (code === "partial-data") return "Some standings could not be updated"
    if (code === "invalid-data") return "Standings could not be read"
    return "Standings are temporarily unavailable"
  }

  function parseBody(raw, targetLeague) {
    if (!raw || !ResponsePolicy.bodyWithinLimit(raw)) return null
    try {
      var payload = JSON.parse(raw)
      var parsed = targetLeague === "nhl"
        ? NhlProvider.parseStandingsResponse(payload)
        : EspnProvider.parseStandingsResponse(payload, targetLeague)
      if (!parsed || !Array.isArray(parsed.groups) || !Array.isArray(parsed.errors)) return null
      var groups = parsed.groups.map(function(group) {
        return {
          id: group.id,
          label: group.label,
          entries: Array.isArray(group.entries) ? group.entries : group.rows
        }
      })
      return StandingsModel.normalizeGroups(groups, targetLeague, parsed.errors)
    } catch (error) {
      return null
    }
  }

  function applyResult(result, targetLeague) {
    if (!result || !Array.isArray(result.groups) || !Array.isArray(result.rows)
        || !Array.isArray(result.errors)) {
      root.loading = false
      root.errorCode = "invalid-data"
      root.errorSummary = root.userSafeError(root.errorCode)
      root.stale = root.hasData
      return
    }

    root.loading = false
    root.leagueId = targetLeague
    root.groups = result.groups
    root.rows = result.rows
    if (result.errors.length > 0 && result.rows.length === 0) {
      root.hasData = false
      root.stale = false
      root.errorCode = "invalid-data"
      root.errorSummary = root.userSafeError(root.errorCode)
      root.partialErrorCount = result.errors.length
      return
    }

    root.hasData = true
    root.stale = result.errors.length > 0
    root.errorCode = result.errors.length > 0 ? "partial-data" : ""
    root.errorSummary = result.errors.length > 0 ? root.userSafeError(root.errorCode) : ""
    root.partialErrorCount = result.errors.length
    root.lastSuccessAt = new Date().toISOString()
  }

  function load(targetLeague, force) {
    if (root.ownerDestroyed || typeof targetLeague !== "string" || targetLeague === "") return false
    var url = targetLeague === "nhl"
      ? NhlProvider.buildStandingsUrl()
      : EspnProvider.buildStandingsUrl(targetLeague)
    if (!url) {
      root.leagueId = targetLeague
      root.groups = []
      root.rows = []
      root.hasData = false
      root.loading = false
      root.errorCode = "unsupported"
      root.errorSummary = "Standings are not available for this league"
      root.partialErrorCount = 0
      return false
    }
    if (!force && root.leagueId === targetLeague && (root.loading || root.hasData)) return false
    if (requestProcess.running) {
      root.activeRequestGeneration++
      requestProcess.running = false
    }

    root.requestGeneration++
    root.activeRequestGeneration = root.requestGeneration
    root.requestLeagueId = targetLeague
    root.leagueId = targetLeague
    root.loading = true
    root.errorCode = ""
    root.errorSummary = ""
    root.partialErrorCount = 0
    root.pendingResponseBody = ""
    root.responseTooLarge = false
    requestProcess.requestGeneration = root.activeRequestGeneration
    requestProcess.command = ["curl", "-fsSL", "--max-time", "10",
      "--max-filesize", String(ResponsePolicy.MAX_RESPONSE_BYTES), url]
    requestProcess.running = true
    return true
  }

  function refresh(targetLeague) {
    return root.load(targetLeague, true)
  }

  function snapshot() {
    return {
      leagueId: root.leagueId,
      groups: root.groups,
      rows: root.rows,
      hasData: root.hasData,
      loading: root.loading,
      stale: root.stale,
      errorCode: root.errorCode,
      errorSummary: root.errorSummary,
      partialErrorCount: root.partialErrorCount,
      lastSuccessAt: root.lastSuccessAt
    }
  }

  function appendChunk(chunk) {
    if (root.responseTooLarge) return
    var value = String(chunk || "")
    if (!ResponsePolicy.canAppend(root.pendingResponseBody, value)) {
      root.responseTooLarge = true
      if (requestProcess.running) requestProcess.signal(9)
      return
    }
    root.pendingResponseBody += value
  }

  Component.onDestruction: {
    root.ownerDestroyed = true
    root.activeRequestGeneration++
    if (requestProcess.running) requestProcess.running = false
  }

  Process {
    id: requestProcess
    running: false
    property int requestGeneration: 0

    stdout: SplitParser {
      splitMarker: ""
      onRead: function(data) {
        if (requestProcess.requestGeneration !== root.activeRequestGeneration
            || root.ownerDestroyed) return
        root.appendChunk(data)
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (requestProcess.requestGeneration !== root.activeRequestGeneration
          || root.ownerDestroyed) return
      var targetLeague = root.requestLeagueId
      var result = root.responseTooLarge ? null
        : root.parseBody(root.pendingResponseBody.trim(), targetLeague)
      if (!result) {
        root.loading = false
        root.errorCode = "invalid-data"
        root.errorSummary = root.userSafeError(root.errorCode)
        root.stale = root.hasData
        root.partialErrorCount = 0
      } else {
        root.applyResult(result, targetLeague)
      }
    }
  }
}
