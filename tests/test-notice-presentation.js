const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const notice = require('../model/NoticePresentation.js');
const now = Date.parse('2026-11-24T12:10:00Z');
const old = '2026-11-24T12:05:00Z';
let count = 0;
function test(name, run) { run(); count++; console.log('ok '+count+' - '+name); }

test('healthy loaded scores have no notice', () => {
  assert.equal(notice.noticeFor({hasData:true},now).visible,false);
});
test('first load cannot become empty or retryable', () => {
  const n = notice.noticeFor({loading:true,empty:true},now);
  assert.equal(n.summary,'Loading scores…'); assert.equal(n.canRetry,false);
  assert.equal(n.severity,'info'); assert.equal(n.detail,'');
});
test('retained refresh is quiet and does not invent a failure', () => {
  const n=notice.noticeFor({loading:true,hasData:true},now);
  assert.equal(n.summary,'Updating scores…'); assert.equal(n.severity,'info');
});
test('stale retry keeps source and age visible and disables retry', () => {
  const n=notice.noticeFor({displayName:'NHL',stale:true,loading:true,lastSuccessAt:old},now);
  assert.equal(n.summary,'NHL · last update 5 min ago · updating…');
  assert.equal(n.severity,'warning'); assert.equal(n.canRetry,false);
  assert.match(n.accessibleSummary,/Stale scores/);
});
test('stale recovery retains warning until actual success', () => {
  const s={displayName:'NBA',hasData:true,stale:true,lastSuccessAt:old,errorSummary:'Request timed out'};
  assert.equal(notice.noticeFor(s,now).canRetry,true);
  assert.equal(notice.noticeFor({...s,loading:true,errorSummary:''},now).severity,'warning');
  assert.equal(notice.noticeFor({...s,stale:false,errorSummary:''},now).visible,false);
});
test('first partial result has no invented previous success age', () => {
  const n=notice.noticeFor({displayName:'NHL',stale:true,partial:true,errorCode:'partial-data',errorSummary:'Some scores could not be updated'},now);
  assert.equal(n.summary,'NHL · limited scores'); assert.doesNotMatch(n.summary,/last update/);
  assert.match(n.detail,/Some scores could not be updated/); assert.equal(n.canRetry,true);
});
test('published incomplete schedules stay neutral without futile Retry', () => {
  const n=notice.noticeFor({kind:'schedule',hasData:true,partial:true,failed:false,errorSummary:'Only published games are shown.'},now);
  assert.equal(n.summary,'Schedule incomplete'); assert.equal(n.severity,'info');
  assert.equal(n.canRetry,false); assert.match(n.detail,/published/);
});
test('actual schedule failure has one recovery action', () => {
  const n=notice.noticeFor({kind:'schedule',failed:true,errorSummary:'Schedule unavailable.'},now);
  assert.equal(n.summary,'Schedule unavailable'); assert.equal(n.canRetry,true); assert.equal(n.severity,'error');
});
test('partial request failure with usable games is a warning', () => {
  const n=notice.noticeFor({kind:'schedule',hasData:true,failed:true,partial:true},now);
  assert.equal(n.severity,'warning'); assert.equal(n.canRetry,true);
});
test('retained schedule data remains stale and retryable', () => {
  const n=notice.noticeFor({kind:'schedule',hasData:true,stale:true,partial:true,failed:false,lastSuccessAt:old},now);
  assert.equal(n.severity,'warning'); assert.equal(n.canRetry,true); assert.match(n.summary,/5 min ago/);
});
test('empty selection, unloaded and confirmed empty remain distinct', () => {
  const selection=notice.noticeFor({emptySelection:true,failed:false,errorSummary:'Follow a league.'},now);
  const unloaded=notice.noticeFor({unloaded:true},now);
  const empty=notice.noticeFor({empty:true,hasData:true},now);
  assert.equal(selection.summary,'Choose leagues to follow'); assert.equal(selection.canRetry,false);
  assert.equal(unloaded.summary,'Select a day to load its games');
  assert.equal(empty.summary,'No games listed');
});
test('standings use sport-neutral nouns and preserve recovery', () => {
  assert.equal(notice.noticeFor({kind:'standings',loading:true},now).summary,'Loading standings…');
  assert.equal(notice.noticeFor({kind:'standings',empty:true,hasData:true},now).summary,'No standings available');
  assert.equal(notice.noticeFor({kind:'standings',failed:true},now).canRetry,true);
});
test('affected league summaries name every source and give oldest age', () => {
  const n=notice.noticeFor({kind:'following',hasData:true,affectedLeagues:[
    {leagueId:'nhl',displayName:'NHL',stale:true,lastSuccessAt:old,errorSummary:'NHL timeout'},
    {leagueId:'nfl',displayName:'NFL',failed:true,lastSuccessAt:'2026-11-24T12:00:00Z',errorSummary:'NFL failure'}]},now);
  assert.equal(n.summary,'NHL, NFL · updates delayed · oldest update 10 min ago');
  assert.deepEqual(n.affectedLeagueIds,['nhl','nfl']); assert.match(n.detail,/NHL timeout/);assert.match(n.detail,/NFL failure/);
});
test('aggregate retry keeps source warnings and age while updating', () => {
  const n=notice.noticeFor({kind:'following',hasData:true,loading:true,affectedLeagues:[{displayName:'NHL',stale:true,lastSuccessAt:old}]},now);
  assert.match(n.summary,/NHL.*5 min ago.*updating/);assert.equal(n.canRetry,false);assert.equal(n.severity,'warning');
});
test('source objects are not mutated and duplicate names are combined', () => {
  const s={hasData:true,affectedLeagues:[{displayName:'NHL',failed:true},{displayName:'NHL',failed:true}]}; const before=JSON.stringify(s);
  assert.equal(notice.noticeFor(s,now).summary,'NHL · updates delayed');assert.equal(JSON.stringify(s),before);
});
test('aggregate identity stays stable when polling changes affected leagues', () => {
  const a=notice.noticeFor({kind:'following',hasData:true,affectedLeagues:['NHL']},now);
  const b=notice.noticeFor({kind:'following',hasData:true,affectedLeagues:['NHL','NFL']},now);
  assert.equal(a.id,b.id);
  assert.notEqual(notice.noticeFor({contextKey:'team:nhl:6',partial:true,kind:'schedule'},now).id,
    notice.noticeFor({contextKey:'team:nfl:2',partial:true,kind:'schedule'},now).id);
});
test('array-like QVariantList sources are admitted with a fixed bound', () => {
  const n=notice.noticeFor({hasData:true,affectedLeagues:{0:{displayName:'NHL',failed:true},length:1}},now);
  assert.equal(n.summary,'NHL · updates delayed');
  const huge={length:1e12}; huge[0]={displayName:'NHL',failed:true};
  assert.equal(notice.noticeFor({hasData:true,affectedLeagues:huge},now).affectedLeagueIds.length,1);
});
test('invalid and future timestamps remain honest', () => {
  assert.equal(notice.ageFor('bad',now),'age unavailable');
  assert.equal(notice.ageFor('2026-11-25T12:00:00Z',now),'age unavailable');
});
test('untrusted text is bounded and display stays plain', () => {
  const n=notice.noticeFor({failed:true,displayName:'NHL\u202e',errorSummary:'<img src="https://example.invalid">'+ 'x'.repeat(2000)},now);
  assert.equal(n.detail.length,512); assert.doesNotMatch(n.summary,/\u202e/);
  assert.match(n.detail,/^<img/); // Renderer, never the model, owns PlainText.
});
test('explicit retry policy can suppress recovery but never enable it while loading', () => {
  assert.equal(notice.noticeFor({failed:true,canRetry:false},now).canRetry,false);
  assert.equal(notice.noticeFor({loading:true,failed:true,canRetry:true},now).canRetry,false);
});
test('QML require-free scope produces the same normalized model', () => {
  const scope={Date}; vm.createContext(scope);vm.runInContext(fs.readFileSync(require.resolve('../model/NoticePresentation.js'),'utf8'),scope);
  const state={displayName:'NHL',stale:true,lastSuccessAt:old};
  assert.equal(JSON.stringify(scope.noticeFor(state,now)),JSON.stringify(notice.noticeFor(state,now)));
});
console.log('Notice presentation: '+count+' checks passed');
