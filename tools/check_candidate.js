#!/usr/bin/env node
// Host checks execute the candidate's actual helper and drawing source with
// small Monkey C syntax/primitive adapters. This is not a Garmin VM emulator:
// it does not verify firmware delivery, rendering, timing, or battery usage.
const fs = require('fs'), path = require('path'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const source = name => fs.readFileSync(path.join(root, 'source', name + '.mc'), 'utf8');
const isMcNumber = value => typeof value === 'number' && Number.isInteger(value);
const isMcFloat = value => typeof value === 'number';
Number.prototype.toFloat = function () { return Math.fround(+this); };
Number.prototype.toNumber = function () { return Math.trunc(+this); };
Number.prototype.format = function (format) {
    assert.equal(format, '%d', 'Only integer formatting is adapted');
    return String(Math.trunc(+this));
};
function translate(s) {
    return s.replace(/^import .*;$/gm, '')
        .replace(/\bprivate\s+/g, '')
        .replace(/\bas\s+(?:Array<[^>]+>|(?:\w+\.)*\w+)\??/g, '')
        .replace(/\b(\d+(?:\.\d+)?)d\b/g, '$1')
        .replace(/new \[(\w+)\]/g, 'new Array($1)')
        .replace(/\.size\(\)/g, '.length')
        .replace(/:(\w+)\s*=>/g, '$1:')
        .replace(/\[:(\w+)\]/g, '["$1"]')
        .replace(/(\w+(?:\[\d+\])?) instanceof Number/g, 'isMcNumber($1)')
        .replace(/(\w+(?:\[\d+\])?) instanceof Float/g, 'isMcFloat($1)')
        .replace(/(\w+) has :(\w+)/g, '("$2" in $1)');
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
    assert.equal(depth, 0, 'Unclosed source block');
    return s.slice(body, cursor);
}
function moduleFrom(name, names, file=name) {
    return eval('(()=>{' + translate(block(source(file), 'module ' + name + ' ')) +
        ';return {' + names + '};})()');
}
const Pal = moduleFrom('Pal', 'TRACK', 'Fmt');
const Lay = moduleFrom('Lay', 'SPARK_W,HISTORY_SAMPLES', 'SkyRingView');
const Fmt = moduleFrom('Fmt', 'round');
const ChartColors = moduleFrom('ChartColors', 'heartRate,stress,steps,PURPLE,BLUE,GREEN,YELLOW,ORANGE,RED');
const DaySteps = moduleFrom('DaySteps', 'dayNumber,summarize,summarizeWithGoals');
const RecoveryTime = moduleFrom('RecoveryTime', 'validMinutes,display');
function RecoveryReadState() {
    return eval('(()=>{' + translate(block(source('RecoveryTime'), 'class RecoveryReadState ')) +
        ';return {wake,due,accept};})()');
}

// Integer bucket indexing uses Monkey C Number / Number truncation.
function HistoryBuckets(now, min, max) {
    let body = translate(block(source('HistoryBuckets'), 'class HistoryBuckets '));
    assert(body.includes('var index = (when - mStart) / BUCKET_SEC;'));
    body = body.replace('var index = (when - mStart) / BUCKET_SEC;',
        'var index = Math.trunc((when - mStart) / BUCKET_SEC);');
    return eval('(()=>{' + body + ';initialize(now,min,max);return {add,finish};})()');
}
const end = 100000, start = end - 14400;
const stressBuckets = new HistoryBuckets(end, 0, 100);
stressBuckets.add(start,0);
stressBuckets.add(start+599,14);
stressBuckets.add(start+600,25);
stressBuckets.add(end,100);
for(const value of [null,-1,101,NaN,Infinity,-Infinity,'50',{},false]) stressBuckets.add(start+1200,value);
for(const when of [null,NaN,Infinity,'100000',end+1,start-1]) stressBuckets.add(when,50);
assert.deepEqual(stressBuckets.finish(), [7,25,...new Array(21).fill(null),100]);
assert.deepEqual(stressBuckets.finish(), stressBuckets.finish(), 'Finishing must not mutate accumulated data');
const zeroBuckets = new HistoryBuckets(end,0,100);
zeroBuckets.add(end,0);
assert.strictEqual(zeroBuckets.finish()[23],0, 'Measured zero is rest, not missing history');
assert.strictEqual(zeroBuckets.finish()[22],null, 'Missing stress does not become zero');
const hrBuckets = new HistoryBuckets(end,1,254);
hrBuckets.add(end,0);hrBuckets.add(end,-1);hrBuckets.add(end,255);
assert.strictEqual(hrBuckets.finish()[23],null);
hrBuckets.add(end,59);hrBuckets.add(end,60);
assert.strictEqual(hrBuckets.finish()[23],59.5);
console.log('PASS actual history buckets: inclusive endpoints, ten-minute boundaries, averages, zero versus missing, invalid values, repeatable output');

for (const [bpm, color] of [[null,'TRACK'],[0,'TRACK'],[-1,'TRACK'],[59.9,'PURPLE'],
    [60,'BLUE'],[69.9,'BLUE'],[70,'GREEN'],[89.9,'GREEN'],[90,'YELLOW'],
    [109.9,'YELLOW'],[110,'ORANGE'],[129.9,'ORANGE'],[130,'RED'],[190,'RED']]) {
    assert.equal(ChartColors.heartRate(bpm), color === 'TRACK' ? Pal.TRACK : ChartColors[color]);
}
for (const [level, color] of [[null,'TRACK'],[-1,'TRACK'],[0,'PURPLE'],[14,'PURPLE'],
    [14.6,'BLUE'],[15,'BLUE'],[25,'BLUE'],[26,'GREEN'],[50,'GREEN'],[51,'YELLOW'],
    [65,'YELLOW'],[66,'ORANGE'],[75,'ORANGE'],[76,'RED'],[100,'RED'],[101,'TRACK']]) {
    assert.equal(ChartColors.stress(level), color === 'TRACK' ? Pal.TRACK : ChartColors[color]);
}
assert.equal(ChartColors.steps(null, 5000), Pal.TRACK);
assert.equal(ChartColors.steps(-1, 5000), Pal.TRACK);
assert.equal(ChartColors.steps(9000, null), ChartColors.GREEN);
assert.equal(ChartColors.steps(9000, 0), ChartColors.GREEN);
assert.equal(ChartColors.steps(9000, '5000'), ChartColors.GREEN);
assert.equal(ChartColors.steps(5000, 5000), ChartColors.YELLOW);
console.log('PASS fixed HR/stress thresholds, fractional averages, missing data, and goal colors');

const today = DaySteps.dayNumber(2026, 9, 25);
const summary = DaySteps.summarizeWithGoals(today, 6000, 5000, [
    [today-6,9000,8000], [today-4,4000,6000], [today-4,7000,3000],
    [today-3,0,5000], [today-2,7000], [today-2,7000,6000],
    [today-1,4000,3500], [today,9999,9000], [today+1,5000,4000], [today-7,9999,1000]
]);
assert.deepEqual(summary.bars, [9000,null,4000,0,7000,4000,6000]);
assert.deepEqual(summary.goals, [8000,null,6000,5000,null,3500,5000]);
assert.equal(summary.sum, 30000);
assert.equal(summary.count, 6);
assert.equal(summary.complete, false);
assert.equal(ChartColors.steps(summary.bars[4], summary.goals[4]), ChartColors.GREEN,
    'Unknown historical goal must not inherit today or a later duplicate');
assert.equal(DaySteps.summarizeWithGoals(today, null, 5000, [[today,9000,8000]]).sum, null);
assert.equal(DaySteps.summarizeWithGoals(today, 0, null, []).sum, 0);
const tomorrow = DaySteps.summarizeWithGoals(today+1, 0, 6500, [[today,6000,5000]]);
assert.deepEqual(tomorrow.bars.slice(-2), [6000,0]);
assert.deepEqual(tomorrow.goals.slice(-2), [5000,6500]);
assert.equal(DaySteps.dayNumber(2024,3,1)-DaySteps.dayNumber(2024,2,28), 2);
assert.equal(DaySteps.dayNumber(2026,3,9)-DaySteps.dayNumber(2026,3,8), 1);
assert.equal(DaySteps.dayNumber(2026,11,2)-DaySteps.dayNumber(2026,11,1), 1);
assert.equal(DaySteps.dayNumber(2027,1,1)-DaySteps.dayNumber(2026,12,31), 1);
console.log('PASS dated adaptive goals, sparse days, duplicates, today ownership, and midnight/calendar rollover');

for (const invalid of [null,-1,'1',1.5]) assert.equal(RecoveryTime.display(invalid).value, '--');
for (const [minutes, value, unit] of [[0,'0','h'],[1,'1','m'],[59,'59','m'],[60,'1','h'],[61,'2','h']]) {
    assert.equal(RecoveryTime.display(minutes).value, value);
    assert.equal(RecoveryTime.display(minutes).unit, unit);
}
const recovering = new RecoveryReadState();
recovering.wake(100);
assert.equal(recovering.accept(1,100), null);
assert.equal(recovering.accept(1,100), null);
assert.equal(recovering.due(100), false);
assert.equal(recovering.due(101), true);
assert.equal(recovering.accept(1,101), 1, 'A genuine last minute must survive confirmation');
assert.equal(recovering.due(102), false);
assert.equal(recovering.due(103), true);
assert.equal(recovering.accept(0,103), 0);
for (const t of [104,120,160,1000]) assert.equal(recovering.due(t), false);
assert.equal(recovering.due(90), true);
assert.equal(recovering.accept(1,90), null);
assert.equal(recovering.accept(0,91), 0);
recovering.accept(null,93);
assert.equal(recovering.due(94), false);
recovering.wake(200);
assert.equal(recovering.accept(1,200), null);
assert.equal(recovering.accept(1,210), 1);
assert.equal(recovering.due(210), false, 'Late frames must not queue catch-up reads');
console.log('PASS recovery validation, true last-minute retention, bounded rechecks, missing data, and clock rollback');

const view = source('SkyRingView');
function methodText(name) {
    const start = view.indexOf('function ' + name + '(');
    assert(start >= 0, 'Missing method ' + name);
    return translate(view.slice(start, view.indexOf('{', start)+1) +
        block(view, 'function ' + name + '(') + '}');
}
function recorder() {
    let color;
    const calls = [];
    return { calls, dc: {
        setColor(c) { color=c; }, setPenWidth() {},
        drawLine(...args) { calls.push({kind:'line',color,args}); },
        fillCircle(...args) { calls.push({kind:'circle',color,args}); },
        fillRoundedRectangle(...args) { calls.push({kind:'bar',color,args}); }
    }};
}
const Graphics = { COLOR_TRANSPARENT:-1, COLOR_BLACK:0 };
const spark = eval('(' + methodText('drawSpark') + ')');
let capture = recorder();
spark(capture.dc, 100, 20, 45, [55,65,null,135,135], false);
assert.deepEqual(capture.calls.filter(c=>c.kind==='line').map(c=>c.color),
    [ChartColors.PURPLE,ChartColors.BLUE,ChartColors.RED,ChartColors.RED]);
assert.equal(capture.calls.at(-1).color, ChartColors.RED);
assert.equal(capture.calls[0].args[0], 100-Lay.SPARK_W/2);
assert.equal(capture.calls.at(-1).args[0], 100+Lay.SPARK_W/2);
for(const values of [null,[null,null],[null,42,null]]) {
    capture=recorder();spark(capture.dc,100,20,45,values,true);
    assert.equal(capture.calls.length,0, 'Insufficient history must not invent a trace');
}
capture=recorder();spark(capture.dc,100,20,45,[0,20,null,40,60,70,90],true);
assert.deepEqual(capture.calls.filter(c=>c.kind==='line').map(c=>c.color), [
    ChartColors.PURPLE,ChartColors.BLUE,
    ChartColors.GREEN,ChartColors.YELLOW,ChartColors.YELLOW,ChartColors.ORANGE,
    ChartColors.ORANGE,ChartColors.RED]);
assert.equal(capture.calls.at(-1).color,ChartColors.RED);
assert.equal(capture.calls.at(-1).kind,'circle');
capture=recorder();spark(capture.dc,100,20,45,[0,0],true);
assert(capture.calls.length>0 && capture.calls.every(c=>c.color===ChartColors.PURPLE));
assert.equal(capture.calls[0].args[1],32.5, 'Flat valid history remains centered');
for(const [isStress,minSpan] of [[false,12],[true,20]]) {
    capture=recorder();spark(capture.dc,100,20,45,[40,42],isStress);
    const lines=capture.calls.filter(c=>c.kind==='line');
    const firstY=lines[0].args[1],lastY=lines.at(-1).args[3];
    assert(Math.abs(firstY-lastY-2/minSpan*25)<0.00001, 'Minimum vertical span must not exaggerate tiny variations');
}
capture=recorder();spark(capture.dc,100,20,45,[0,100,null],true);
assert.equal(capture.calls.filter(c=>c.kind==='circle').length,0, 'Do not mark old history as the newest sample');
let mBars=summary.bars, mBarGoals=summary.goals;
const bars=eval('(' + methodText('drawBars') + ')');
capture=recorder(); bars(capture.dc,0,30,97);
assert.deepEqual(capture.calls.map(c=>c.color), [ChartColors.YELLOW,Pal.TRACK,
    ChartColors.GREEN,ChartColors.GREEN,ChartColors.GREEN,ChartColors.YELLOW,ChartColors.YELLOW]);
assert.equal(capture.calls[1].kind,'circle');
console.log('PASS actual chart drawing calls: HR/stress half-segment colors, missing gaps, 84px width, minimum vertical spans, and dated goal colors');

// Native history adapters execute the actual bounded collector with controlled
// SensorHistory records. They do not model native sampling frequency or cost.
const ActivityMonitor={INVALID_HR_SAMPLE:255};
function collect(records, stressSeries=true, options={}) {
    const calls={next:0, requests:[]};
    const nativeIterator=options.nullIterator ? null : {
        next() {
            calls.next++;
            if(options.throwNext) throw Error('iterator unavailable');
            return records[calls.next-1] ?? null;
        }
    };
    const SensorHistory={ORDER_NEWEST_FIRST:1,ORDER_OLDEST_FIRST:0};
    const getter=kind=>opts=>{
        calls.requests.push({kind,opts});
        if(options.throwGet) throw Error('history unavailable');
        return nativeIterator;
    };
    if(!options.noStress) SensorHistory.getStressHistory=getter('stress');
    if(!options.noHr) SensorHistory.getHeartRateHistory=getter('hr');
    const Toybox=options.noModule ? {} : {SensorHistory};
    const Time={Duration:function(seconds){this.seconds=seconds;}};
    const buildHistory=eval('(' + methodText('buildHistory') + ')');
    const values=buildHistory({value:()=>end},stressSeries);
    return {values,calls};
}
const sample=(when,data)=>({when:when===null?null:{value:()=>when},data});
const measured=collect([
    sample(end+1,90),sample(end,0),sample(end-1,null),sample(null,30),
    sample(end-600,100),sample(end-601,25),sample(end-1200,15),
    sample(start,0),sample(start-1,50),sample(end,80)
]);
assert.deepEqual(measured.values,[0,...new Array(21).fill(null),20,50]);
assert.equal(measured.calls.requests[0].kind,'stress');
assert.equal(measured.calls.requests[0].opts.order,1,'Read newest history first under the work bound');
assert.equal(measured.calls.requests[0].opts.period.seconds,14400);
assert(measured.calls.next<=10,'Stop after native history leaves the requested window');
const hrMeasured=collect([sample(end,59),sample(end,60),sample(end,0),sample(end,255)],false);
assert.equal(hrMeasured.values[23],59.5);
assert.equal(hrMeasured.calls.requests[0].kind,'hr');
const noStressValue=collect([sample(end,null),sample(end,-1),sample(end,101)]);
assert(noStressValue.values.every(v=>v===null),'Missing native stress must not use the held live reading');
const limited=collect(Array.from({length:Lay.HISTORY_SAMPLES+50},()=>sample(end,60)));
assert.equal(limited.calls.next,Lay.HISTORY_SAMPLES,'Collector must have a hard native iteration bound');
assert.equal(limited.values[23],60);
assert.equal(Lay.HISTORY_SAMPLES,1024);
for(const opts of [{noModule:true},{noStress:true},{nullIterator:true},{throwGet:true},{throwNext:true}]) {
    assert.equal(collect([],true,opts).values,null,'Unavailable native stress stays unavailable');
}
assert.equal(collect([],false,{noHr:true}).values,null);
assert(!/\bmStress\b|readStress|Complications/.test(methodText('buildHistory')));
console.log('PASS actual history collector: native stress/HR routing, newest-first 4h requests, zero preservation, unavailable data, and 1,024-sample hard bound');

// Exercise actual onUpdate/readRecovery/WakeState control flow with a mocked
// native value and drawing surface. The single integer division in onUpdate
// needs explicit truncation, matching Monkey C Number / Number semantics.
const System = { DISPLAY_MODE_OFF:0, DISPLAY_MODE_LOW_POWER:1, DISPLAY_MODE_HIGH_POWER:2,
    getClockTime:()=>({}) };
const WakeState=moduleFrom('WakeState','resolve,needsRefresh');
// Exercise the actual refresh method's paired five-minute cache, without
// repeating real astronomy, sensor, or complication work on the host.
const historyCache=eval(`(()=>{
    var mIs24=false,mAstro=null,mDateStr='',mStatuteTemp=true,mHistoryAt=-1;
    var mHrSpark=null,mStressSpark=null,builds=[];
    var System={UNIT_STATUTE:1,getDeviceSettings:()=>({is24Hour:false,temperatureUnits:1})};
    var Time={FORMAT_MEDIUM:1},Gregorian={info:()=>({day_of_week:'Fri',day:25,month:'Sep'})};
    var Lang={format:()=>''},Astro={compute:()=>({})};
    var location=()=>[0,0],buildStops=()=>{},readStress=()=>{},readActivity=()=>{},readWeather=()=>{},readRecovery=()=>{};
    var buildHistory=(now,stress)=>{builds.push([now.value(),stress]);return [now.value(),stress];};
    ${methodText('refresh')}
    return {at:t=>{refresh({value:()=>t},{timeZoneOffset:0});return {builds:[...builds],hr:mHrSpark,stress:mStressSpark};}};
})()`);
assert.deepEqual(historyCache.at(1000).builds,[[1000,false],[1000,true]]);
assert.equal(historyCache.at(1000).builds.length,2);
assert.equal(historyCache.at(1299).builds.length,2);
assert.deepEqual(historyCache.at(1300).builds.slice(-2),[[1300,false],[1300,true]]);
assert.deepEqual(historyCache.at(1290).builds.slice(-2),[[1290,false],[1290,true]],'Clock rollback must reanchor both histories');
assert.deepEqual(historyCache.at(1600).stress,[1600,true]);
assert.deepEqual(historyCache.at(1601).hr,[1600,false]);
console.log('PASS actual refresh cache: paired series rebuilds, five-minute cadence, and immediate clock-rollback reset');

const updateText=methodText('onUpdate');
assert(updateText.includes('var key = now.value() / 60;'), 'Review changed minute-cache arithmetic');
const integration=eval(`(()=>{
    var t=600, mode=2, native=1, fullReads=0, recoveryReads=0, mRecoveryMin=null;
    var mLastDisplayMode=0, mLastFrameAt=-1, mRefreshKey=-1, mHrHistoryPollAt=-1;
    var mComplicationsDirty=false, mAstro={}, mRecId=1;
    var mRecoveryRead=new RecoveryReadState();
    var Time={now:()=>({value:()=>t})};
    var Complications={getComplication:()=>{ recoveryReads++; if(native==='throw') throw Error('unavailable'); return {value:native}; }};
    var displayMode=()=>mode, readStress=()=>{};
    var drawRing=()=>{}, drawHeader=()=>{}, drawVitals=()=>{}, drawRowA=()=>{}, drawRowB=()=>{}, drawEnv=()=>{};
    ${methodText('readRecovery')}
    var refresh=now=>{ fullReads++; readRecovery(now); };
    ${updateText.replace('var key = now.value() / 60;', 'var key = Math.trunc(now.value() / 60);')}
    return {frame:(at,display,value,dirty=false)=>{
        t=at;mode=display;native=value;mComplicationsDirty=dirty;
        var draws=0;
        onUpdate({setColor(){draws++;},clear(){draws++;},getWidth:()=>454,getHeight:()=>454});
        return {fullReads,recoveryReads,value:mRecoveryMin,draws};
    }};
})()`);
assert.deepEqual(integration.frame(600,2,1),{fullReads:1,recoveryReads:1,value:null,draws:2});
assert.equal(integration.frame(601,2,0).value,0);
assert.equal(integration.frame(602,2,0).recoveryReads,2);
assert.equal(integration.frame(603,2,0).recoveryReads,3);
for(let t=604;t<660;t++) assert.equal(integration.frame(t,2,0).recoveryReads,3);
assert.equal(integration.frame(660,2,0).fullReads,2);
assert.equal(integration.frame(661,1,1,true).recoveryReads,4);
assert.equal(integration.frame(662,0,1,true).draws,0);
assert.equal(integration.frame(663,2,1).value,null);
assert.equal(integration.frame(664,2,null,true).value,null);
assert.equal(integration.frame(665,2,'throw',true).value,null);
assert.equal(integration.frame(666,2,0,true).value,0);
assert.equal(integration.frame(650,2,1).value,null);
assert.equal(integration.frame(651,2,0).value,0);
for(const file of fs.readdirSync(path.join(root,'source')).filter(f=>f.endsWith('.mc'))) {
    const code=fs.readFileSync(path.join(root,'source',file),'utf8').replace(/\/\/[^\n]*|\/\*[\s\S]*?\*\//g,'');
    assert(!/Toybox\.Timer|new\s+(?:Timer\.)?Timer\b/.test(code), 'Unexpected timer in '+file);
}
assert(!/requestUpdate\(/.test(methodText('readRecovery')));
assert(!/requestUpdate\(/.test(methodText('onUpdate')));
assert(/mBarGoals\s*=\s*summary\[:goals\]/.test(view));
assert(/var dayGoal = \(h has :stepGoal\) \? h.stepGoal : null;/.test(view));
console.log('PASS actual awake/update wiring: recovery-only rechecks, minute cache, OFF/LOW early returns, errors, rollback; no timers');
const codeOnly=view.replace(/\/\/[^\n]*|\/\*[\s\S]*?\*\//g,'');
assert(!/\b(drawStatus|drawSegments|buildHrSpark|mBattery|mBat|mElev|mStatuteDist)\b/.test(codeOnly),
    'Removed footer or old gauge code unexpectedly remains');
assert(!/getSystemStats|\.battery\b|\.altitude\b/.test(codeOnly),
    'Removed battery/elevation reads unexpectedly remain');
assert(!/\"WX\"|\"BAT\"|\"ELEV\"/.test(codeOnly),'Removed footer labels unexpectedly remain');
assert(/drawSpark\(dc, cx,[^;]*mStressSpark, true\)/.test(codeOnly),'Stress history must be drawn in the old stress column');
assert(/drawSpark\(dc, colHr,[^;]*mHrSpark, false\)/.test(codeOnly),'HR history must keep its original column');
console.log('PASS removed footer/gauge code and sensor reads; live numbers remain separate from history rendering');
console.log('All candidate host checks passed. Garmin VM/device timing and native data freshness remain unverified here.');
