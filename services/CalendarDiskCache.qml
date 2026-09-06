import QtQuick
import Quickshell
import Quickshell.Io
import "../model/CalendarDiskCachePolicy.js" as CachePolicy
import "../model/DateModel.js" as DateModel

// Durable normalized calendar snapshots. Cache bytes are read, written, and
// pruned only by the descriptor-bound helper; QML keeps the existing queue and
// normalization boundary but never resolves a cache pathname for I/O.
Item {
  id: root

  readonly property string cacheRoot: Quickshell.env("HOME") + "/.cache/sportray/calendar"
  property bool ready: false
  property var entries: ({})
  property var readQueue: []
  property var writeQueue: []
  property var cleanupQueue: []
  property string activeReadKey: ""
  property var activeWrite: null
  property string pendingWriteName: ""
  property string pendingWriteText: ""
  property string helperOperation: ""
  property string helperName: ""
  property string todayDateKey: DateModel.localDateKey(new Date())

  function fileNameFor(entry) { return CachePolicy.fileName(entry.leagueId, entry.dateKey) }

  function snapshotFor(leagueId) {
    var days = []
    var prefix = String(leagueId || "").toLowerCase() + ":"
    for (var id in root.entries) {
      if (id.indexOf(prefix) !== 0) continue
      var entry = root.entries[id]
      if (entry) days.push({dateKey: entry.dateKey, games: entry.games || [], complete: true})
    }
    days.sort(function(left, right) { return left.dateKey.localeCompare(right.dateKey) })
    return {leagueId: String(leagueId || "").toLowerCase(), days: days}
  }

  function coverageFor(leagueIds, dateKeys) {
    return CachePolicy.coverage(root.entries, leagueIds, dateKeys, root.todayDateKey)
  }
  function windowDateKeys() { return CachePolicy.windowDateKeys(root.todayDateKey) }
  function hydrationRanges(leagueIds, dateKeys, maxRangeDays) {
    return CachePolicy.hydrationRanges(root.entries, leagueIds, dateKeys, root.todayDateKey, maxRangeDays)
  }
  function shouldRequestMonth(leagueIds, dateKeys) {
    return CachePolicy.shouldRequestRange(root.coverageFor(leagueIds, dateKeys), root.ready)
  }

  function enqueueReads(keys) {
    root.readQueue = []
    keys.forEach(function(value) {
      var parts = CachePolicy.keyParts(value)
      if (parts && CachePolicy.inWindow(parts.dateKey, root.todayDateKey)) root.readQueue.push(value)
      else if (parts) root.queueCleanupForKey(value)
    })
    Qt.callLater(root.readNext)
  }

  function queueCleanupForKey(value) {
    var parts = CachePolicy.keyParts(value)
    if (!parts) return
    var name = CachePolicy.fileName(parts.leagueId, parts.dateKey)
    if (root.cleanupQueue.indexOf(name) < 0 && root.helperName !== name) root.cleanupQueue.push(name)
    root.flushCleanup()
  }

  function retain(next) {
    var kept = CachePolicy.prune(next, root.todayDateKey)
    for (var id in next) if (next[id] && !kept[id]) root.queueCleanupForKey(id)
    root.entries = kept
  }

  function startHelper(operation, name, text) {
    if (cacheHelper.running || root.helperOperation !== "") return false
    root.helperOperation = operation
    root.helperName = name
    root.pendingWriteText = text || ""
    cacheHelper.command = ["/usr/bin/python3", "-I", "-S", root.helperPath, operation, name]
    cacheHelper.running = true
    return true
  }

  function readNext() {
    if (cacheHelper.running || root.helperOperation !== "") return
    if (root.readQueue.length === 0) {
      root.activeReadKey = ""
      root.ready = true
      root.flushCleanup()
      return
    }
    root.activeReadKey = root.readQueue.shift()
    var parts = root.activeReadKey.split(":")
    root.startHelper("read", CachePolicy.fileName(parts[0], parts[1]), "")
  }

  function applyDayText(raw) {
    var parts = root.activeReadKey.split(":")
    var entry = CachePolicy.parseDayText(raw, parts[0], parts[1], root.todayDateKey)
    if (entry) {
      var next = {}
      for (var id in root.entries) next[id] = root.entries[id]
      next[root.activeReadKey] = entry
      root.retain(next)
    }
  }

  function persistStates(states) {
    if (!root.ready || !Array.isArray(states)) return
    root.todayDateKey = DateModel.localDateKey(new Date())
    states.forEach(function(state) {
      if (!state || typeof state.leagueId !== "string" || !Array.isArray(state.days)) return
      state.days.forEach(function(day) {
        if (!day || day.complete !== true || !DateModel.isDateKey(day.dateKey)) return
        var entry = CachePolicy.createRetainedDay(state.leagueId, day.dateKey,
          day.games, Date.now(), root.todayDateKey)
        if (!entry) return
        var id = CachePolicy.key(entry.leagueId, entry.dateKey)
        var existing = root.entries[id]
        if (existing && JSON.stringify(existing.games || []) === JSON.stringify(entry.games || [])) return
        var next = {}
        for (var current in root.entries) next[current] = root.entries[current]
        next[id] = entry
        root.retain(next)
        root.writeQueue.push(entry)
      })
    })
    root.flushWrites()
  }

  function flushWrites() {
    if (!root.ready || cacheHelper.running || root.helperOperation !== "") return
    if (root.writeQueue.length === 0) {
      root.startHelper("write", "manifest.json",
        JSON.stringify(CachePolicy.manifest(root.entries, root.todayDateKey), null, 2) + "\n")
      return
    }
    root.activeWrite = root.writeQueue.shift()
    root.pendingWriteName = root.fileNameFor(root.activeWrite)
    root.startHelper("write", root.pendingWriteName, JSON.stringify(root.activeWrite, null, 2) + "\n")
  }

  function flushCleanup() {
    if (cacheHelper.running || root.helperOperation !== "" || root.cleanupQueue.length === 0) return
    root.startHelper("remove", root.cleanupQueue.shift(), "")
  }

  Process {
    id: cacheHelper
    running: false
    stdinEnabled: true
    stdout: StdioCollector { id: cacheHelperOutput; waitForEnd: true }
    onStarted: {
      if (root.helperOperation === "write") write(root.pendingWriteText + "\u0000")
    }
    onExited: function(exitCode) {
      var operation = root.helperOperation
      var name = root.helperName
      var raw = cacheHelperOutput.text
      root.helperOperation = ""
      root.helperName = ""
      root.pendingWriteText = ""
      if (operation === "read") {
        if (name === "manifest.json") {
          var parsed = null
          if (exitCode === 0) { try { parsed = JSON.parse(raw) } catch (error) {} }
          var keys = parsed && parsed.cacheVersion === CachePolicy.CACHE_VERSION
            && Array.isArray(parsed.keys) ? parsed.keys : []
          root.enqueueReads(keys)
        } else {
          if (exitCode === 0) root.applyDayText(raw)
          Qt.callLater(root.readNext)
        }
      } else if (operation === "write") {
        if (name === root.pendingWriteName) {
          root.activeWrite = null
          root.pendingWriteName = ""
          Qt.callLater(root.flushWrites)
        } else Qt.callLater(root.flushCleanup)
      } else if (operation === "remove") Qt.callLater(root.flushCleanup)
    }
  }

  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("../scripts/calendar-cache-helper.py").toString().replace("file://", ""))

  Component.onCompleted: root.startHelper("read", "manifest.json", "")
  Component.onDestruction: { if (cacheHelper.running) cacheHelper.running = false }
}
