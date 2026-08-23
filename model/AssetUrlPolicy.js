var REVIEWED_LOGO_HOSTS = {
  "a.espncdn.com": true,
  "assets.nhle.com": true
};

function cleanString(value) {
  if (typeof value !== "string") return null;
  var result = value.trim();
  return result || null;
}

function safeLogoUrl(value) {
  var url = cleanString(value);
  if (!url || !/^https:\/\//i.test(url)) return null;

  var match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  if (!match) return null;

  var host = match[1].toLowerCase();
  return REVIEWED_LOGO_HOSTS[host] ? url : null;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    REVIEWED_LOGO_HOSTS: REVIEWED_LOGO_HOSTS,
    safeLogoUrl: safeLogoUrl
  };
}
