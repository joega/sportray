import QtQuick
import Quickshell
import Quickshell.Io
import "../model/CalendarDiskCachePolicy.js" as CachePolicy
import "../model/DateModel.js" as DateModel

// Durable normalized calendar snapshots. This is cache state, not settings:
// it has no user intent, provider payload, notification state, or polling
// ownership. Reads and writes are serialized through dedicated FileViews so a
// path change can never retarget an in-flight operation.
Item {
  id: root

  readonly property string cacheRoot: Quickshell.env("HOME") + "/.cache/sportray/calendar"
  readonly property string manifestPath: root.cacheRoot + "/manifest.json"
  property bool ready: false
  property bool manifestStarted: false
  property var entries: ({})
  property var readQueue: []
  property var writeQueue: []
  property var cleanupQueue: []
  property string activeReadKey: ""
  property var activeWrite: null
  property string pendingWritePath: ""
  property string pendingWriteText: ""
  property string activeCleanupPath: ""
  property string todayDateKey: DateModel.localDateKey(new Date())

  function dayPath(entry) {
    return root.cacheRoot + "/" + CachePolicy.fileName(entry.leagueId, entry.dateKey)
  }

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

  function enqueueReads(keys) {
    root.readQueue = []
    keys.forEach(function(value) {
      var parts = CachePolicy.keyParts(value)
      if (parts && CachePolicy.inWindow(parts.dateKey, root.todayDateKey))
        root.readQueue.push(value)
      else if (parts)
        root.queueCleanupForKey(value)
    })
    // Let the manifest FileView completion settle before starting the first
    // day read; subsequent day reads use the same deferred boundary below.
    Qt.callLater(root.readNext)
  }

  function queueCleanupForKey(value) {
    var parts = CachePolicy.keyParts(value)
    if (!parts) return
    var path = root.cacheRoot + "/" + CachePolicy.fileName(parts.leagueId, parts.dateKey)
    if (root.cleanupQueue.indexOf(path) < 0 && root.activeCleanupPath !== path)
      root.cleanupQueue.push(path)
    root.flushCleanup()
  }

  function retain(next) {
    var kept = CachePolicy.prune(next, root.todayDateKey)
    for (var id in next) {
      if (next[id] && !kept[id]) root.queueCleanupForKey(id)
    }
    root.entries = kept
  }

  function readNext() {
    if (root.readQueue.length === 0) {
      root.activeReadKey = ""
      root.ready = true
      root.flushCleanup()
      return
    }
    root.activeReadKey = root.readQueue.shift()
    var parts = root.activeReadKey.split(":")
    dayReadFile.path = root.cacheRoot + "/" + CachePolicy.fileName(parts[0], parts[1])
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
    // FileView finishes its current operation after emitting onLoaded. Do not
    // retarget the same FileView from inside that callback or Quickshell drops
    // the replacement operation and the cache never reaches ready.
    Qt.callLater(function() { root.readNext() })
  }

  function persistStates(states) {
    if (!root.ready || !Array.isArray(states)) return
    root.todayDateKey = DateModel.localDateKey(new Date())
    states.forEach(function(state) {
      if (!state || typeof state.leagueId !== "string" || !Array.isArray(state.days)) return
      state.days.forEach(function(day) {
        if (!day || day.complete !== true || !DateModel.isDateKey(day.dateKey)) return
        var entry = CachePolicy.createDay(state.leagueId, day.dateKey, day.games, Date.now())
        if (!entry) return
        var id = CachePolicy.key(entry.leagueId, entry.dateKey)
        var existing = root.entries[id]
        if (existing && JSON.stringify(existing.games || []) === JSON.stringify(entry.games || [])) return
        var next = {}
        for (var existing in root.entries) next[existing] = root.entries[existing]
        next[id] = entry
        root.retain(next)
        root.writeQueue.push(entry)
      })
    })
    root.flushWrites()
  }

  function flushWrites() {
    if (!root.ready || root.activeWrite) return
    if (root.writeQueue.length === 0) {
      manifestFile.setText(JSON.stringify(CachePolicy.manifest(root.entries, root.todayDateKey), null, 2) + "\n")
      return
    }
    root.activeWrite = root.writeQueue.shift()
    root.pendingWritePath = root.dayPath(root.activeWrite)
    root.pendingWriteText = JSON.stringify(root.activeWrite, null, 2) + "\n"
    dayWriteFile.path = root.pendingWritePath
    Qt.callLater(root.commitWrite)
  }

  function commitWrite() {
    if (!root.activeWrite || !root.pendingWritePath) return
    dayWriteFile.setText(root.pendingWriteText)
  }

  function flushCleanup() {
    if (root.activeCleanupPath || root.cleanupQueue.length === 0) return
    root.activeCleanupPath = root.cleanupQueue.shift()
  }

  Process {
    id: mkdirProcess
    command: ["/usr/bin/mkdir", "-p", "--", root.cacheRoot]
    running: true
    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0) { root.ready = false; return }
      root.manifestStarted = true
    }
  }

  FileView {
    id: manifestFile
    path: root.manifestStarted ? root.manifestPath : ""
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: {
      var parsed = null
      try { parsed = JSON.parse(text()) } catch (error) {}
      var keys = parsed && parsed.cacheVersion === CachePolicy.CACHE_VERSION
        && Array.isArray(parsed.keys) ? parsed.keys : []
      root.enqueueReads(keys)
    }
    onLoadFailed: root.enqueueReads([])
  }

  FileView {
    id: dayReadFile
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onLoaded: root.applyDayText(text())
    onLoadFailed: Qt.callLater(function() { root.readNext() })
  }

  FileView {
    id: dayWriteFile
    blockLoading: true
    blockAllReads: true
    atomicWrites: true
    watchChanges: false
    printErrors: false
    onSaved: {
      root.activeWrite = null
      root.pendingWritePath = ""
      root.pendingWriteText = ""
      Qt.callLater(root.flushWrites)
    }
    onSaveFailed: {
      root.activeWrite = null
      root.pendingWritePath = ""
      root.pendingWriteText = ""
      Qt.callLater(root.flushWrites)
    }
  }

  Process {
    id: cleanupProcess
    command: ["/usr/bin/rm", "-f", "--", root.activeCleanupPath]
    running: root.activeCleanupPath !== ""
    onExited: function(exitCode, exitStatus) {
      root.activeCleanupPath = ""
      root.flushCleanup()
    }
  }
}
