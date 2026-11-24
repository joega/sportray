const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const agenda = require('../model/AgendaPresentation.js');
let checks = 0;
function test(name, body) { body(); console.log('ok '+(++checks)+' - '+name); }
function entry(id, dateKey, status='scheduled') { return {dateKey, game: {id,status,awayTeam:{id:'nhl:6',shortName:'Bruins'},homeTeam:{id:'nhl:10',name:'Toronto Maple Leafs'},awayScore:3,homeScore:2}}; }
test('date columns validate actual calendar dates', () => {
  assert.deepEqual(agenda.dateParts('2026-11-27'),{key:'2026-11-27',year:2026,month:11,day:27,weekday:'Fri',monthLabel:'Nov',ordinal:20784,weekDay:5});
  for(const invalid of ['2026-02-30','2025-02-29','date','',null,'2026-11-27extra']) assert.equal(agenda.dateParts(invalid),null);
  assert.equal(agenda.dateParts('2028-02-29').day,29);
});
test('weeks start on Monday across weekends and month boundaries', () => {
  assert.equal(agenda.weekLabel('2026-11-29','2026-11-24'),'This week');
  assert.equal(agenda.weekLabel('2026-11-30','2026-11-24'),'Next week');
  assert.equal(agenda.weekLabel('2026-12-06','2026-11-24'),'Next week');
  assert.equal(agenda.weekLabel('2026-12-07','2026-11-24'),'Week of Dec 7');
});
test('relative week labels remain local-date and year aware', () => {
  assert.equal(agenda.weekLabel('2027-01-04','2026-11-24'),'Week of Jan 4, 2027');
  assert.equal(agenda.weekLabel('2026-12-28','2026-12-30'),'This week');
  assert.equal(agenda.weekLabel('2027-01-03','2026-12-30'),'This week');
  assert.equal(agenda.weekLabel('2027-01-04','2026-12-30'),'Next week');
  assert.equal(agenda.weekLabel('2026-03-08','2026-03-03'),'This week');
  assert.equal(agenda.weekLabel('2026-03-09','2026-03-03'),'Next week');
});
test('group headings appear once per contiguous week without changing entries', () => {
  const entries=['2026-11-27','2026-11-29','2026-11-30','2026-12-02','2026-12-07'].map((date,i)=>entry(String(i),date));
  const before=JSON.stringify(entries);
  assert.deepEqual(agenda.sectionLabels(entries,'2026-11-24'),['This week','','Next week','','Week of Dec 7']);
  assert.equal(JSON.stringify(entries),before);
  assert.deepEqual(agenda.sectionLabels(Array(257).fill(entries[0]),'2026-11-24'),[]);
  assert.deepEqual(agenda.sectionLabels(null,'2026-11-24'),[]);
});
test('opponent presentation distinguishes home, road and unknown teams', () => {
  const game=entry('1','2026-11-27');
  assert.deepEqual(agenda.opponent(game,'nhl:6'),{team:game.game.homeTeam,prefix:'at'});
  assert.deepEqual(agenda.opponent(game,'nhl:10'),{team:game.game.awayTeam,prefix:'vs'});
  assert.equal(agenda.opponent(game,'nhl:99'),null);
  assert.equal(agenda.teamLabel(game.game.homeTeam),'Toronto Maple Leafs');
  assert.equal(agenda.teamLabel(null),'Team unavailable');
});
test('scores appear only for played game states with both normalized scores', () => {
  for(const status of ['live','intermission','final']) assert.equal(agenda.score(entry('1','2026-11-27',status)),'3–2');
  for(const status of ['scheduled','postponed','canceled','unknown']) assert.equal(agenda.score(entry('1','2026-11-27',status)),'');
  const missing=entry('1','2026-11-27','final'); missing.game.homeScore=null;
  assert.equal(agenda.score(missing),'');
  missing.game.homeScore=NaN; assert.equal(agenda.score(missing),'');
});
test('QML require-free scope produces identical groups and opponent data', () => {
  const context={}; vm.createContext(context); vm.runInContext(fs.readFileSync(require.resolve('../model/AgendaPresentation.js'),'utf8'),context);
  const entries=[entry('1','2026-11-27'),entry('2','2026-11-30')];
  assert.deepEqual(JSON.parse(JSON.stringify(context.sectionLabels(entries,'2026-11-24'))),['This week','Next week']);
  assert.equal(context.opponent(entries[0],'nhl:6').prefix,'at');
});
console.log('PASS '+checks+' agenda presentation checks');
