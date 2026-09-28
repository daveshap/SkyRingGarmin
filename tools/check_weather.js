#!/usr/bin/env node
// Focused host regression checks for actual Monkey C weather source.
// Strings are distinct objects, including source literals, so identity == does
// not silently pass as JavaScript primitive-string content equality. This is
// still a small adapter, NOT the Garmin VM, simulator, or a device render.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const source = name => fs.readFileSync(path.join(root, 'source', name + '.mc'), 'utf8');
class McString extends String {
    equals(other) {
        return (typeof other === 'string' || other instanceof String) && String(this) === String(other);
    }
}
const mcString = value => new McString(value);
const isMcNumber = value => typeof value === 'number' && Number.isInteger(value);
const isMcFloat = value => typeof value === 'number';
Number.prototype.toFloat = function () { return Math.fround(+this); };
Number.prototype.toNumber = function () { return Math.trunc(+this); };
Number.prototype.format = function (format) {
    assert.equal(String(format), '%d');
    return mcString(String(Math.trunc(+this)));
};
Array.prototype.add = function (value) { this.push(value); };
function clean(s) { return s.replace(/\/\/[^\n]*/g, ''); }
function translate(s) {
    return clean(s).replace(/\bprivate\s+/g, '')
        .replace(/\bas\s+(?:Array<[^>]+>|(?:\w+\.)*\w+)\??/g, '')
        .replace(/\.size\(\)/g, '.length')
        .replace(/\[:(\w+)\]/g, '["$1"]')
        .replace(/(\w+) instanceof Number/g, 'isMcNumber($1)')
        .replace(/(\w+) instanceof Float/g, 'isMcFloat($1)')
        .replace(/"(?:\\.|[^"\\])*"/g, literal => 'mcString(' + literal + ')');
}
function block(s, prefix) {
    const start = s.indexOf(prefix);
    assert(start >= 0, 'Missing source block: ' + prefix);
    let cursor = s.indexOf('{', start), depth = 1;
    const body = cursor + 1;
    while (depth && ++cursor < s.length) {
        if (s[cursor] === '{') depth++;
        if (s[cursor] === '}') depth--;
    }
    assert.equal(depth, 0);
    return s.slice(body, cursor);
}
function moduleFrom(name, file = name) {
    const body = block(source(file), 'module ' + name + ' ');
    const names = [...body.matchAll(/\b(?:const|function)\s+(\w+)/g)].map(m => m[1]);
    return eval('(()=>{' + translate(body) + ';return {' + names.join(',') + '};})()');
}
const Pal = moduleFrom('Pal', 'Fmt'), Fmt = moduleFrom('Fmt');
const ChartColors = moduleFrom('ChartColors'), Lay = moduleFrom('Lay', 'SkyRingView');
const view = source('SkyRingView');
function method(name) {
    const prefix = 'function ' + name + '(';
    const start = view.indexOf(prefix);
    const code = view.slice(start, view.indexOf('{', start) + 1) + block(view, prefix) + '}';
    return eval('(' + translate(code) + ')');
}
const colors = { c:'SUN',p:'SUN',t:'SUN',n:'MOON',q:'MOON',C:'CLOUD',f:'FOG',r:'RAIN',s:'SNOW',w:'WIND' };
for (const [ch, color] of Object.entries(colors)) {
    assert.equal(ChartColors.condition(mcString(ch)), ChartColors['WEATHER_' + color], ch);
}
for (const ch of ['?', 'future']) assert.equal(ChartColors.condition(mcString(ch)), Pal.DIMMER);
assert.equal(ChartColors.condition(mcString('p')), 0xFFF000);

