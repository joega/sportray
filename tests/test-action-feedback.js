const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const feedback = require("../model/ActionFeedbackPolicy.js");
const settingsApi = require("../model/SettingsModel.js");
const watchesApi = require("../model/WatchPolicy.js");
const now = Date.parse("2026-11-24T12:00:00Z");
let count = 0;
function test(name, body) { body(); count++; console.log("ok - " + name); }
function settings() { const value = settingsApi.createDefaults(); value.ticker = {enabled: false, position: "top", speed: "slow"}; return value; }
function game(id) { return {league: "nhl", providerGameId: String(id), startTime: "2026-11-25T19:00:00Z"}; }
function watch(id, created=now) { return watchesApi.createWatch(game(id), new Date(created).toISOString(), created); }
function allowed(action, value, watches=[], time=now) { return feedback.canUndo(action, value, watches, time, true, false, false, watchesApi); }

test("favorite feedback records one bounded target and an eight-second lifetime", () => {
  const action = feedback.action(1, "favorite", "nhl:6", false, true, "Boston Bruins", now);
  assert.equal(action.summary, "Boston Bruins added to favorites");
  assert.equal(action.expiresAt, now + 8000);
  const value=settings(); value.favoriteTeamIds=["nhl:6"];
  assert.equal(allowed(action,value),true);
  assert.equal(allowed(action,value,[],now+8000),false);
});
test("favorite Undo rejects changed targets and capacity violations", () => {
  const action=feedback.action(1,"favorite","nhl:6",true,false,"Bruins",now), value=settings();
  assert.equal(allowed(action,value),true);
  value.favoriteTeamIds=["nhl:6"]; assert.equal(allowed(action,value),false);
  value.favoriteTeamIds=Array.from({length:32},(_,i)=>"nhl:"+(100+i)); assert.equal(allowed(action,value),false);
});
test("watch Undo requires the exact normalized record", () => {
  const original=watch(1), action=feedback.action(1,"watch",original.gameId,null,original,"",now);
  assert.equal(allowed(action,settings(),[original]),true);
  assert.equal(allowed(action,settings(),[watch(1,now+1)]),false);
  assert.equal(allowed(action,settings(),[]),false);
});
test("feedback watch snapshots cannot change with the live record", () => {
  const original=watch(1), action=feedback.action(1,"watch",original.gameId,null,original,"",now);
  original.createdAt=new Date(now+1).toISOString();
  assert.notEqual(action.after.createdAt,original.createdAt);
  assert.equal(allowed(action,settings(),[original]),false);
});
test("removed watches cannot be restored disabled, expired, or over capacity", () => {
  const original=watch(1), action=feedback.action(1,"watch",original.gameId,original,null,"",now), value=settings();
  assert.equal(allowed(action,value),true);
  value.enabledLeagues=[]; assert.equal(allowed(action,value),false);
  value.enabledLeagues=["nhl"];
  assert.equal(allowed(action,value,Array.from({length:32},(_,i)=>watch(100+i))),false);
  const expired={...original,expiresAt:new Date(now-1).toISOString()};
  assert.equal(allowed({...action,before:expired},value),false);
});
test("readiness, shutdown, opaque schemas, malformed actions and repeated Undo are guarded", () => {
  const value=settings(); value.favoriteTeamIds=["nhl:6"];
  const action=feedback.action(1,"favorite","nhl:6",false,true,"Bruins",now);
  assert.equal(feedback.canUndo(action,value,[],now,false,false,false,watchesApi),false);
  assert.equal(feedback.canUndo(action,value,[],now,true,true,false,watchesApi),false);
  assert.equal(feedback.canUndo(action,value,[],now,true,false,true,watchesApi),false);
  for(const bad of [null,{}, {...action,undone:true},{...action,expiresAt:NaN},{...action,kind:"error"}])
    assert.equal(allowed(bad,value),false);
});
test("labels are bounded and control characters are neutralized without rich text", () => {
  assert.equal(feedback.cleanLabel("Boston\n\u202eBruins"),"Boston Bruins");
  assert.equal(feedback.cleanLabel("x".repeat(500)).length,128);
  assert.equal(feedback.cleanLabel("<b>Team</b>"),"<b>Team</b>");
});
test("queued favorite intent preserves unrelated external favorites and ticker fields", () => {
  const base=settings(), incoming=settings(), desired=settings();
  incoming.favoriteTeamIds=["nhl:12"]; incoming.ticker={enabled:true,position:"bottom",speed:"fast"};
  desired.favoriteTeamIds=["nhl:6"];
  const result=feedback.mergeSettings(base,incoming,desired,settingsApi);
  assert.deepEqual(result.favoriteTeamIds,["nhl:12","nhl:6"]);
  assert.deepEqual(result.ticker,incoming.ticker);
});
test("queued notification and ticker edits affect only their explicitly changed keys", () => {
  const base=settings(),incoming=settings(),desired=settings();
  incoming.notifications.gameStart=true; incoming.ticker.enabled=true;
  desired.notifications.gameFinal=true; desired.ticker.speed="fast";
  const result=feedback.mergeSettings(base,incoming,desired,settingsApi);
  assert.equal(result.notifications.gameStart,true); assert.equal(result.notifications.gameFinal,true);
  assert.deepEqual(result.ticker,{enabled:true,position:"top",speed:"fast"});
});
test("queued watch add preserves unrelated external watches", () => {
  const before=[],incoming=[watch(2)],desired=[watch(1)];
  const result=feedback.mergeWatches(before,incoming,desired,now,watchesApi);
  assert.deepEqual(result.map(w=>w.gameId).sort(),["nhl:1","nhl:2"]);
});
test("queued watch removal never erases a renewed external record", () => {
  const before=[watch(1,now-1000)], renewed=watch(1,now), incoming=[renewed];
  assert.deepEqual(feedback.mergeWatches(before,incoming,[],now,watchesApi),incoming);
});
test("queued watch additions never evict externally added records at capacity", () => {
  const incoming=Array.from({length:32},(_,i)=>watch(i+100));
  const result=feedback.mergeWatches([],incoming,[watch(1)],now,watchesApi);
  assert.equal(result.length,32); assert.equal(result.some(w=>w.gameId==="nhl:1"),false);
});
test("queued additions recheck enabled leagues without deleting existing disabled watches", () => {
  assert.deepEqual(feedback.mergeWatches([],[],[watch(1)],now,watchesApi,[]),[]);
  const existing=watch(2);
  assert.deepEqual(feedback.mergeWatches([existing],[existing],[existing],now,watchesApi,[]),[existing]);
});
test("reconciliation is immutable and behaves identically without Node require", () => {
  const base=settings(),incoming=settings(),desired=settings(); desired.favoriteTeamIds=["nhl:6"];
  const before=JSON.stringify([base,incoming,desired]);
  const result=feedback.mergeSettings(base,incoming,desired,settingsApi);
  assert.equal(JSON.stringify([base,incoming,desired]),before);
  const context={}; vm.createContext(context);
  vm.runInContext(fs.readFileSync(require.resolve("../model/ActionFeedbackPolicy.js"),"utf8"),context);
  assert.equal(JSON.stringify(context.mergeSettings(base,incoming,desired,settingsApi)),JSON.stringify(result));
});
console.log("Action feedback: "+count+" checks passed");
