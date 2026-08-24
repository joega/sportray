function childActionPressed(sourcePressed, retryPressed, nextGamePressed, emptyActionPressed,
  standingsPressed) {
  return sourcePressed === true || retryPressed === true || nextGamePressed === true
    || emptyActionPressed === true || standingsPressed === true;
}

function allowsRowActivation(hasChildActionPress) {
  return hasChildActionPress !== true;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    childActionPressed: childActionPressed,
    allowsRowActivation: allowsRowActivation
  };
}
