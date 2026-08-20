function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function cleanProviderId(value) {
  if (typeof value === "number" && isFinite(value)) value = String(value);
  return cleanString(value);
}

function normalizeLeague(league) {
  var value = cleanString(league);
  return value ? value.toLowerCase() : null;
}

function canonicalTeamId(league, providerTeamId) {
  var normalizedLeague = normalizeLeague(league);
  var normalizedProviderId = cleanProviderId(providerTeamId);
  if (!normalizedLeague || !normalizedProviderId) return null;
  return normalizedLeague + ":" + normalizedProviderId;
}

function safeUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https?:\/\//i.test(url)) return null;
  return url;
}

function normalizePrimaryColor(value) {
  var color = cleanString(value);
  if (!color) return null;
  if (color.charAt(0) === "#") color = color.slice(1);
  return /^[0-9a-f]{6}$/i.test(color) ? "#" + color.toLowerCase() : null;
}

function normalizeTeam(input) {
  if (!isRecord(input)) return null;

  var league = normalizeLeague(input.league);
  var providerTeamId = cleanProviderId(input.providerTeamId);
  var id = canonicalTeamId(league, providerTeamId);
  if (!id) return null;

  return {
    id: id,
    league: league,
    providerTeamId: providerTeamId,
    name: cleanString(input.name),
    shortName: cleanString(input.shortName),
    abbreviation: cleanString(input.abbreviation),
    primaryColor: normalizePrimaryColor(input.primaryColor),
    logoUrl: safeUrl(input.logoUrl),
    link: safeUrl(input.link)
  };
}

function createUnknownTeam(league, providerTeamId) {
  var id = canonicalTeamId(league, providerTeamId);
  if (!id) return null;

  var separator = id.indexOf(":");
  return {
    id: id,
    league: id.slice(0, separator),
    providerTeamId: id.slice(separator + 1),
    name: null,
    shortName: null,
    abbreviation: null,
    primaryColor: null,
    logoUrl: null,
    link: null
  };
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    canonicalTeamId: canonicalTeamId,
    normalizeLeague: normalizeLeague,
    normalizePrimaryColor: normalizePrimaryColor,
    normalizeTeam: normalizeTeam,
    createUnknownTeam: createUnknownTeam
  };
}
