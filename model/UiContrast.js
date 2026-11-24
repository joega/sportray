// Theme-derived text choices. Callers supply the actual painted background;
// composite translucent control fills over their surface before choosing text.
function channel(value) {
  return typeof value === "number" && isFinite(value) && value >= 0 && value <= 1;
}

function rgba(value) {
  if (typeof value === "string") {
    var text = value.replace(/^\s+|\s+$/g, "");
    if (/^#[0-9a-f]{3}$/i.test(text))
      text = "#" + text.charAt(1) + text.charAt(1) + text.charAt(2) + text.charAt(2)
        + text.charAt(3) + text.charAt(3);
    // Qt's eight-digit hex notation is #AARRGGBB.
    if (!/^#(?:[0-9a-f]{6}|[0-9a-f]{8})$/i.test(text)) return null;
    var offset = text.length === 9 ? 3 : 1;
    return {r: parseInt(text.substr(offset, 2), 16) / 255,
      g: parseInt(text.substr(offset + 2, 2), 16) / 255,
      b: parseInt(text.substr(offset + 4, 2), 16) / 255,
      a: offset === 3 ? parseInt(text.substr(1, 2), 16) / 255 : 1};
  }
  if (!value || typeof value !== "object" || !channel(value.r)
      || !channel(value.g) || !channel(value.b)) return null;
  var alpha = value.a === undefined ? 1 : value.a;
  return channel(alpha) ? {r: value.r, g: value.g, b: value.b, a: alpha} : null;
}

function composite(foreground, background) {
  var front = rgba(foreground), back = rgba(background);
  if (!front || !back) return null;
  var alpha = front.a + back.a * (1 - front.a);
  if (alpha === 0) return {r: 0, g: 0, b: 0, a: 0};
  var rearWeight = back.a * (1 - front.a);
  return {r: (front.r * front.a + back.r * rearWeight) / alpha,
    g: (front.g * front.a + back.g * rearWeight) / alpha,
    b: (front.b * front.a + back.b * rearWeight) / alpha, a: alpha};
}

function linear(value) {
  return value <= 0.04045 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
}

function luminance(color) {
  return 0.2126 * linear(color.r) + 0.7152 * linear(color.g) + 0.0722 * linear(color.b);
}

function contrastRatio(foreground, background) {
  var back = rgba(background);
  // An unknown underlying surface cannot produce a truthful contrast ratio.
  if (!back || back.a !== 1) return null;
  var front = composite(foreground, back);
  if (!front) return null;
  var first = luminance(front), second = luminance(back);
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05);
}

function foreground(preferred, fallback, background, minimumRatio) {
  var threshold = typeof minimumRatio === "number" && isFinite(minimumRatio)
      && minimumRatio >= 1 && minimumRatio <= 21 ? minimumRatio : 4.5;
  var ratio = contrastRatio(preferred, background);
  // Preserve the caller's QColor, including its binding-friendly native type.
  // A malformed or insufficient preferred color uses the supplied theme text;
  // do not invent a palette or silently claim that a bad fallback passes.
  return ratio !== null && ratio >= threshold ? preferred : fallback;
}

if (typeof module !== "undefined" && module.exports) module.exports = {
  rgba: rgba, composite: composite, contrastRatio: contrastRatio, foreground: foreground
};
