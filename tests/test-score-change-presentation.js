const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const policy = require("../model/ScoreChangePresentation.js");
const visible = {visible: true, stale: false, reducedMotion: false};
let count = 0;
function test(name, body) { body(); count++; console.log("ok - " + name); }
function game(away=1, home=0, id="101") {
  return {id:"nhl:"+id,league:"nhl",providerGameId:id,isValid:true,status:"live",awayScore:away,homeScore:home};
}
function flags(result) { return [result.awayChanged,result.homeChanged]; }
test("initial score binding establishes a quiet baseline",()=>{
  assert.deepEqual(flags(policy.observe(null,game(),visible)),[false,false]);
});
test("only the actual changed finite score is emphasized",()=>{
  const before=policy.snapshot(game(),visible);
  assert.deepEqual(flags(policy.observe(before,game(2,0),visible)),[true,false]);
  assert.deepEqual(flags(policy.observe(before,game(1,1),visible)),[false,true]);
  assert.deepEqual(flags(policy.observe(before,game(2,1),visible)),[true,true]);
});
test("clock, favorite, identity-equivalent publications and unchanged scores stay quiet",()=>{
  const before=policy.snapshot(game(),visible);
  assert.deepEqual(flags(policy.observe(before,{...game(),clock:"12:30",presentation:{isFavorite:true}},visible)),[false,false]);
});
test("same-game score corrections are also real deltas",()=>{
  assert.deepEqual(flags(policy.observe(policy.snapshot(game(3,2),visible),game(2,2),visible)),[true,false]);
});
test("recycled rows and noncanonical or mismatched identities never pulse",()=>{
  const before=policy.snapshot(game(),visible);
  for (const after of [game(2,0,"102"),{...game(2,0),id:"bad"},{...game(2,0),providerGameId:"999"}])
    assert.deepEqual(flags(policy.observe(before,after,visible)),[false,false]);
});
test("unavailable or nonnumeric scores do not become changes",()=>{
  for(const score of [null,undefined,NaN,Infinity,-1,1.5,"2"]){
    const unavailable={...game(),awayScore:score};
    assert.deepEqual(flags(policy.observe(policy.snapshot(unavailable,visible),game(2,0),visible)),[false,false]);
    assert.deepEqual(flags(policy.observe(policy.snapshot(game(1,0),visible),unavailable,visible)),[false,false]);
  }
});
test("stale, hidden and reduced-motion observations stay quiet",()=>{
  const before=policy.snapshot(game(),visible);
  for(const state of [{...visible,visible:false},{...visible,stale:true},{...visible,reducedMotion:true}])
    assert.deepEqual(flags(policy.observe(before,game(2,0),state)),[false,false]);
});
test("returning from stale, hidden or reduced motion starts a fresh baseline",()=>{
  for(const state of [{...visible,visible:false},{...visible,stale:true},{...visible,reducedMotion:true}]){
    const before=policy.snapshot(game(),state);
    const first=policy.observe(before,game(2,0),visible);
    assert.deepEqual(flags(first),[false,false]);
    assert.deepEqual(flags(policy.observe(first.snapshot,game(3,0),visible)),[true,false]);
  }
});
test("only valid score-bearing live, intermission and final states qualify",()=>{
  const before=policy.snapshot(game(),visible);
  for(const status of ["scheduled","postponed","canceled","unknown","malformed"])
    assert.deepEqual(flags(policy.observe(before,{...game(2,0),status},visible)),[false,false]);
  for(const status of ["live","intermission","final"])
    assert.deepEqual(flags(policy.observe(before,{...game(2,0),status},visible)),[true,false]);
  assert.deepEqual(flags(policy.observe(before,{...game(2,0),isValid:false},visible)),[false,false]);
});
test("the observer does not mutate games, options or its previous snapshot",()=>{
  const previous=policy.snapshot(game(),visible), after=game(2,0), snapshot=JSON.stringify([previous,after,visible]);
  policy.observe(previous,after,visible);
  assert.equal(JSON.stringify([previous,after,visible]),snapshot);
});
test("QML require-free evaluation produces the same delta decision",()=>{
  const context={};vm.createContext(context);
  vm.runInContext(fs.readFileSync(require.resolve("../model/ScoreChangePresentation.js"),"utf8"),context);
  const previous=policy.snapshot(game(),visible), after=game(2,1);
  assert.equal(JSON.stringify(context.observe(previous,after,visible)),JSON.stringify(policy.observe(previous,after,visible)));
});
console.log("Score-change presentation: "+count+" checks passed");
