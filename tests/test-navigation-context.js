const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const navigation = require('../model/NavigationContext.js');
const teams = require('../model/TeamSchedulePolicy.js');
const catalog = require('../providers/NhlTeamCatalog.js').listTeams();
let count = 0;
function test(name, body) { body(); count++; console.log('ok '+count+' - '+name); }

test('history retains the newest eight contexts in order without mutating input', () => {
  let stack = Object.freeze([]);
  for (let i=0;i<12;i++) {
    const before=JSON.stringify(stack); const next=navigation.push(stack,Object.freeze({surface:'scores',destination:'following',selectedRowId:'game:'+i}));
    assert.equal(JSON.stringify(stack),before); stack=Object.freeze(next);
  }
  assert.equal(stack.length,navigation.MAX_DEPTH); assert.equal(stack[0].selectedRowId,'game:4'); assert.equal(stack[7].selectedRowId,'game:11');
});
test('pop returns the latest context and a fresh bounded stack', () => {
  const frames=[{surface:'scores'},{surface:'detail'},{surface:'team'}]; const before=JSON.stringify(frames);
  const result=navigation.pop(frames); assert.equal(result.frame,frames[2]); assert.deepEqual(result.stack,frames.slice(0,2));
  assert.equal(JSON.stringify(frames),before); assert.notEqual(result.stack,frames);
});
test('empty and malformed history remain safe', () => {
  for (const value of [null,undefined,{},'not a stack']) {
    assert.deepEqual(navigation.pop(value),{frame:null,stack:[]});
    assert.deepEqual(navigation.push(value,{surface:'scores'}),[{surface:'scores'}]);
  }
});
test('Back labels identify every supported return surface', () => {
  const cases=[['detail','Back to game'],['standings','Back to standings'],['team','Back to team schedule'],['calendar','Back to calendar']];
  for (const [surface,label] of cases) assert.equal(navigation.label({surface}),label);
  assert.equal(navigation.label({surface:'scores',destination:'following'}),'Back to Following');
  assert.equal(navigation.label({surface:'scores',destination:'nhl'}),'Back to scores');assert.equal(navigation.label(null),'Back');
});
test('disabled or missing destinations fall back to Following', () => {
  assert.equal(navigation.destination({destination:'nhl'},['nhl','nfl']),'nhl');
  assert.equal(navigation.destination({destination:'nba'},['nhl','nfl']),'following');
  assert.equal(navigation.destination({destination:'following'},[]),'following');
  assert.equal(navigation.destination(null,['nhl']),'following');
  for (const value of [null,undefined,{},'nhl',{length:-1},{length:Infinity}])
    assert.equal(navigation.destination({destination:'nhl'},value),'following');
});
test('destination lookup admits bounded QVariantList-like enabled IDs', () => {
  assert.equal(navigation.destination({destination:'nfl'},{0:'nhl',1:'nfl',length:2}),'nfl');
  assert.equal(navigation.destination({destination:'nfl'},{0:'nfl',length:9}),'following');
  assert.equal(navigation.destination({destination:'nfl'},{0:'nfl',length:1.5}),'following');
});
test('a full origin frame survives push and pop without preference changes', () => {
  const frame={surface:'detail',destination:'nhl',dateKey:'2026-11-24',filter:'favorites',selectedRowId:'game:nhl:1',contentY:147,
    detailId:'nhl:1',detailScroll:208,detailCursor:2,focusTarget:'home-team',teamWindowStart:'2026-11-24'};
  const before=JSON.stringify(frame); const restored=navigation.pop(navigation.push([],frame)).frame;
  assert.deepEqual(restored,frame);assert.equal(JSON.stringify(frame),before);
});
test('canonical non-favorite teams are admitted from an enabled catalog', () => {
  const team=catalog.find(team=>team.id==='nhl:6'); assert.ok(team);
  assert.equal(teams.resolve('nhl:6',catalog,['nhl']),team);
  assert.equal(teams.resolve('nhl:6',catalog,[]),null);
  assert.equal(teams.resolve('nhl:6',catalog,['nfl']),null);
});
test('invalid, forged and unknown team identities are rejected', () => {
  for (const id of [null,undefined,1,'','nhl:999999','nhl:6/../../','NHL:6','__proto__:6','nhl:6?url=bad'])
    assert.equal(teams.resolve(id,catalog,['nhl']),null);
  assert.equal(teams.resolve('nhl:6',[{id:'nhl:6',league:'nhl',providerTeamId:'7'}],['nhl']),null);
  assert.equal(teams.resolve('nhl:6',[{id:'nhl:6',league:'nfl',providerTeamId:'6'}],['nhl']),null);
});
test('team admission enforces finite integer bounds on catalog and enabled lists', () => {
  const team=catalog.find(team=>team.id==='nhl:6');
  assert.equal(teams.resolve('nhl:6',{0:team,length:1},{0:'nhl',length:1}),team);
  for (const length of [-1,1.5,Infinity,NaN,4097]) assert.equal(teams.resolve('nhl:6',{0:team,length},['nhl']),null);
  for (const length of [-1,1.5,Infinity,NaN,9]) assert.equal(teams.resolve('nhl:6',[team],{0:'nhl',length}),null);
});
test('team resolution never changes catalog or enabled preferences', () => {
  const before=JSON.stringify(catalog), enabled=Object.freeze(['nhl']);
  teams.resolve('nhl:6',catalog,enabled); assert.equal(JSON.stringify(catalog),before); assert.deepEqual(enabled,['nhl']);
});
test('QML require-free helpers preserve Node behavior', () => {
  const navScope={}; vm.createContext(navScope); vm.runInContext(fs.readFileSync(require.resolve('../model/NavigationContext.js'),'utf8'),navScope);
  const teamScope={};vm.createContext(teamScope);vm.runInContext(fs.readFileSync(require.resolve('../model/TeamSchedulePolicy.js'),'utf8'),teamScope);
  assert.equal(JSON.stringify(navScope.pop(navScope.push([],{surface:'scores',destination:'following'}))),
    JSON.stringify(navigation.pop(navigation.push([],{surface:'scores',destination:'following'}))));
  assert.equal(navScope.destination({destination:'nhl'},{0:'nhl',length:1}),'nhl');
  assert.equal(teamScope.resolve('nhl:6',catalog,{0:'nhl',length:1}).id,'nhl:6');
});
console.log('Navigation context and team policy: '+count+' checks passed');
