const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const contrast = require('../model/UiContrast.js');
let count = 0;
function test(name, body) { body(); console.log('ok '+(++count)+' - '+name); }
function near(actual, expected, tolerance=0.0001) { assert.ok(Math.abs(actual-expected)<=tolerance, `${actual} != ${expected}`); }
const latte = {background:'#eff1f5', text:'#4c4f69', accent:'#1e66f5', urgent:'#d20f39'};
const dark = {background:'#1e1e2e', text:'#cdd6f4', accent:'#89b4fa', urgent:'#f38ba8'};
function alpha(color, value) { return {...contrast.rgba(color),a:value}; }

test('WCAG luminance gives21 for black/white and1 for identical colors', () => {
  near(contrast.contrastRatio('#000','#fff'),21); near(contrast.contrastRatio('#fff','#fff'),1);
  near(contrast.contrastRatio('#fff','#000'),21);
});
test('Qt QColor channels and Qt hex notation produce the same result', () => {
  assert.deepEqual(contrast.rgba('#804c4f69'),{...contrast.rgba(latte.text),a:128/255});
  near(contrast.contrastRatio(contrast.rgba(latte.text),contrast.rgba(latte.background)),7.0620);
});
test('Latte small accent text uses the theme text fallback', () => {
  near(contrast.contrastRatio(latte.accent,latte.background),4.3448);
  assert.equal(contrast.foreground(latte.accent,latte.text,latte.background),latte.text);
});
test('dark accent text retains the accent', () => {
  near(contrast.contrastRatio(dark.accent,dark.background),7.7889);
  assert.equal(contrast.foreground(dark.accent,dark.text,dark.background),dark.accent);
});
test('hover and focus fill are composited before evaluating link contrast', () => {
  for (const theme of [latte,dark]) {
    const hover=contrast.composite(alpha(theme.text,.08),theme.background);
    const choice=contrast.foreground(theme.accent,theme.text,hover);
    assert.equal(choice,theme===latte?theme.text:theme.accent);
    assert.ok(contrast.contrastRatio(choice,hover)>=4.5);
  }
  near(contrast.contrastRatio(latte.accent,contrast.composite(alpha(latte.text,.08),latte.background)),3.8650);
});
test('Next up accent fill does not make Latte accent text readable', () => {
  for (const theme of [latte,dark]) {
    const fill=contrast.composite(alpha(theme.accent,.06),theme.background);
    assert.equal(contrast.foreground(theme.accent,theme.text,fill),theme===latte?theme.text:theme.accent);
    assert.ok(contrast.contrastRatio(contrast.foreground(theme.accent,theme.text,fill),fill)>=4.5);
  }
});
test('transparent captions are judged against their actual hover background', () => {
  const caption=alpha(latte.text,.85), hover=contrast.composite(alpha(latte.text,.08),latte.background);
  assert.equal(contrast.foreground(caption,latte.text,latte.background),caption);
  near(contrast.contrastRatio(caption,hover),4.4735);
  assert.equal(contrast.foreground(caption,latte.text,hover),latte.text);
  assert.equal(contrast.foreground(alpha(latte.text,.62),latte.text,latte.background),latte.text);
});
test('stock error text and selected Following button text pass in both themes', () => {
  for (const theme of [latte,dark]) {
    assert.equal(contrast.foreground(theme.urgent,theme.text,theme.background),theme.urgent);
    const selected=contrast.composite(alpha(theme.text,.18),theme.background);
    assert.ok(contrast.contrastRatio(theme.text,selected)>=4.5);
  }
});
test('source over preserves alpha and handles fully transparent sources', () => {
  assert.deepEqual(contrast.composite('#00000000','#00000000'),{r:0,g:0,b:0,a:0});
  assert.deepEqual(contrast.composite('#00000000','#fff'),{r:1,g:1,b:1,a:1});
  const result=contrast.composite({r:1,g:0,b:0,a:.5},{r:0,g:0,b:1,a:.5});
  near(result.r,2/3); near(result.b,1/3); near(result.a,.75);
});
test('invalid channels, malformed strings, and unknown backgrounds fail closed', () => {
  for (const bad of [null,undefined,{},'red','#ff','#12345','#gggggg',42,{r:NaN,g:0,b:0},{r:2,g:0,b:0},{r:0,g:0,b:0,a:-1}]) {
    assert.equal(contrast.rgba(bad),null); assert.equal(contrast.contrastRatio(bad,'#fff'),null);
    assert.equal(contrast.foreground(bad,latte.text,'#fff'),latte.text);
  }
  assert.equal(contrast.contrastRatio('#fff','#80000000'),null);
  assert.equal(contrast.foreground('#fff',latte.text,'bad'),latte.text);
});
test('explicit large-text threshold works and malformed thresholds keep4.5', () => {
  assert.equal(contrast.foreground(latte.accent,latte.text,latte.background,3),latte.accent);
  for (const threshold of [NaN,Infinity,0,22,'3'])
    assert.equal(contrast.foreground(latte.accent,latte.text,latte.background,threshold),latte.text);
});
test('native QColor values retain identity and inputs are never mutated', () => {
  const preferred=Object.freeze(contrast.rgba(dark.accent)), background=Object.freeze(contrast.rgba(dark.background));
  const fallback=Object.freeze(contrast.rgba(dark.text));
  assert.equal(contrast.foreground(preferred,fallback,background),preferred);
  assert.notEqual(contrast.composite(preferred,background),preferred);
  assert.equal(contrast.foreground(preferred,fallback,background,21),fallback);
});
test('QML require-free scope evaluates identical contrast decisions', () => {
  const scope={}; vm.createContext(scope);
  vm.runInContext(fs.readFileSync(require.resolve('../model/UiContrast.js'),'utf8'),scope);
  assert.equal(scope.foreground(latte.accent,latte.text,latte.background),latte.text);
  near(scope.contrastRatio(dark.accent,dark.background),7.7889);
});
console.log('PASS '+count+' UI contrast checks');
