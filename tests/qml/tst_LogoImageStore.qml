import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "LogoImageStore"

  property var store: null
  property var consumers: []
  property var extraStores: []
  readonly property string firstUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/bos.png"
  readonly property string secondUrl: "https://a.espncdn.com/i/teamlogos/nhl/500/nyr.png"
  readonly property string imageData: "data:image/png;base64,iVBORw0KGgo="

  Component {
    id: consumerComponent
    QtObject {
      property var imageStore: null
      property string url: ""
      readonly property string source: imageStore ? imageStore.sourceFor(url) : ""
    }
  }

  function init() {
    failOnWarning(/.?/)
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/LogoImageStore.qml"))
    compare(component.status, Component.Ready, component.errorString())
    // Hold the existing helper boundary idle; these tests drive cache results
    // deterministically and never fetch images from the network.
    store = component.createObject(testCase, {activeUrl: "test:busy"})
    verify(store !== null)
    consumers = []
    extraStores = []
  }

  function cleanup() {
    for (var i = 0; i < consumers.length; i++) consumers[i].destroy()
    consumers = []
    for (var j = 0; j < extraStores.length; j++) extraStores[j].destroy()
    extraStores = []
    if (store) store.destroy()
    store = null
    wait(0)
  }

  function consumer(url) {
    var item = consumerComponent.createObject(testCase, {imageStore: store, url: url})
    consumers.push(item)
    return item
  }

  function test_bindingDefersAdmissionAndDeduplicates() {
    var first = consumer(firstUrl)
    var second = consumer(first.url)
    compare(first.source, "")
    compare(second.source, "")
    compare(store.queuedUrls.length, 0)
    tryCompare(store, "queuedUrls", [first.url])
  }

  function test_helperSerializesRepeatedRequests() {
    var process = findChild(store, "fixtureProcess")
    store.activeUrl = ""
    var first = consumer(firstUrl)
    var duplicate = consumer(firstUrl)
    var second = consumer(secondUrl)
    compare(process.starts, 0)
    tryCompare(process, "starts", 1)
    compare(process.command[process.command.length - 1], firstUrl)
    // A cache update reevaluates the still-pending bindings. Neither an active
    // request nor the queued URL may be admitted a second time.
    store.setResult("test:unrelated", "")
    wait(0)
    compare(process.starts, 1)
    compare(store.queuedUrls, [secondUrl])
    process.finish(0, imageData)
    compare(first.source, imageData)
    compare(duplicate.source, imageData)
    compare(process.starts, 2)
    compare(process.command[process.command.length - 1], secondUrl)
    process.finish(4, "")
    compare(second.source, "")
    wait(0)
    compare(process.starts, 2)
    compare(store.queuedUrls.length, 0)
    compare(store.sourceFor(secondUrl), "")
    compare(store.requests.scheduled, false)
  }

  function test_result_data() {
    return [
      {tag: "validated raster", exitCode: 0, output: imageData, expected: imageData},
      {tag: "helper failure", exitCode: 4, output: "", expected: ""},
      {tag: "unexpected output", exitCode: 0, output: "https://example.invalid/logo.png", expected: ""},
      {tag: "oversized output", exitCode: 0,
        output: "data:image/png;base64," + new Array(350002).join("x"), expected: ""}
    ]
  }

  function test_result(data) {
    var process = findChild(store, "fixtureProcess")
    store.activeUrl = ""
    var item = consumer(firstUrl)
    tryCompare(process, "starts", 1)
    process.finish(data.exitCode, data.output)
    compare(item.source, data.expected)
    compare(store.sources[firstUrl], data.expected)
    // Empty strings are negative cache entries, not another request.
    for (var i = 0; i < 10; i++) compare(store.sourceFor(firstUrl), data.expected)
    compare(store.requests.scheduled, false)
    wait(0)
    compare(process.starts, 1)
  }

  function test_recycledConsumerTracksUrlAndStore() {
    var item = consumer(firstUrl)
    store.setResult(firstUrl, imageData)
    compare(item.source, imageData)
    item.url = secondUrl
    compare(item.source, "")
    store.setResult(secondUrl, imageData + "second")
    compare(item.source, imageData + "second")
    var component = Qt.createComponent(Qt.resolvedUrl("../../services/LogoImageStore.qml"))
    var other = component.createObject(testCase, {activeUrl: "test:busy"})
    extraStores.push(other)
    item.imageStore = other
    compare(item.source, "")
    other.setResult(secondUrl, imageData)
    compare(item.source, imageData)
  }

  function test_pendingQueueAndCacheStayBounded() {
    var process = findChild(store, "fixtureProcess")
    for (var i = 0; i < store.maxEntries * 3; i++) {
      store.sourceFor("test:logo-" + i)
      store.sourceFor("test:logo-" + i)
    }
    compare(store.requests.urls.length, store.maxEntries)
    compare(store.queuedUrls.length, 0)
    tryVerify(function() { return store.queuedUrls.length === store.maxEntries })
    compare(store.requests.urls.length, 0)
    compare(process.starts, 0)
    store.activeUrl = ""
    store.startNext()
    compare(process.starts, 1)
    for (var j = 0; j < store.maxEntries + 10; j++) store.setResult("test:cache-" + j, "")
    compare(Object.keys(store.sources).length, store.maxEntries)
    process.finish(4, "")
    compare(store.queuedUrls.length, 0)
    compare(process.starts, 1)
    store.sourceFor("test:beyond-cache")
    compare(store.requests.urls.length, 0)
    compare(store.requests.scheduled, false)
  }

  function test_destroyBeforeDeferredFlush() {
    consumer(firstUrl)
    var owner = store.requests
    compare(owner.scheduled, true)
    store.destroy()
    store = null
    wait(0)
    verify(!owner.alive)
    compare(owner.urls.length, 0)
    wait(0)
  }
}
