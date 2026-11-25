const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const policy = require('../model/FeaturePresentation.js');
let count = 0;
function test(name, run) { run(); console.log('ok '+(++count)+' - '+name); }
function game(id, status, favorite=true, valid=true) { return {id,status,isValid:valid,presentation:{isFavorite:favorite}}; }
function row(value) { return {kind:'game',rowId:'game:'+value.id,game:value,stale:true,action:{type:'open-detail'}}; }
test('live favorites lead scheduled and completed favorites',()=>{
  assert.equal(policy.choose([game('final','final'),game('soon','scheduled'),game('live','live')]),'live');
  assert.equal(policy.choose([game('later','scheduled'),game('break','intermission')]),'break');
});
test('ties preserve existing favorite ordering',()=>{
  assert.equal(policy.choose([game('b','live'),game('a','live')]),'b');
});
test('administrative, invalid and nonfavorite games remain compact',()=>{
  assert.equal(policy.choose([game('off','postponed'),game('bad','unknown'),game('x','live',true,false),game('other','live',false)]),'');
});
test('identities remain canonical and inputs are not mutated',()=>{
  const games=[game(' NHL:123 ','scheduled')], before=JSON.stringify(games);
  assert.equal(policy.choose(games),'nhl:123'); assert.equal(JSON.stringify(games),before);
});
test('a latched ID renders once ahead of remaining slate groups',()=>{
  const selected=game('a','live'),other=game('b','live'),rows=[{kind:'section-header',rowId:'s',label:'Live'},row(other),row(selected)];
  const result=policy.rows(rows,'a'); assert.equal(result[0].rowId,'game:a');assert.equal(result[0].featured,true);
  assert.equal(result.filter(r=>r.kind==='game').length,2);assert.equal(result[2].rowId,'game:b');
});
test('status stays visible and empty sections disappear',()=>{
  const status={kind:'status',rowId:'status:nhl'},input=[status,{kind:'section-header',rowId:'s'},row(game('a','live'))];
  const result=policy.rows(input,'a');assert.equal(result[0],status);assert.equal(result.length,2);
  assert.equal(result[1].stale,true);assert.deepEqual(result[1].action,{type:'open-detail'});
});
test('missing feature never promotes a replacement or changes row geometry',()=>{
  const input=[row(game('other','live'))]; assert.equal(policy.rows(input,'gone'),input);assert.equal(policy.rows(input,''),input);
});
test('a retained final game stays featured until its view boundary',()=>{
  const input=[row(game('old','final')),row(game('new','live'))];
  assert.equal(policy.rows(input,'old')[0].game.id,'old');
});
test('reprojection does not mutate original rows or lose canonical actions',()=>{
  const input=[row(game('a','live'))],before=JSON.stringify(input);
  assert.equal(policy.rows(input,'a')[0].rowId,input[0].rowId);assert.equal(JSON.stringify(input),before);
});
test('require-free QML path matches Node policy',()=>{
  const scope={};vm.createContext(scope);vm.runInContext(fs.readFileSync(require.resolve('../model/FeaturePresentation.js'),'utf8'),scope);
  assert.equal(scope.choose([game('x','live')]),policy.choose([game('x','live')]));
});
console.log('Featured matchup: '+count+' checks passed');
