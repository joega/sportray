// Keep provider transport and parser admission bounded before a response can
// become normalized games. The byte limit is enforced by curl; the character
// limit is the conservative QML-side guard for streamed QString chunks.
var MAX_RESPONSE_BYTES = 2 * 1024 * 1024;
var MAX_RESPONSE_CHARS = Math.floor(MAX_RESPONSE_BYTES / 3);
var MAX_EVENTS = 256;

function bodyWithinLimit(value) {
  return typeof value === "string" && value.length <= MAX_RESPONSE_CHARS;
}

function canAppend(current, chunk) {
  return typeof current === "string" && typeof chunk === "string"
    && current.length <= MAX_RESPONSE_CHARS
    && chunk.length <= MAX_RESPONSE_CHARS - current.length;
}

function eventCountWithinLimit(count) {
  return typeof count === "number" && isFinite(count)
    && count >= 0 && Math.floor(count) === count && count <= MAX_EVENTS;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    MAX_RESPONSE_BYTES: MAX_RESPONSE_BYTES,
    MAX_RESPONSE_CHARS: MAX_RESPONSE_CHARS,
    MAX_EVENTS: MAX_EVENTS,
    bodyWithinLimit: bodyWithinLimit,
    canAppend: canAppend,
    eventCountWithinLimit: eventCountWithinLimit
  };
}
