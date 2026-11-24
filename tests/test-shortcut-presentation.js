const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const model = require('../model/ShortcutPresentation.js');
let count=0;
function test(name, body) { body(); console.log('ok '+(++count)+' - '+name); }
function keys(context) { return model.forContext(context).flatMap(group=>group.rows.map(row=>row.keys)); }
test('F appears only in Following scores or team settings',()=>{
  assert(keys({following:true}).includes('F')); assert(!keys({following:false}).includes('F'));
  assert(!keys({surface:'standings',following:true}).includes('F'));
  assert(keys({surface:'settings',section:'teams'}).includes('F'));
});
test('calendar pages keep date/range and native Tab semantics',()=>{
  assert(keys({surface:'calendar'}).includes('Arrows')); assert(!keys({surface:'team'}).includes('Arrows'));
  for(const surface of ['calendar','team']) assert(keys({surface}).includes('Page Up / Down'));
});
test('details do not advertise unsupported refresh or settings shortcuts',()=>{
  for(const value of ['R','N','G','S','F']) assert(!keys({surface:'detail'}).includes(value));
  assert(keys({surface:'detail'}).includes('Home / End'));
});
test('Undo is contextual and team review is scoped',()=>{
  assert(!keys({}).includes('Ctrl+Z')); assert(keys({canUndo:true}).includes('Ctrl+Z'));
  assert(keys({surface:'settings',section:'teams'}).includes('V'));
  assert(!keys({surface:'settings',section:'sports'}).includes('V'));
});
test('static groups remain bounded and do not mutate context',()=>{
  for(const surface of ['scores','standings','calendar','team','detail','settings']) {
    const input={surface,following:true,canUndo:true,section:'teams'}, before=JSON.stringify(input), rows=keys(input);
    assert(rows.length<=17); assert.equal(new Set(rows).size,rows.length); assert.equal(JSON.stringify(input),before);
  }
});
test('QML require-free module produces identical help',()=>{
  const scope={};vm.createContext(scope);vm.runInContext(fs.readFileSync(require.resolve('../model/ShortcutPresentation.js'),'utf8'),scope);
  assert.equal(JSON.stringify(scope.forContext({surface:'calendar'})),JSON.stringify(model.forContext({surface:'calendar'})));
});
console.log('Shortcut presentation: '+count+' checks passed');
