var ALLOWED_HOSTS = {"espn.com":true,"www.espn.com":true,"nhl.com":true,"www.nhl.com":true,"mlb.com":true,"www.mlb.com":true};
function safeGameUrl(value) {
  if (typeof value !== "string") return "";
  var url = value.trim(), match = /^https:\/\/([^/?#]+)(?:[/?#]|$)/i.exec(url);
  return match && ALLOWED_HOSTS[match[1].toLowerCase()] ? url : "";
}
var ProviderUrlPolicy = {safeGameUrl: safeGameUrl};
if (typeof module !== "undefined") module.exports = ProviderUrlPolicy;
