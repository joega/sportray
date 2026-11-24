// Bounded panel-session history. Frames contain normalized view state only.
var MAX_DEPTH = 8;
function push(stack, frame) {
  return (Array.isArray(stack) ? stack : []).slice(-(MAX_DEPTH - 1)).concat([frame]);
}
function pop(stack) {
  var values = Array.isArray(stack) ? stack : [];
  return {frame: values.length ? values[values.length - 1] : null, stack: values.slice(0, -1)};
}
function label(frame) {
  if (!frame) return "Back";
  if (frame.surface === "detail") return "Back to game";
  if (frame.surface === "standings") return "Back to standings";
  if (frame.surface === "team") return "Back to team schedule";
  if (frame.surface === "calendar") return "Back to calendar";
  return frame.destination === "following" ? "Back to Following" : "Back to scores";
}
function destination(frame, enabledLeagues) {
  if (!frame || typeof frame.destination !== "string") return "following";
  if (frame.destination === "following") return "following";
  if (!enabledLeagues || typeof enabledLeagues.length !== "number"
      || !isFinite(enabledLeagues.length) || enabledLeagues.length < 0 || enabledLeagues.length > 8
      || Math.floor(enabledLeagues.length) !== enabledLeagues.length) return "following";
  for (var i = 0; i < enabledLeagues.length; i++) {
    if (enabledLeagues[i] === frame.destination) return frame.destination;
  }
  return "following";
}
if (typeof module !== "undefined" && module.exports)
  module.exports = {MAX_DEPTH: MAX_DEPTH, push: push, pop: pop, label: label, destination: destination};
