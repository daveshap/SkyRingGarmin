#!/usr/bin/env node
// Replay the actual Monkey C arithmetic and rim/phase drawing methods.
// This checks numerical/geometry behavior, not Garmin VM timing or rendering.
// Reference: captured USNO celnav and one-day data, Hillsborough city center,
// 36.075 N, 79.10 W, 2026-09-24. See docs/LUNAR_CALCULATIONS.md.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
Number.prototype.toDouble = function () { return +this; };
Number.prototype.toFloat = function () { return Math.fround(+this); };
Number.prototype.toLong = Number.prototype.toNumber = function () { return Math.trunc(+this); };
Number.prototype.abs = function () { return Math.abs(+this); };
function translate(s) {
    return s.replace(/^import .*;$/gm, '').replace(/\(:test\)/g, '')
        .replace(/\b(\d+(?:\.\d+)?)d\b/g, '$1').replace(/\bprivate /g, '')
        .replace(/ as (?:Toybox\.Lang\.|Graphics\.)?(?:Array|Dictionary|Number|Numeric|Boolean|Float|Double|Void|Dc)\b\??/g, '')
        .replace(/\.size\(\)/g, '.length').replace(/:(\w+)\s*=>/g, '$1:')
        .replace(/\[:(\w+)\]/g, '["$1"]');
}
function load(name, exports) {
    const s = translate(fs.readFileSync(path.join(root, 'source', name + '.mc'), 'utf8'))
        .replace('module ' + name + ' {', '(()=>{')
        .replace(/}\s*$/, 'return {' + exports + '};})()');
    return eval(s);
}
const Lunar = load('Lunar', 'coordinates,position,signed');
const Astro = load('Astro', 'compute,w180');
const Test = { assert: x => assert.ok(x), assertEqual: (a,b) => assert.strictEqual(a,b) };
const testSource = fs.readFileSync(path.join(root, 'tests/LunarTests.mc'), 'utf8');
const testNames = [...testSource.matchAll(/\(:test\)\s*function\s+(\w+)\(/g)].map(m => m[1]);
eval(translate(testSource) + '\n' + testNames.map(n => n + '(null);').join('\n'));
console.log('PASS ' + testNames.length + ' position-only Monkey C test bodies');

const unix = s => Date.parse(s) / 1000;
const lat = 36.075, lon = -79.10, stamp = unix('2026-09-25T00:00:00Z');
const p = Lunar.position(stamp, lat, lon);
const a = Astro.compute(stamp, lat, lon, -14400);
assert.strictEqual(a.moonH, p.hourAngle);
assert.strictEqual(a.moonUp, p.horizon > 0);
assert.strictEqual(a.illum, p.illumination);
assert.strictEqual(a.waxing, p.waxing);
for (const tz of [-43200, 0, 19800, 50400]) {
    const shifted = Astro.compute(stamp, lat, lon, tz);
    for (const k of ['sunH', 'moonH', 'moonAlt', 'moonUp', 'illum', 'waxing']) {
        assert.strictEqual(shifted[k], a[k], 'Timezone changed physical position: ' + k);
    }
}
// Daily solar approximation should agree to within two minutes with USNO.
assert(Math.abs(a.riseMin - (7*60+6)) <= 2);
assert(Math.abs(a.setMin - (19*60+10)) <= 2);
const transit = Astro.compute(unix('2026-09-24T17:08:00Z'), lat, lon, -14400);
assert(Math.abs(transit.sunH) < 0.5, 'Solar upper transit must be at top');
const lunarTransit = Lunar.position(unix('2026-09-25T03:57:00Z'), lat, lon);
assert(Math.abs(lunarTransit.hourAngle) < 0.5, 'Lunar upper transit must be at top');
console.log('PASS USNO solar rise/set/transits, UTC basis, and timezone-independent positions');

// Check only a few known instants around captured USNO rise/set times. There
// is deliberately no production event search or worker state in this build.
for (const [at, rising] of [
    ['2026-09-24T22:07:00Z', true], ['2026-09-24T08:52:00Z', false]
]) {
    const before = Lunar.position(unix(at)-600, lat, lon);
    const after = Lunar.position(unix(at)+600, lat, lon);
    assert.strictEqual(before.horizon > 0, !rising);
    assert.strictEqual(after.horizon > 0, rising);
}
const stillBelow = Lunar.position(unix('2026-09-24T21:57:00Z'), lat, lon);
assert(stillBelow.hourAngle > -90 && stillBelow.hourAngle < 0 && stillBelow.horizon < 0);
console.log('PASS lunar above/below horizon follows lunar altitude, not the solar horizon or dial half');

const view = fs.readFileSync(path.join(root, 'source/SkyRingView.mc'), 'utf8');
function method(name) {
    const at = view.indexOf('function ' + name + '(');
    assert(at >= 0, 'Missing method ' + name);
    let cursor = view.indexOf('{', at), depth = 1;
    while (depth) { cursor++; if (view[cursor] === '{') depth++; if (view[cursor] === '}') depth--; }
    return eval('(' + translate(view.slice(at, cursor+1)) + ')');
}
const polar = method('polar');
for (const [h, expected] of [[0,[0,-214]], [-90,[-214,0]], [90,[214,0]], [180,[0,214]]]) {
    const actual = polar(0,0,214,h);
    assert(Math.hypot(actual[0]-expected[0], actual[1]-expected[1]) < 0.001);
}
const marker = polar(227,227,214,a.moonH);
assert(marker[0] < 227 && marker[1] < 227);
const nextMarker = Lunar.position(stamp+3600, lat, lon);
assert(Lunar.signed(nextMarker.hourAngle-p.hourAngle) > 10);
assert(Lunar.signed(nextMarker.hourAngle-p.hourAngle) < 16);
assert(/polar\(cx, cy, Lay\.MARKER_R, a\[:moonH\]/.test(view));
assert(/var moonUp = a\[:moonUp\]/.test(view));
console.log('PASS source rim mapping: top=upper transit, left=approaching, right=after, bottom=lower transit');

// Software sample of source drawMoon calls. Garmin fillEllipse takes center
// and x/y radii, verified in the bundled SDK Dc reference.
const Graphics = { COLOR_TRANSPARENT: -1 };
const Fmt = { round: x => Math.trunc(x < 0 ? x-0.5 : x+0.5) };
const drawMoon = method('drawMoon');
function render(k, waxing, south) {
    let color = 0, clip = null;
    const r = 10, samples = [];
    // Quarter-pixel samples check illumination area without display antialiasing.
    for (let y=-r+0.125;y<r;y+=0.25) for(let x=-r+0.125;x<r;x+=0.25) {
        if (x*x+y*y<=r*r) samples.push({x,y,lit:0});
    }
    const paint = predicate => {
        for(const s of samples) {
            if (clip && (s.x<clip[0] || s.x>=clip[0]+clip[2] || s.y<clip[1] || s.y>=clip[1]+clip[3])) continue;
            if(predicate(s)) s.lit=color;
        }
    };
    const dc = {
        setColor(c) { color=c; },
        fillCircle(x,y,r) { paint(s=>(s.x-x)**2+(s.y-y)**2<=r*r); },
        fillEllipse(x,y,a,b) { paint(s=>((s.x-x)/a)**2+((s.y-y)/b)**2<=1); },
        setClip(...args) { clip=args; }, clearClip() { clip=null; }
    };
    drawMoon(dc,0,0,r,k,waxing,south,1,0);
    return { fraction:samples.reduce((n,s)=>n+s.lit,0)/samples.length,
        left:samples.filter(s=>s.x<0&&s.lit).length, right:samples.filter(s=>s.x>0&&s.lit).length };
}
for(const k of [0,0.05,0.25,0.5,0.75,0.95,1]) {
    for(const waxing of [false,true]) for(const south of [false,true]) {
        const disc=render(k,waxing,south);
        assert(Math.abs(disc.fraction-k)<0.04, 'Phase area wrong: '+JSON.stringify({k,waxing,south,disc}));
        if(k>0&&k<1) assert.strictEqual(disc.right>disc.left, waxing!==south);
    }
}
console.log('PASS source phase disc: new/quarter/gibbous/full, waxing/waning and hemisphere orientation');
console.log('Reference lunar H='+p.hourAngle.toFixed(5)+' deg, apparent altitude='+p.altitude.toFixed(3)+
    ' deg, illumination='+(100*p.illumination).toFixed(2)+'%, marker x/y='+marker.map(v=>v.toFixed(1)).join('/'));
console.log('All arithmetic/geometry checks passed. Actual Garmin VM/device execution is not measured here.');
