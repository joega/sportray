import QtQuick
import Quickshell.Io

// Logo URLs remain provider data, but views only receive this bounded local
// data URL. One owner serializes requests and retains a small session cache.
Item {
  id: root

  property var sources: ({})
  property var queuedUrls: []
  property string activeUrl: ""
  property string output: ""
  readonly property int maxEntries: 96
  readonly property int maxDataUrlChars: 350000
  // Mutate this plain JS object's fields in place: sourceFor runs inside QML
  // bindings, so it must not emit queue/active-property changes while they run.
  readonly property var requests: ({alive: true, scheduled: false, urls: []})
  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("../scripts/logo-image-helper.py").toString().replace("file://", ""))

  function sourceFor(url) {
    if (typeof url !== "string" || url.length === 0) return ""
    var current = root.sources[url]
    if (typeof current === "string") return current
    if (Object.keys(root.sources).length >= root.maxEntries) return ""
    var pending = root.requests
    if (pending.urls.indexOf(url) === -1 && pending.urls.length < root.maxEntries)
      pending.urls.push(url)
    if (!pending.scheduled && pending.urls.length > 0) {
      pending.scheduled = true
      Qt.callLater(function() {
        // A deferred callback may outlive the store. Check only the captured
        // plain owner state before touching the QML object again.
        if (pending.alive) root.flushRequests()
      })
    }
    return ""
  }

  function flushRequests() {
    var urls = root.requests.urls
    root.requests.urls = []
    root.requests.scheduled = false
    var queue = root.queuedUrls.slice()
    for (var i = 0; i < urls.length && queue.length < root.maxEntries; i++) {
      var url = urls[i]
      if (typeof root.sources[url] !== "string" && root.activeUrl !== url
          && queue.indexOf(url) === -1) queue.push(url)
    }
    root.queuedUrls = queue
    root.startNext()
  }

  function setResult(url, value) {
    var next = {}
    for (var key in root.sources) next[key] = root.sources[key]
    if (Object.keys(next).length >= root.maxEntries) return
    next[url] = value
    root.sources = next
  }

  function startNext() {
    if (logoHelper.running || root.activeUrl !== "" || root.queuedUrls.length === 0) return
    if (Object.keys(root.sources).length >= root.maxEntries) {
      root.queuedUrls = []
      return
    }
    root.activeUrl = root.queuedUrls[0]
    root.queuedUrls = root.queuedUrls.slice(1)
    root.output = ""
    logoHelper.command = ["/usr/bin/python3", "-I", "-S", root.helperPath, root.activeUrl]
    logoHelper.running = true
  }

  Process {
    id: logoHelper
    running: false
    stdout: SplitParser {
      splitMarker: ""
      onRead: function(chunk) {
        if (root.output.length + String(chunk).length > root.maxDataUrlChars) {
          root.output = ""
          logoHelper.running = false
          return
        }
        root.output += String(chunk)
      }
    }
    onExited: function(exitCode) {
      var url = root.activeUrl
      root.activeUrl = ""
      if (exitCode === 0 && root.output.indexOf("data:image/") === 0
          && root.output.length <= root.maxDataUrlChars)
        root.setResult(url, root.output)
      else root.setResult(url, "")
      root.output = ""
      root.startNext()
    }
  }

  Component.onDestruction: {
    root.requests.alive = false
    root.requests.urls = []
    if (logoHelper.running) logoHelper.running = false
  }
}
