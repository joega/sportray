function numberOrZero(value) {
  var number = Number(value);
  return isFinite(number) && number > 0 ? number : 0;
}

function footerLayout(rowWidth, contextNaturalWidth, favoriteWidth, sourceWidth,
  spacing, minimumDetailWidth) {
  var width = numberOrZero(rowWidth);
  var context = numberOrZero(contextNaturalWidth);
  var favorite = numberOrZero(favoriteWidth);
  var source = numberOrZero(sourceWidth);
  var gap = numberOrZero(spacing);
  var minimumDetail = numberOrZero(minimumDetailWidth);
  var sourceGap = source > 0 ? gap : 0;
  var metaWidth = Math.max(0, width - source - sourceGap);

  function detailGapCount(hasContext) {
    var visibleBeforeDetail = (hasContext ? 1 : 0) + (favorite > 0 ? 1 : 0);
    return visibleBeforeDetail > 0 ? visibleBeforeDetail : 0;
  }

  var contextGapCount = detailGapCount(context > 0);
  var contextBudget = Math.max(0,
    metaWidth - favorite - contextGapCount * gap - minimumDetail);
  var boundedContext = Math.min(context, contextBudget);
  if (boundedContext <= 0) {
    boundedContext = 0;
    contextGapCount = detailGapCount(false);
  }

  var detailWidth = Math.max(0,
    metaWidth - boundedContext - favorite - contextGapCount * gap);
  var detailStart = boundedContext + favorite
    + (boundedContext > 0 ? gap : 0)
    + (favorite > 0 ? gap : 0);
  var sourceStart = Math.max(0, width - source);

  return {
    rowWidth: width,
    contextWidth: boundedContext,
    favoriteWidth: favorite,
    detailWidth: detailWidth,
    detailStart: detailStart,
    detailEnd: detailStart + detailWidth,
    sourceWidth: source,
    sourceStart: sourceStart,
    sourceEnd: sourceStart + source,
    sourceReachable: source > 0 && sourceStart >= 0 && sourceStart < width
      && sourceStart + source <= width,
    nonOverlapping: source <= 0 || detailStart + detailWidth <= sourceStart - gap
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    footerLayout: footerLayout
  };
}
