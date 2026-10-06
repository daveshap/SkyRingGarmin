#!/usr/bin/env node
// Execute production lifecycle/rotation methods with explicit fake firmware
// events. This checks our scheduler, not Garmin callback delivery or battery use.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const source = name => fs.readFileSync(path.join(root, 'source', name + '.mc'), 'utf8');
const view = source('SkyRingView');
function block(s, prefix) {
    const start = s.indexOf(prefix);
    assert(start >= 0, 'Missing source block: ' + prefix);
    let end = s.indexOf('{', start), depth = 1, body = end + 1;
    while (depth && ++end < s.length) {
        if (s[end] === '{') depth++;
        if (s[end] === '}') depth--;
    }
    assert.equal(depth, 0);
    return s.slice(body, end);
}
function translate(s) {
    return s.replace(/\/\/[^\n]*|\/\*[\s\S]*?\*\//g, '')
        .replace(/\bprivate\s+/g, '')
        .replace(/\bas\s+(?:Array<[^>]+>|(?:\w+\.)*\w+)\??/g, '')
        .replace(/(\w+) has :(\w+)/g, '("$2" in $1)')
        .replace(/method\(:(\w+)\)/g, '$1');
}
function method(name, s = view) {
    const prefix = 'function ' + name + '(';
    const start = s.indexOf(prefix);
    assert(start >= 0, prefix);
    return translate(s.slice(start, s.indexOf('{', start) + 1) + block(s, prefix) + '}');
}
function MoistureRotation() {
    return eval('(()=>{' + translate(block(source('MoistureRotation'), 'class MoistureRotation ')) +
        ';return {update,pause,isRotating,isDue,showDew};})()');
}
const System = { DISPLAY_MODE_OFF:0, DISPLAY_MODE_LOW_POWER:1, DISPLAY_MODE_HIGH_POWER:2 };
const WakeState = eval('(()=>{' + translate(block(source('WakeState'), 'module WakeState ')) +
    ';return {resolve,needsRefresh};})()');
function harness() {
    let ms = 0, civil = 600, mode = 2, queued = false;
    let requests = 0, paints = [], reads = 0, clears = 0, timerStarts = 0, timerStops = 0;
    let nativeHum = 62, nativeDew = 12, timers = [], lastCallback = null;
    const System = { DISPLAY_MODE_OFF:0, DISPLAY_MODE_LOW_POWER:1, DISPLAY_MODE_HIGH_POWER:2,
        getDisplayMode:()=>mode, getTimer:()=>ms, getClockTime:()=>({}) };
    const Time = { now:()=>({value:()=>civil}) };
    const Graphics = { COLOR_BLACK:0 };
    const WatchUi = { requestUpdate:()=>{ requests++; queued = true; } };
    const Timer = { Timer:class {
        constructor() { timers.push(this); this.active = false; }
        start(callback, interval, repeat) {
            assert.equal(interval, 2000); assert.equal(repeat, true);
            this.callback = lastCallback = callback; this.interval = interval;
            this.next = ms + interval; this.active = true; timerStarts++;
        }
        stop() { this.active = false; timerStops++; }
    }};
    const dc = {setColor(){}, clear(){clears++;}, getWidth:()=>454, getHeight:()=>454};
    const fieldStart = view.indexOf('private var fTime;');
    const fields = translate(view.slice(fieldStart, view.indexOf('function initialize()', fieldStart)));
    const names = ['onShow','onHide','onEnterSleep','onExitSleep','displayMode','isAwake',
        'onUpdate','stopMoistureTimer','pauseWeatherRotation','syncMoistureTimer','onMoistureTick'];
    let methods = names.map(n=>method(n)).join('\n');
    assert(methods.includes('var key = now.value() / 60;'));
    methods = methods.replace('var key = now.value() / 60;', 'var key = Math.trunc(now.value() / 60);');
    const api = eval(`(()=>{${fields}
        var refresh=()=>{reads++;mAstro={};mHum=nativeHum;mDewC=nativeDew;};
        var readStress=()=>{},drawRing=()=>{},drawHeader=()=>{},drawVitals=()=>{},drawRowA=()=>{},drawRowB=()=>{};
        var drawEnv=()=>paints.push({ms,civil,dew:mMoistureRotation.showDew()});
        ${methods}
        return {onShow,onHide,onEnterSleep,onExitSleep,onUpdate,onMoistureTick,
            state:()=>({dew:mMoistureRotation.showDew(),rotating:mMoistureRotation.isRotating(),
                allowed:mMoistureTimerAllowed,running:mMoistureTimerRunning})};
    })()`);
    function flush() {
        // Coalescing is explicit here; the normal-order tests below also run
        // without coalescing to account for a redundant queued paint.
        if (queued) { queued = false; api.onUpdate(dc); }
    }
    function tick() {
        for (const timer of timers) {
            if (timer.active && timer.next <= ms) {
                timer.next = ms + timer.interval;
                timer.callback();
            }
        }
    }
    function set(nextMs, opts = {}) {
        civil = opts.civil ?? civil + Math.floor((nextMs - ms) / 1000);
        ms = nextMs; mode = opts.mode ?? mode;
    }
    return {
        set,flush,tick,
        event:name=>api[name](),
        frame:()=>api.onUpdate(dc),
        queuedTick:()=>{ assert(lastCallback); lastCallback(); },
        weather:(rh,dew)=>{nativeHum=rh;nativeDew=dew;},
        start:()=>{api.onShow();api.onExitSleep();flush();},
        advance:target=>{
            while (timers.some(t=>t.active && t.next<=target)) {
                set(Math.min(...timers.filter(t=>t.active).map(t=>t.next)));
                tick();flush();
            }
            if (ms < target) set(target);
        },
        stats:()=>({requests,paints:paints.slice(),reads,clears,timerStarts,timerStops,...api.state()})
    };
}

// Execute the exact prior methods kept as a regression fixture, not a new
// implementation of the bug. This synthetic callback sequence demonstrates a
// weakness; it does not claim the user's firmware emitted that exact sequence.
function oldResetFixture() {
    const prior = fs.readFileSync(path.join(__dirname,'fixtures','moisture-before-ad4773b.mc'),'utf8');
    let t = 0;
    const System = {DISPLAY_MODE_OFF:0,DISPLAY_MODE_LOW_POWER:1,DISPLAY_MODE_HIGH_POWER:2,getClockTime:()=>({})};
    const Time = {now:()=>({value:()=>t})}, Graphics = {COLOR_BLACK:0}, WatchUi={requestUpdate(){}};
    let methods = ['onExitSleep','onUpdate','updateWeatherCycle'].map(n=>method(n,prior)).join('\n');
    methods=methods.replace('var key = now.value() / 60;', 'var key = Math.trunc(now.value() / 60);');
    return eval(`(()=>{
        var mLastFrameAt=-1,mLastDisplayMode=0,mEnvCycleAt=-1,mEnvShowDew=false,mSleeping=false;
        var mRefreshKey=-1,mHrHistoryPollAt=-1,mComplicationsDirty=false,mAstro={};
        var displayMode=()=>2,refresh=()=>{},readStress=()=>{};
        var drawRing=()=>{},drawHeader=()=>{},drawVitals=()=>{},drawRowA=()=>{},drawRowB=()=>{};
        var drawEnv=(dc,cx,cy,sec)=>updateWeatherCycle(sec);
        ${methods}
        return {wake:onExitSleep,frame:sec=>{t=sec;onUpdate({setColor(){},clear(){},getWidth:()=>454,getHeight:()=>454});return mEnvShowDew;}};
    })()`);
}
const old = oldResetFixture();
for (let sec=0;sec<=10;sec++) {old.wake();assert.equal(old.frame(sec),false);}
const repeated = harness(); repeated.start();
for (let sec=1;sec<=10;sec++) {
    repeated.set(sec*1000); repeated.event('onExitSleep'); repeated.flush();
    assert.equal(repeated.stats().dew, Math.floor(sec/2)%2===1);
}
assert.equal(repeated.stats().timerStarts,1,'Duplicate wake callbacks do not restart the timer');
repeated.event('onShow');repeated.flush();
assert.equal(repeated.stats().dew,true,'Duplicate show preserves selection');
console.log('PASS duplicate wake/show: former reset weakness reproduced; new source keeps alternating');

const timerOnly = harness();timerOnly.start();timerOnly.advance(12000);
assert.deepEqual(timerOnly.stats().paints.map(p=>p.dew),[false,true,false,true,false,true,false]);
assert.equal(timerOnly.stats().reads,1,'Timer-only rotation uses the cached weather observation');
assert.equal(timerOnly.stats().timerStarts,1);
console.log('PASS timer delivers independent 2s paint requests when natural frames are withheld');

for (const order of ['native-first','timer-first']) {
    const h = harness();h.start();const initial = h.stats();
    for(let sec=1;sec<=12;sec++) {
        h.set(sec*1000);
        if(order==='native-first') {h.frame();h.tick();h.flush();}
        else {h.tick();h.frame();h.flush();} // permits a redundant queued paint
        assert.equal(h.stats().dew,Math.floor(sec/2)%2===1);
    }
    const s = h.stats();
    assert.equal(s.reads,1,'Timer does not increase cached weather reads: '+order);
    assert.equal(s.timerStarts,1);
    assert.equal(s.requests-initial.requests,order==='native-first'?0:6);
    for (let i=1;i<s.paints.length;i++) {
        if(s.paints[i].ms===s.paints[i-1].ms) {
            assert.equal(s.paints[i].dew,s.paints[i-1].dew,'Same-cycle extra paint cannot flip twice');
        }
    }
}
console.log('PASS natural 1Hz in both callback orders: one phase change, no extra data reads; timer-first may request a redundant paint');

for(const stop of ['onEnterSleep','onHide','OFF','LOW']) {
    const h=harness();h.start();h.advance(2000);
    if(stop==='OFF'||stop==='LOW') {h.set(2100,{mode:stop==='OFF'?0:1});h.frame();}
    else {h.event(stop); if(stop==='onEnterSleep')h.set(2100,{mode:1}); h.flush();}
    const before=h.stats();h.set(8000);h.queuedTick();h.flush();const after=h.stats();
    assert.equal(after.running,false,stop);
    assert.equal(after.requests,before.requests,'Queued callback must not request a paint: '+stop);
    assert.equal(after.reads,before.reads,'Queued callback must not read weather: '+stop);
    assert.equal(after.paints.length,before.paints.length,'Queued callback must not render: '+stop);
}
console.log('PASS sleep/hide/OFF/LOW stop scheduling; queued callbacks are inert');

for (const mode of [0,1]) {
    const h=harness();h.start();const before=h.stats();
    h.set(2000,{mode});h.tick();h.flush();const after=h.stats();
    assert.equal(after.running,false,'Timer observes OFF/LOW without a lifecycle/frame callback');
    assert.equal(after.requests,before.requests);
    assert.equal(after.reads,before.reads);
    assert.equal(after.paints.length,before.paints.length);
}
const delayedSleep=harness();delayedSleep.start();delayedSleep.event('onEnterSleep');
// The sleep callback can be stale relative to actual display mode. Rendering
// trusts physical HIGH while scheduler permission remains explicitly denied.
delayedSleep.set(1000,{mode:2});const beforeLateFrame=delayedSleep.stats();delayedSleep.flush();
assert.equal(delayedSleep.stats().paints.length,beforeLateFrame.paints.length+1);
assert.equal(delayedSleep.stats().running,false);
assert.equal(delayedSleep.stats().allowed,false);
assert.equal(delayedSleep.stats().timerStarts,1,'Actual HIGH alone cannot restart denied timer');
console.log('PASS missing sleep callback stops via display mode; stale sleep cannot latch visible frame black');


const eligibility=harness();eligibility.event('onShow');eligibility.flush();
assert.equal(eligibility.stats().timerStarts,0,'Show/high display alone never grants timer permission');
eligibility.set(2000);eligibility.frame();assert.equal(eligibility.stats().dew,true);
assert.equal(eligibility.stats().timerStarts,0,'Normal frames still rotate without timer eligibility');
eligibility.event('onExitSleep');eligibility.flush();assert.equal(eligibility.stats().timerStarts,1);
eligibility.event('onHide');eligibility.event('onShow');eligibility.flush();
assert.equal(eligibility.stats().running,false,'Returning after hide still needs new timer permission');
eligibility.event('onExitSleep');eligibility.flush();assert.equal(eligibility.stats().timerStarts,2);
console.log('PASS timer requires explicit onExitSleep permission and can restart after hide');

const missing=harness();missing.start();missing.advance(2000);
missing.weather(62,null);missing.set(60000);missing.frame();
assert.equal(missing.stats().running,false,'Missing dew stops timer');
const count=missing.stats().requests;missing.queuedTick();assert.equal(missing.stats().requests,count);
missing.weather(null,12);missing.set(120000);missing.frame();assert.equal(missing.stats().running,false);
missing.weather(62,12);missing.set(180000);missing.frame();assert.equal(missing.stats().running,true);
missing.advance(182000);assert.equal(missing.stats().dew,false,'Returning pair gets a full new dwell');
console.log('PASS missing RH/dew stops unnecessary scheduling; returning native pair resumes');

const civil=harness();civil.start();civil.set(2000,{civil:100});civil.frame();
assert.equal(civil.stats().dew,true,'Civil clock rollback does not reset rotation');
civil.set(4000,{civil:900000});civil.frame();assert.equal(civil.stats().dew,false);
const wrap = new MoistureRotation();wrap.update(2147483000,true);wrap.update(-2147483000,true);
assert.equal(wrap.showDew(),false);assert(!wrap.isDue(-2147482000));
wrap.update(-2147481000,true);assert.equal(wrap.showDew(),true);
wrap.pause();wrap.update(-2147480000,true);assert.equal(wrap.showDew(),true);
console.log('PASS monotonic wrap/pause preserve phase and reanchor dwell; civil adjustments are independent');
console.log('Weather rotation host checks passed. Garmin timer delivery and battery impact require watch validation.');