// Prove that this harness detects the exact former identity-comparison bug.
const mutantBody = block(source('ChartColors'), 'function condition(')
    .replace(/glyph\.equals\(("[^"]+")\)/g, '(glyph == $1)')
    .replace(/\bWEATHER_(\w+)\b/g, 'ChartColors.WEATHER_$1');
const mutant = eval('(function(glyph){' + translate(mutantBody) + '})');
assert.equal(mutant(mcString('p')), Pal.DIMMER);
assert.notEqual(mutant(mcString('p')), ChartColors.WEATHER_SUN);
console.log('PASS weather color routing: distinct strings for all glyphs; former == implementation fails');

for (const [level, expected] of [[0,'GREEN'],[2,'GREEN'],[3,'YELLOW'],[5,'YELLOW'],
    [6,'ORANGE'],[7,'ORANGE'],[8,'RED'],[10,'RED'],[11,'PURPLE'],[15,'PURPLE']]) {
    assert.equal(ChartColors.uvIndex(level), ChartColors[expected]);
}
for (const value of [null,-1,2.5,mcString('2')]) assert.equal(ChartColors.uvIndex(value), Pal.DIMMER);

const fI22 = 'icons28', fN28 = 'numbers28', fL18 = 'labels18', aN28 = 28, aL18 = 18;
let calls = [];
function glyph(dc,x,y,font,ch,color) { calls.push({kind:'glyph',x,y,glyph:String(ch),color}); }
function text(dc,x,base,font,asc,color,value) { calls.push({kind:'text',x,base,value:String(value),color}); }
function tw(dc,value,font) { return String(value).length * (font === fN28 ? 13 : 8); }
const drawConditionIcon = method('drawConditionIcon');
const iconLayers = {};
for (const [ch, color] of Object.entries(colors)) {
    calls = [];
    drawConditionIcon({},0,0,mcString(ch));
    const overlay = ['p','q'].includes(ch) ? 'g' : ['r','s','t'].includes(ch) ? 'k' : null;
    assert.deepEqual(calls.map(c=>[c.glyph,c.color]), [[ch,ChartColors['WEATHER_' + color]],
        ...(overlay ? [[overlay,ChartColors.WEATHER_CLOUD]] : [])]);
    iconLayers[ch] = calls.map(({glyph,color})=>({glyph,color}));
}
console.log('PASS actual drawConditionIcon layers: yellow sun + silver cloud; lavender moon; vivid precipitation');

let mWxAgeMin = 0, mUv = 8, mCond = 1, mHiC = null, mLoC = null, mTempC = 21;
let mHum = 62, mDewC = 12, mRainPct = 0, mEnvCycleAt = -1, mEnvShowDew = false, mStatuteTemp = true;
let mAstro = {sunUp:true};
const condGlyph = method('condGlyph'), tempStr = method('tempStr');
const updateWeatherCycle = method('updateWeatherCycle');
const itemWidth = method('itemWidth'), rowWidth = method('rowWidth'), drawEnv = method('drawEnv');
function env(now = 100) { calls = []; drawEnv({},227,227,now); return calls.slice(); }
function resetCycle() { mEnvCycleAt = -1; mEnvShowDew = false; }
const glyphCall = (cs,ch) => cs.find(c=>c.kind==='glyph' && c.glyph===ch);
const textCall = (cs,value) => cs.find(c=>c.kind==='text' && c.value===value);
for (const age of [0,120,121,300]) {
    resetCycle();
    mWxAgeMin = age;
    for (const [now,ch,color] of [[100,'D',ChartColors.WEATHER_HUMIDITY],
        [101,'D',ChartColors.WEATHER_HUMIDITY],[102,'d',Pal.DEW],[103,'d',Pal.DEW],
        [104,'D',ChartColors.WEATHER_HUMIDITY]]) {
        const cs = env(now);
        assert.equal(glyphCall(cs,'p').color,0xFFF000);
        assert.equal(glyphCall(cs,'g').color,ChartColors.WEATHER_CLOUD);
        assert.equal(glyphCall(cs,ch).color,color);
        assert.equal(textCall(cs,'70°').color,age>120?Pal.DIM:Pal.INK);
        assert.equal(textCall(cs,'UV').color,ChartColors.RED);
        assert.equal(textCall(cs,'8').color,Pal.lerp(ChartColors.RED,Pal.INK,0.65));
    }
}
mWxAgeMin = 0;
resetCycle();
const rh = env(100), dew = env(102);
assert.equal(textCall(rh,'UV').x,textCall(dew,'UV').x,'UV stays fixed across alternation');
assert.equal(textCall(rh,'70°').x,textCall(dew,'70°').x,'Temperature stays fixed');
assert.equal(textCall(rh,'62%').color,Pal.lerp(ChartColors.WEATHER_HUMIDITY,Pal.INK,0.65));
assert.equal(textCall(dew,'54°').color,Pal.lerp(Pal.DEW,Pal.INK,0.65));
mHum = null;
resetCycle();
assert(glyphCall(env(100),'d'),'Missing RH shows available dew immediately');
mDewC = null;
resetCycle();
assert(glyphCall(env(102),'D'),'Both missing retains RH placeholder');
mHum = 62;
resetCycle();
assert(glyphCall(env(102),'D'),'Missing dew retains RH throughout cycle');
mDewC = 0;
resetCycle(); env(100);
assert(textCall(env(102),'32°'),'Zero Celsius dew is valid');
mDewC = -5;
resetCycle(); env(100);
assert(textCall(env(102),'23°'),'Negative dew is valid');
mUv = null;
assert.equal(textCall(env(100),'UV').color,Pal.DIMMER);
mRainPct = 29;
assert(textCall(env(100),'UV'));
mRainPct = 30;
const rain = env(100);
assert.equal(glyphCall(rain,'u').color,ChartColors.WEATHER_RAIN);
assert(!textCall(rain,'UV'));
console.log('PASS actual weather row: content-based UV/RH/dew routing, null fields, stale colors, 2s alternation, rain threshold');

// The visible frame advances once after two seconds. Missed frames must not
// repeatedly land on the same modulo phase, and duplicate frames do no work.
mRainPct = 0; mUv = 8; mHum = 62; mDewC = 12;
resetCycle();
for (let t = 100; t <= 220; t++) {
    const expected = Math.floor((t - 100) / 2) % 2 === 1 ? 'd' : 'D';
    assert(glyphCall(env(t),expected),'Two-minute continuous 1Hz cycle at ' + t);
}
resetCycle();
for (const [t,ch] of [[100,'D'],[104,'d'],[112,'D'],[172,'d']]) {
    assert(glyphCall(env(t),ch),'A delayed frame switches once at ' + t);
    assert.equal(mEnvCycleAt,t);
    assert(glyphCall(env(t),ch),'A duplicate frame does not switch at ' + t);
    assert.equal(mEnvCycleAt,t);
}
assert(glyphCall(env(173),'d'),'One second after a delayed switch stays visible');
assert(glyphCall(env(174),'D'));
assert(glyphCall(env(90),'D'),'Rollback restarts RH');
assert.equal(mEnvCycleAt,90);
assert(glyphCall(env(91),'D'));
assert(glyphCall(env(92),'d'));
mHum = null; mDewC = null;
resetCycle();
for (let t = 100; t <= 108; t++) {
    const cs = env(t);
    assert(glyphCall(cs,'D'),'No data retains RH identity');
    assert(!glyphCall(cs,'d'),'No dew icon for missing dew data');
    assert(textCall(cs,'--'),'No invented moisture reading');
}
console.log('PASS actual weather cycle: sustained 1Hz, 4/8/60s late frames, duplicates, clock rollback, absent readings');
const outputIndex = process.argv.indexOf('--layers');
if (outputIndex >= 0) {
    assert(process.argv[outputIndex + 1], '--layers requires a destination');
    fs.writeFileSync(process.argv[outputIndex + 1], JSON.stringify(iconLayers,null,2) + '\n');
}
