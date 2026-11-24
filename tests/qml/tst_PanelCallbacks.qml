import QtQuick
import QtTest

TestCase {
  id: testCase
  name: "PanelCallbacks"
  property var owner: null
  property int callbacks: 0
  property string source: ""

  function initTestCase() {
    var request = new XMLHttpRequest()
    request.open("GET", Qt.resolvedUrl("../../Panel.qml"), false)
    request.send()
    source = request.responseText
    verify(source.length > 0)
  }
  function productionFunction(name, nextName) {
    var start = source.indexOf("  function " + name + "(")
    var end = source.indexOf("  function " + nextName + "(", start + 1)
    verify(start > 0 && end > start)
    return source.slice(start, end)
  }
  function init() {
    failOnWarning(/.?/)
    callbacks = 0
    // Execute the exact production callback functions. Only the disposed import
    // boundary is simulated; no production hooks, desktop, or workers are used.
    owner = Qt.createQmlObject('import QtQuick\n'
      + 'import "CallbackGuardContext.js" as LifecyclePolicy\n'
      + 'Item { id: root; property var callbackOwner: LifecyclePolicy.createOwnerState(); '
      + 'property var resultListLifecycle: LifecyclePolicy.createOwnerState(); '
      + 'property alias list: resultList; Item { id: resultList }\n'
      + productionFunction("deferPanelCallback", "deferResultListCallback")
      + productionFunction("deferResultListCallback", "queuePanelHeightRecalculation")
      + '\nComponent.onDestruction: { callbackOwner.alive = false; resultListLifecycle.alive = false } }',
      testCase, Qt.resolvedUrl("CallbackOwner.qml"))
    verify(owner !== null)
  }
  function cleanup() {
    if (owner) owner.destroy()
    wait(0)
    owner = null
  }
  function queueBoth() {
    owner.deferPanelCallback(function() { callbacks++ })
    owner.deferResultListCallback(function(list) {
      verify(list !== null)
      callbacks++
    })
  }
  function test_liveCallbacksExecute() {
    queueBoth()
    tryCompare(testCase, "callbacks", 2)
  }
  function test_invalidatedPanelRejectsBeforeContextLookup() {
    queueBoth()
    owner.callbackOwner.alive = false
    wait(20)
    compare(callbacks, 0)
  }
  function test_invalidatedListLeavesPanelCallbackUsable() {
    queueBoth()
    owner.resultListLifecycle.alive = false
    wait(20)
    compare(callbacks, 1)
  }
  function test_replacedGenerationRejectsOldWork() {
    queueBoth()
    owner.callbackOwner.generation++
    wait(20)
    compare(callbacks, 0)
    queueBoth()
    tryCompare(testCase, "callbacks", 2)
  }
  function test_explicitTeardownRejectsQueuedWork() {
    queueBoth()
    // destroy() itself is deferred: Qt is allowed to run callbacks while an
    // owner is still alive. Model the invalidation performed during teardown.
    owner.callbackOwner.alive = false
    owner.resultListLifecycle.alive = false
    owner.destroy()
    wait(20)
    owner = null
    compare(callbacks, 0)
  }
}
