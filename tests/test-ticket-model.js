const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ticker = require('../model/TicketPresentation.js');
const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, '../fixtures/bar-presentation/ticket-strip.json')));
let checks = 0;
function test(name, run) { run(); checks++; console.log(`ok ${checks} - ${name}`); }
const describe = id => ({nhl:{label:'NHL',sport:'hockey'},'usa.1':{label:'MLS',sport:'soccer'},'eng.1':{label:'Premier League',sport:'soccer'}}[id]);
function build(games = fixture.games) { return ticker.build({games, favoriteTeamIds:['usa.1:3'],nowMs:Date.parse(fixture.now),formatStartTime:()=> '8:00 PM',leagueInfo:describe}); }
test('existing order, caps and display text remain intact', () => {
 const result=build(); assert.deepEqual(result.entries.map(e=>e.game.id),fixture.expectedOrder);
 fixture.expectedSegments.forEach(s=>assert.ok(result.text.includes(s),s));
 assert.equal(result.items.length,result.entries.length);
});
test('render items carry stable identity, favorite and live-state semantics',()=>{
 const result=build(); const live=result.items.find(i=>i.gameId==='live');
 assert.equal(live.status,'live'); assert.equal(live.isLive,true); assert.equal(live.favorite,false); assert.equal(live.leagueId,'nhl');
 const fav=result.items.find(i=>i.gameId==='scheduled-two'); assert.equal(fav.favorite,true);assert.equal(fav.isLive,false);
 assert.equal(result.items.find(i=>i.gameId==='recent-final').isLive,false);
});
test('tooltip keeps full team identities and the admitted provider',()=>{
 const game={...fixture.games.find(g=>g.id==='live'),awayTeam:{id:'nhl:6',abbreviation:'BOS',name:'Boston Bruins'},homeTeam:{id:'nhl:10',abbreviation:'TOR',name:'Toronto Maple Leafs'},link:'https://www.nhl.com/gamecenter/1'};
 const item=build([game]).items[0]; assert.equal(item.fullMatchup,'Boston Bruins at Toronto Maple Leafs');
 assert.equal(item.providerName,'NHL.com');assert.ok(item.tooltip.includes('NHL.com'));assert.ok(item.tooltip.includes('2nd 04:12'));
});
test('unsafe source stays neutral and cannot claim a provider',()=>{
 const game={...fixture.games.find(g=>g.id==='live'),link:'https://espn.com.evil.example/a'};
 const item=build([game]).items[0];assert.equal(item.sourceUrl,'');assert.equal(item.providerName,'');assert.ok(item.tooltip.includes('Open scores'));
});
test('compact live context keeps clock ahead of optional detail without inventing baseball time',()=>{
 const original=fixture.games.find(g=>g.id==='live');
 const item=build([{...original,statusDetail:'Power play'}]).items[0];
 assert.equal(item.displayDetail,'2nd 04:12');assert.ok(item.tooltip.includes('Power play'));
 const baseball=ticker.build({games:[{...original,league:'mlb',periodLabel:'Top 7th',statusDetail:'2 outs',clock:'99:99'}],nowMs:Date.parse(fixture.now),leagueInfo:()=>({label:'MLB',sport:'baseball'})}).items[0];
 assert.equal(baseball.displayDetail,'Top 7th');assert.equal(baseball.tooltip.includes('99:99'),false);
});
test('tooltip and identity strings are bounded without hiding literal markup',()=>{
 const game={...fixture.games.find(g=>g.id==='live'),id:'x'.repeat(1000),awayTeam:{name:'<img src="https://example.invalid">'+ 'x'.repeat(1000)},homeTeam:{name:'z'.repeat(1000)}};
 const item=build([game]).items[0]; assert.ok(item.gameId.length<=80);assert.ok(item.fullMatchup.length<=132);assert.ok(item.tooltip.length<300); assert.ok(item.tooltip.includes('<img'));
});
test('24-game and age windows remain unchanged',()=>{
 const original=fixture.games.find(g=>g.id==='live');
 assert.equal(build(Array.from({length:80},(_,i)=>({...original,id:String(i)}))).items.length,ticker.MAX_GAMES);
 assert.equal(ticker.MAX_GAMES,24);assert.equal(ticker.FINAL_WINDOW_MS,12*60*60*1000);
});
test('require-free QML scope produces the same enriched items',()=>{
 const source=fs.readFileSync(path.join(__dirname,'../model/TicketPresentation.js'),'utf8');
 const context=vm.createContext({Date,JSON,Math});vm.runInContext(source,context);
 const actual=context.build({games:fixture.games,favoriteTeamIds:['usa.1:3'],nowMs:Date.parse(fixture.now),formatStartTime:()=> '8:00 PM',leagueInfo:describe});
 assert.deepEqual(JSON.parse(JSON.stringify(actual)),build());
});
console.log(`Ticker model: ${checks} checks passed`);
