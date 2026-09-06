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
  readonly property string helperPath: decodeURIComponent(
    Qt.resolvedUrl("../scripts/logo-image-helper.py").toString().replace("file://", ""))

  function sourceFor(url) {
    if (typeof url !== "string" || url.length === 0) return ""
    var current = root.sources[url]
    if (typeof current === "string") return current
    if (current === undefined && root.queuedUrls.indexOf(url) === -1 && root.activeUrl !== url) {
      root.queuedUrls = root.queuedUrls.concat([url]).slice(0, root.maxEntries)
      root.startNext()
    }
    return ""
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
    if (logoHelper.running) logoHelper.running = false
  }
}
