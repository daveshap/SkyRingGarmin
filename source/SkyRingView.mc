import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

// Layout in pixels relative to the screen centre (454 px display).
module Lay {
    const RING_R = 220;
    const RING_W = 12;
    const CONTENT_R = 211.0; // Inner track edge minus 3px clearance.
    const MARKER_R = 214;    // 12px markers remain inside the 227px display.
    const ICON_MAIN = 26;
    const ICON_SMALL = 20;
    const ICON_ADV = 32;
    const SMALL_ADV = 24;
    const PEAK_ICON_Y = -198;
    const PEAK_Y = -178;
    const DATE_Y = -157;
    const TIME_Y = -82;
    const SOLAR_Y = -50;
    const VIT_Y = 0;
    const VIT_DX = 100;
    const ROWA_Y = 68;
    const ROWB_Y = 106;
    const ENV_Y = 144;
    const STAT_Y = 174;
    const HORIZ_X = 200;
    const HORIZ_ICON_Y = -46;
    const HORIZ_LABEL_Y = -12;
    const RAIN_MIN = 30;        // show rain chance instead of UV from this % up
    const STALE_MIN = 120;      // dim the weather row when data is older than this
    const HOLD_SEC = 1800;      // keep the last good stress reading this long
}

class SkyRingView extends WatchUi.WatchFace {

    // Fonts (loaded in onLayout)
    private var fTime;
    private var fN42;
    private var fN34;
    private var fN28;
    private var fT22;
    private var fL20;
    private var fL18;
    private var fI22;
    private var fI16;

    // Native font metrics, measured once at layout instead of bitmap ascents.
    private var aTime as Number = 0;
    private var aN42 as Number = 0;
    private var aN34 as Number = 0;
    private var aN28 as Number = 0;
    private var aT22 as Number = 0;
    private var aL20 as Number = 0;
    private var aL18 as Number = 0;

    // Mode and cache control
    private var mRefreshKey as Number = -1;
    private var mVisible as Boolean = false;
    private var mSleeping as Boolean = false;
    private var mLastDisplayMode as Number = System.DISPLAY_MODE_OFF;
    private var mLastFrameAt as Number = -1;
    private var mComplicationsDirty as Boolean = true;
    private var mHrHistory = null;
    private var mHrHistoryPollAt as Number = -1;
    private var mHrHistorySampleAt as Number = 0;

    // Sky
    private var mAstro as Dictionary? = null;
    private var mStopPos as Array = [];
    private var mStopCol as Array = [];
    private var mLocApprox as Boolean = true;

    // Settings / device
    private var mIs24 as Boolean = false;
    private var mStatuteTemp as Boolean = true;
    private var mStatuteElev as Boolean = true;
    private var mDateStr as String = "";

    // Metrics
    private var mSteps = null;
    private var mCal = null;
    private var mFloors = null;
    private var mIntWeek = null;
    private var mIntGoal = null;
    private var m7d = null;
    private var m7dComplete as Boolean = false;
    private var mBars = null;
    private var mStress = null;
    private var mStressAt as Number = 0;
    private var mTempC = null;
    private var mHum = null;
    private var mCond = null;
    private var mWxAgeMin = null;
    private var mRainPct = null;
    private var mUv = null;
    private var mHiC = null;
    private var mLoC = null;
    private var mAltM = null;
    private var mBattery = 0.0;
    private var mRecId = null;
    private var mStressId = null;
    private var mRecoveryMin = null;
    private var mHrSpark = null;
    private var mHrSparkAt as Number = 0;

    function initialize() {
        WatchFace.initialize();
        // Recovery time and live stress come from Garmin's own complications.
        if (Toybox has :Complications) {
            try {
                Complications.registerComplicationChangeCallback(method(:onComplicationChanged));
                mRecId = new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME);
                Complications.subscribeToUpdates(mRecId);
                mStressId = new Complications.Id(Complications.COMPLICATION_TYPE_STRESS);
                Complications.subscribeToUpdates(mStressId);
            } catch (e) {
            }
        }
    }

    // Same native font selection as the working RowWatch face. Text never
    // passes through a generated bitmap atlas or its custom antialiasing path.
    private function nativeFont(size as Number) {
        var font = null;
        if (Graphics has :getVectorFont) {
            font = Graphics.getVectorFont({
                :face => ["RobotoCondensedRegular", "RobotoRegular"],
                :size => size
            });
        }
        if (font == null) {
            font = (size <= 16) ? Graphics.FONT_XTINY :
                ((size <= 24) ? Graphics.FONT_TINY : Graphics.FONT_SMALL);
        }
        return font;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        fTime = nativeFont(88);
        fN42 = nativeFont(44);
        fN34 = nativeFont(38);
        fN28 = nativeFont(32);
        fT22 = nativeFont(24);
        fL20 = nativeFont(22);
        fL18 = nativeFont(20);
        aTime = Graphics.getFontAscent(fTime);
        aN42 = Graphics.getFontAscent(fN42);
        aN34 = Graphics.getFontAscent(fN34);
        aN28 = Graphics.getFontAscent(fN28);
        aT22 = Graphics.getFontAscent(fT22);
        aL20 = Graphics.getFontAscent(fL20);
        aL18 = Graphics.getFontAscent(fL18);
        // The working icon artwork stays as the two small bitmap resources.
        fI22 = WatchUi.loadResource(Rez.Fonts.F_icons22);
        fI16 = WatchUi.loadResource(Rez.Fonts.F_icons16);
    }

    function onShow() as Void {
        mVisible = true;
        mSleeping = false;
        mLastFrameAt = -1;
        mRefreshKey = -1;
        mHrHistoryPollAt = -1;
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        mVisible = false;
        mLastDisplayMode = System.DISPLAY_MODE_OFF;
        mLastFrameAt = -1;
    }

    function onEnterSleep() as Void {
        mSleeping = true;
        mLastDisplayMode = System.DISPLAY_MODE_LOW_POWER;
        // Clear the last visible frame; there is deliberately no always-on face.
        if (mVisible) {
            WatchUi.requestUpdate();
        }
    }

    function onExitSleep() as Void {
        mSleeping = false;
        mLastFrameAt = -1;
        mRefreshKey = -1;
        mHrHistoryPollAt = -1;
        // Do not gate this on an old visibility flag either.
        WatchUi.requestUpdate();
    }

    private function displayMode() as Number {
        var mode = (System has :getDisplayMode) ? System.getDisplayMode() : null;
        return WakeState.resolve(mode, mSleeping, mVisible);
    }

    private function isAwake() as Boolean {
        return displayMode() == System.DISPLAY_MODE_HIGH_POWER;
    }

    function onComplicationChanged(id as Complications.Id) as Void {
        // Remember changes even while asleep. Read at the next awake frame;
        // native updates must not perform sensor work or wake the display.
        mComplicationsDirty = true;
        if (isAwake()) {
            WatchUi.requestUpdate();
        }
    }

    // ------------------------------------------------------------------ update

    function onUpdate(dc as Graphics.Dc) as Void {
        var mode = displayMode();
        // Match RowWatch: let Garmin own the physical display. An OFF update
        // does no drawing or data work. HIGH_POWER overrides callback flags.
        if (mode == System.DISPLAY_MODE_OFF) {
            mLastDisplayMode = mode;
            return;
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // There is no always-on renderer: LOW_POWER is completely black.
        if (mode != System.DISPLAY_MODE_HIGH_POWER) {
            mLastDisplayMode = mode;
            return;
        }
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var clock = System.getClockTime();
        var now = Time.now();
        if (WakeState.needsRefresh(mode, mLastDisplayMode, mLastFrameAt, now.value())) {
            mRefreshKey = -1;
            mHrHistoryPollAt = -1;
        }
        mLastDisplayMode = mode;
        mLastFrameAt = now.value();
        // Refresh cached data once per minute while awake, and immediately after waking.
        var key = now.value() / 60;
        if (key != mRefreshKey) {
            refresh(now, clock);
            mRefreshKey = key;
            mComplicationsDirty = false;
        } else if (mComplicationsDirty) {
            readRecovery();
            readStress(now);
            mComplicationsDirty = false;
        }
        if (mAstro == null) {
            return;
        }

        drawRing(dc, cx, cy);
        drawHeader(dc, cx, cy, clock);
        drawVitals(dc, cx, cy);
        drawRowA(dc, cx, cy);
        drawRowB(dc, cx, cy);
        drawEnv(dc, cx, cy);
        drawStatus(dc, cx, cy);
    }

    private function refresh(now as Time.Moment, clock as System.ClockTime) as Void {
        var ds = System.getDeviceSettings();
        mIs24 = ds.is24Hour;

        var loc = location(clock);
        mAstro = Astro.compute(now.value(), loc[0] as Float, loc[1] as Float, clock.timeZoneOffset);
        buildStops();

        var info = Gregorian.info(now, Time.FORMAT_MEDIUM);
        mDateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.day, info.month]);

        readStress(now);
        mStatuteTemp = ds.temperatureUnits == System.UNIT_STATUTE;
        mStatuteElev = ds.elevationUnits == System.UNIT_STATUTE;

        readActivity();
        readWeather(now);
        readElevation();
        readRecovery();
        mBattery = System.getSystemStats().battery;
        if (mHrSpark == null || now.value() - mHrSparkAt >= 300) {
            mHrSpark = buildHrSpark(now);
            mHrSparkAt = now.value();
        }
    }

    // ------------------------------------------------------------------ data

    // [lat, lon] in degrees. Order: weather station, recent GPS, cached, time-zone estimate.
    private function location(clock as System.ClockTime) as Array {
        mLocApprox = false;
        var deg = null;
        if (Toybox has :Weather) {
            var cc = Weather.getCurrentConditions();
            if (cc != null) {
                var p = cc.observationLocationPosition;
                if (p != null) {
                    deg = p.toDegrees();
                }
            }
        }
        if (!validDeg(deg)) {
            var ai = Activity.getActivityInfo();
            if (ai != null) {
                var p2 = ai.currentLocation;
                if (p2 != null) {
                    deg = p2.toDegrees();
                }
            }
        }
        if (validDeg(deg)) {
            var la2 = deg[0].toFloat();
            var lo2 = deg[1].toFloat();
            var saved = Application.Storage.getValue("loc");
            // Only write when it moved, to avoid a flash write every minute.
            if (!(saved instanceof Array) || saved.size() != 2
                    || (saved[0] - la2).abs() > 0.1 || (saved[1] - lo2).abs() > 0.1) {
                Application.Storage.setValue("loc", [la2, lo2]);
            }
            return [la2, lo2];
        }
        var saved2 = Application.Storage.getValue("loc");
        if (validDeg(saved2)) {
            var cached = saved2 as Array;
            return [cached[0].toFloat(), cached[1].toFloat()];
        }
        // Last resort: longitude from the standard-time offset (1 degree per 4 minutes).
        mLocApprox = true;
        // Latitude-dependent graphics are suppressed until a real location exists.
        return [0.0, ((clock.timeZoneOffset - clock.dst) / 240).toFloat()];
    }

    private function validDeg(deg) as Boolean {
        if (!(deg instanceof Array) || deg.size() < 2 || deg[0] == null || deg[1] == null) {
            return false;
        }
        if (!((deg[0] instanceof Number) || (deg[0] instanceof Float) || (deg[0] instanceof Double))
                || !((deg[1] instanceof Number) || (deg[1] instanceof Float) || (deg[1] instanceof Double))) {
            return false;
        }
        var la = deg[0].toFloat();
        var lo = deg[1].toFloat();
        // Some firmware reports 180/180 or 0/0 when it has no fix.
        return la.abs() < 89.9 && lo.abs() < 179.9 && !(la == 0.0 && lo == 0.0);
    }

    // Preserve the observation timestamp: rereading an old sample must not
    // repeatedly renew its freshness. Missing/moving samples are skipped.
    private function firstValid(it, now as Time.Moment) as Array? {
        if (it == null) {
            return null;
        }
        while (true) {
            var s = it.next();
            if (s == null) {
                return null;
            }
            if (s.when == null) { continue; }
            var age = now.value() - s.when.value();
            if (age > Lay.HOLD_SEC) { return null; }
            if (age >= 0 && s.data != null && s.data >= 0 && s.data <= 100) {
                return [s.data, s.when.value()];
            }
        }
        return null;
    }

    // Live stress from Garmin's complication, else the newest valid history sample.
    // The last good value is held for 30 minutes instead of flashing "--"
    // (Garmin can't measure stress while you're moving).
    private function readStress(now as Time.Moment) as Void {
        var v = null;
        var observedAt = now.value();
        if (mStressId != null) {
            try {
                v = Complications.getComplication(mStressId).value;
            } catch (e) {
                v = null;
            }
        }
        if (v != null && (v.toNumber() < 0 || v.toNumber() > 100)) {
            v = null;
        }
        if (v == null && (Toybox has :SensorHistory) && (SensorHistory has :getStressHistory)) {
            var sample = firstValid(SensorHistory.getStressHistory({
                :period => new Time.Duration(Lay.HOLD_SEC),
                :order => SensorHistory.ORDER_NEWEST_FIRST
            }), now);
            if (sample != null) {
                var pair = sample as Array;
                v = pair[0];
                observedAt = pair[1];
            }
        }
        if (v != null) {
            mStress = v;
            mStressAt = observedAt;
        } else if (now.value() - mStressAt > Lay.HOLD_SEC) {
            mStress = null;
        }
    }

    private function readActivity() as Void {
        var am = ActivityMonitor.getInfo();
        mSteps = (am has :steps) ? am.steps : null;
        mCal = (am has :calories) ? am.calories : null;
        mFloors = (am has :floorsClimbed) ? am.floorsClimbed : null;
        mIntGoal = (am has :activeMinutesWeekGoal) ? am.activeMinutesWeekGoal : null;
        mIntWeek = null;
        if (am has :activeMinutesWeek) {
            var amw = am.activeMinutesWeek;
            if (amw != null) {
                mIntWeek = amw.total;
            }
        }

        // Today + the preceding SIX local dates. History can be sparse and
        // contains dated records, so record position is not a calendar day.
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var today = DaySteps.dayNumber(date.year, date.month, date.day);
        var records = [];
        var hist = ActivityMonitor.getHistory();
        if (hist != null) {
            for (var i = 0; i < hist.size(); i++) {
                var h = hist[i];
                if (h != null && h.startOfDay != null && h.steps != null) {
                    var hd = Gregorian.info(h.startOfDay, Time.FORMAT_SHORT);
                    records.add([DaySteps.dayNumber(hd.year, hd.month, hd.day), h.steps]);
                }
            }
        }
        var summary = DaySteps.summarize(today, mSteps, records);
        mBars = summary[:bars];
        m7d = summary[:sum];
        m7dComplete = summary[:complete];
    }

    private function readWeather(now as Time.Moment) as Void {
        mTempC = null;
        mHum = null;
        mCond = null;
        mWxAgeMin = null;
        mRainPct = null;
        mUv = null;
        mHiC = null;
        mLoC = null;
        if (!(Toybox has :Weather)) {
            return;
        }
        var cc = Weather.getCurrentConditions();
        if (cc == null) {
            return;
        }
        mTempC = cc.temperature;
        mHum = cc.relativeHumidity;
        mCond = cc.condition;
        mRainPct = cc.precipitationChance;
        mHiC = cc.highTemperature;
        mLoC = cc.lowTemperature;
        if (cc has :uvIndex) {
            mUv = cc.uvIndex;
        }
        var obs = cc.observationTime;
        if (obs != null) {
            var age = now.compare(obs) / 60;
            mWxAgeMin = (age < 0) ? 0 : age;
        }
    }

    private function readElevation() as Void {
        mAltM = null;
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.altitude != null) {
            mAltM = ai.altitude;
            return;
        }
        if ((Toybox has :SensorHistory) && (SensorHistory has :getElevationHistory)) {
            var it = SensorHistory.getElevationHistory({ :period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST });
            var s = it.next();
            if (s != null) {
                mAltM = s.data;
            }
        }
    }

    private function readRecovery() as Void {
        mRecoveryMin = null;
        if (mRecId == null) {
            return;
        }
        try {
            var c = Complications.getComplication(mRecId);
            if (c != null) {
                var v = c.value;
                mRecoveryMin = (v != null && v >= 0) ? v : null;
            }
        } catch (e) {
            mRecoveryMin = null;
        }
    }

    private function currentHr() {
        if (!isAwake()) {
            return null;
        }
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentHeartRate != null
                && ai.currentHeartRate > 0 && ai.currentHeartRate < ActivityMonitor.INVALID_HR_SAMPLE) {
            return ai.currentHeartRate;
        }

        // Limit fallback age and avoid rescanning history on every one-second redraw.
        var now = Time.now().value();
        if (mHrHistoryPollAt < 0 || now < mHrHistoryPollAt || now - mHrHistoryPollAt >= 30) {
            mHrHistoryPollAt = now;
            mHrHistory = null;
            mHrHistorySampleAt = 0;
            var it = ActivityMonitor.getHeartRateHistory(new Time.Duration(300), true);
            for (var i = 0; i < 32; i++) {
                var s = it.next();
                if (s == null) {
                    break;
                }
                var age = now - s.when.value();
                if (age > 300) {
                    break;
                }
                if (age >= 0 && s.heartRate > 0 && s.heartRate < ActivityMonitor.INVALID_HR_SAMPLE) {
                    mHrHistory = s.heartRate;
                    mHrHistorySampleAt = s.when.value();
                    break;
                }
            }
        }
        if (mHrHistory != null && now >= mHrHistorySampleAt && now - mHrHistorySampleAt <= 300) {
            return mHrHistory;
        }
        return null;
    }

    // Last 4 hours of heart rate, averaged into 24 ten-minute buckets (null = no data).
    private function buildHrSpark(now as Time.Moment) {
        if (!(Toybox has :SensorHistory) || !(SensorHistory has :getHeartRateHistory)) {
            return null;
        }
        var span = 4 * 3600;
        var n = 24;
        var bucket = span / n;
        var start = now.value() - span;
        var sums = new [n];
        var cnts = new [n];
        for (var i = 0; i < n; i++) {
            sums[i] = 0;
            cnts[i] = 0;
        }
        var it = SensorHistory.getHeartRateHistory({
            :period => new Time.Duration(span),
            :order => SensorHistory.ORDER_OLDEST_FIRST
        });
        var s = it.next();
        while (s != null) {
            var w = s.when;
            if (s.data != null && w != null) {
                var idx = (w.value() - start) / bucket;
                if (idx >= 0 && idx < n) {
                    sums[idx] += s.data;
                    cnts[idx] += 1;
                }
            }
            s = it.next();
        }
        var out = new [n];
        for (var j = 0; j < n; j++) {
            out[j] = (cnts[j] > 0) ? sums[j].toFloat() / cnts[j] : null;
        }
        return out;
    }

    // ------------------------------------------------------------------ helpers

    private function tw(dc as Graphics.Dc, s as String, font) as Number {
        return dc.getTextWidthInPixels(s, font);
    }

    // Text with its baseline at `base`.
    private function text(dc as Graphics.Dc, x as Numeric, base as Numeric, font, asc as Number, color as Number, s as String) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, base - asc, font, s, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function textR(dc as Graphics.Dc, x as Numeric, base as Numeric, font, asc as Number, color as Number, s as String) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, base - asc, font, s, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // Icon glyph with its top-left corner at (x, top).
    private function glyph(dc as Graphics.Dc, x as Numeric, top as Numeric, font, ch as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, top, font, ch, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Same geometry as the original horizon icons, with independent colours.
    // The icon colours stay fixed after the event; only ring ticks can fade.
    private function drawHorizonIcon(dc as Graphics.Dc, x as Numeric, top as Numeric, rising as Boolean) as Void {
        glyph(dc, x, top, fI16, rising ? "a" : "z", rising ? Pal.RISE_ICON : Pal.SET_ICON);
        glyph(dc, x, top, fI16, "o", Pal.SUN);
    }

    private function polar(cx as Numeric, cy as Numeric, r as Numeric, theta as Float) as Array {
        var t = theta * 0.0174532925;
        return [cx + r * Math.sin(t), cy - r * Math.cos(t)];
    }

    // Clockwise-from-top degrees -> Garmin arc degrees (counter-clockwise from 3 o'clock), 0..359.
    // Integers on purpose: drawArc truncates its angles, and equal start/end draws a full circle.
    private function gAng(theta as Number) as Number {
        var a = (90 - theta) % 360;
        if (a < 0) {
            a += 360;
        }
        return a;
    }

    // ------------------------------------------------------------------ sky ring

    private function buildStops() as Void {
        var a = mAstro as Dictionary;
        var hg = a[:hGold] as Float;
        var ha = a[:hAstro] as Float;
        mStopPos = [0.0, hg * 0.68, hg, a[:hRise], a[:hCivil], a[:hNaut], ha, ha + (180.0 - ha) * 0.4, 180.0];
        mStopCol = [0xFFE7AE, 0xFFD27A, 0xFFB55A, 0xFF8A45, 0xD0628C, 0x6A4FB8, 0x2E2F74, 0x1A1B45, 0x141536];
    }

    // Colour of the sky at |hour angle| t: pale noon gold -> golden hour -> sunset orange
    // -> civil rose -> nautical violet -> astronomical indigo -> night.
    private function ringColor(t as Float) as Number {
        for (var i = 0; i < 8; i++) {
            var p0 = mStopPos[i] as Float;
            var p1 = mStopPos[i + 1] as Float;
            if (t <= p1) {
                if (p1 - p0 < 0.001) {
                    return mStopCol[i + 1] as Number;
                }
                var f = (t - p0) / (p1 - p0);
                if (f < 0.0) {
                    f = 0.0;
                }
                return Pal.lerp(mStopCol[i] as Number, mStopCol[i + 1] as Number, f);
            }
        }
        return mStopCol[8] as Number;
    }

    private function slice(dc as Graphics.Dc, cx as Number, cy as Number, t1 as Number, t2 as Number, elapsed as Boolean) as Void {
        if (t2 <= t1) {
            return;
        }
        var c = ringColor(((t1 + t2) / 2.0).abs());
        if (elapsed) {
            c = Pal.scale(c, 0.32);   // the part of today already gone
        }
        // Start 1 degree early so neighbouring slices overlap and no seams show.
        var s = gAng(t1 - 1);
        var e = gAng(t2);
        if (s == e) {
            return;                   // equal angles would draw a full circle
        }
        dc.setColor(c, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, Lay.RING_R, Graphics.ARC_CLOCKWISE, s, e);
    }

    private function tick(dc as Graphics.Dc, cx as Number, cy as Number, theta as Float, color as Number) as Void {
        var p1 = polar(cx, cy, Lay.RING_R - Lay.RING_W / 2 - 9, theta);
        var p2 = polar(cx, cy, Lay.RING_R - Lay.RING_W / 2 - 2, theta);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
    }

    private function drawRing(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        if (mLocApprox) {
            // A time zone cannot determine sunrise, sunset, or sun elevation.
            dc.setColor(Pal.TRACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(Lay.RING_W);
            dc.drawCircle(cx, cy, Lay.RING_R);
            var unavailable = "LOCATION --";
            text(dc, cx - tw(dc, unavailable, fL18) / 2, cy + Lay.PEAK_Y,
                fL18, aL18, Pal.DIMMER, unavailable);
            return;
        }
        var a = mAstro as Dictionary;
        var sunH = a[:sunH] as Float;
        var hRise = a[:hRise] as Float;
        var sunUp = a[:sunUp] as Boolean;
        var sp = polar(cx, cy, Lay.MARKER_R, sunH);

        // Ring: finer slices through the twilight bands, coarser elsewhere.
        dc.setPenWidth(Lay.RING_W);
        var zoneLo = (a[:hGold] as Float) - 4.0;
        var zoneHi = (a[:hAstro] as Float) + 4.0;
        var sunI = Fmt.round(sunH);
        var t = -180;
        while (t < 180) {
            var at = t.abs();
            var at2 = (t + 6).abs();
            var inZone = (at >= zoneLo && at <= zoneHi) || (at2 >= zoneLo && at2 <= zoneHi);
            var t2 = t + (inZone ? 3 : 6);
            if (t2 > 180) {
                t2 = 180;
            }
            if (t < sunI && t2 > sunI) {
                slice(dc, cx, cy, t, sunI, true);
                slice(dc, cx, cy, sunI, t2, false);
            } else {
                slice(dc, cx, cy, t, t2, t2 <= sunI);
            }
            t = t2;
        }

        // Ticks: solar noon, sunrise, sunset, with their labels.
        dc.setPenWidth(2);
        tick(dc, cx, cy, 0.0, Pal.TICK);
        var riseMin = a[:riseMin] as Number;
        if (riseMin >= 0) {
            var riseTick = (sunH > -hRise) ? Pal.TICK : Pal.RISE_ICON;
            var setTick = (sunH > hRise) ? Pal.TICK : Pal.SET_ICON;
            tick(dc, cx, cy, -hRise, riseTick);
            tick(dc, cx, cy, hRise, setTick);

            drawHorizonIcon(dc, cx - Lay.HORIZ_X, cy + Lay.HORIZ_ICON_Y, true);
            text(dc, cx - Lay.HORIZ_X, cy + Lay.HORIZ_LABEL_Y, fL20, aL20, Pal.DIM, Fmt.clock(riseMin, mIs24));
            drawHorizonIcon(dc, cx + Lay.HORIZ_X - Lay.ICON_SMALL, cy + Lay.HORIZ_ICON_Y, false);
            textR(dc, cx + Lay.HORIZ_X, cy + Lay.HORIZ_LABEL_Y, fL20, aL20, Pal.DIM, Fmt.clock(a[:setMin] as Number, mIs24));
        }

        // Today's peak sun elevation, at the solar-noon mark.
        var pStr = Fmt.round(a[:peak] as Float).format("%d") + "°";
        var px0 = cx - (Lay.SMALL_ADV + tw(dc, pStr, fL18)) / 2;
        glyph(dc, px0, cy + Lay.PEAK_ICON_Y, fI16, "P", Pal.PEAK_ICON);
        text(dc, px0 + Lay.SMALL_ADV, cy + Lay.PEAK_Y, fL18, aL18, Pal.PEAK_TEXT, pStr);

        // Hour-angle positions: upper meridian at the top, not compass bearings.
        var mp = polar(cx, cy, Lay.MARKER_R, a[:moonH] as Float);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(mp[0], mp[1], 12);
        var moonUp = a[:moonUp] as Boolean; // Current upper-limb horizon test; independent of the solar ring.
        var moonLit = moonUp ? Pal.MOON_LIT : Pal.scale(Pal.MOON_LIT, 0.6);
        drawMoon(dc, mp[0], mp[1], 10, a[:illum] as Float, a[:waxing] as Boolean, a[:south] as Boolean,
            moonLit, Pal.MOON_DARK);
        // A rim identifies the moon even near new moon; illumination stays phase-accurate.
        dc.setPenWidth(1);
        dc.setColor(Pal.scale(moonLit, 0.65), Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(mp[0], mp[1], 10.5);

        // Rays distinguish the sun from a full moon. It stays visible below the horizon.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sp[0], sp[1], 12);
        dc.setColor(sunUp ? Pal.SUN : Pal.scale(Pal.SUN, 0.5), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(sp[0], sp[1], 6);
        dc.setPenWidth(1.5);
        for (var ray = 0; ray < 8; ray++) {
            var p1 = polar(sp[0], sp[1], 8, (ray * 45).toFloat());
            var p2 = polar(sp[0], sp[1], 11, (ray * 45).toFloat());
            dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        }
    }

    // Phase-accurate moon disc. Waxing is lit on the right in the northern hemisphere.
    private function drawMoon(dc as Graphics.Dc, xf as Numeric, yf as Numeric, r as Number, k as Float,
            waxing as Boolean, south as Boolean, lit as Number, dark as Number) as Void {
        var x = Fmt.round(xf);
        var y = Fmt.round(yf);
        dc.setColor(dark, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);

        var litRight = (waxing != south);
        dc.setColor(lit, Graphics.COLOR_TRANSPARENT);
        if (litRight) {
            dc.setClip(x, y - r - 1, r + 2, 2 * r + 3);
        } else {
            dc.setClip(x - r - 1, y - r - 1, r + 1, 2 * r + 3);
        }
        dc.fillCircle(x, y, r);
        dc.clearClip();

        // Terminator: a lit ellipse when gibbous, a dark one when crescent.
        var e = 2.0 * k - 1.0;
        var rx = Fmt.round(e.abs() * r);
        if (rx > 0) {
            dc.setColor(e > 0.0 ? lit : dark, Graphics.COLOR_TRANSPARENT);
            dc.fillEllipse(x, y, rx, r);
        }
    }

    // ------------------------------------------------------------------ header

    private function timeParts(clock as System.ClockTime) as Array<String> {
        var h = clock.hour;
        if (mIs24) {
            return [h.format("%02d") + ":" + clock.min.format("%02d"), ""];
        }
        var suffix = (h >= 12) ? "pm" : "am";
        h = h % 12;
        if (h == 0) {
            h = 12;
        }
        return [h.format("%d") + ":" + clock.min.format("%02d"), suffix];
    }

    private function drawHeader(dc as Graphics.Dc, cx as Number, cy as Number, clock as System.ClockTime) as Void {
        var a = mAstro as Dictionary;

        // Date
        var wd = tw(dc, mDateStr, fT22);
        text(dc, cx - wd / 2, cy + Lay.DATE_Y, fT22, aT22, Pal.DIM, mDateStr);

        // Time
        var tp = timeParts(clock);
        var wT = tw(dc, tp[0], fTime);
        var wS = (tp[1].length() > 0) ? tw(dc, tp[1], fT22) + 5 : 0;
        var x = cx - (wT + wS) / 2;
        text(dc, x, cy + Lay.TIME_Y, fTime, aTime, Pal.INK, tp[0]);
        if (wS > 0) {
            text(dc, x + wT + 5, cy + Lay.TIME_Y, fT22, aT22, Pal.DIM, tp[1]);
        }

        // Solar time | sun elevation now | time to the next sunrise or sunset
        var solarMin = a[:trueMin] as Number;
        var solarStr = (mLocApprox ? "~" : "") + Fmt.clock(solarMin, true);
        if (mLocApprox) {
            var estimate = solarStr + "  location needed";
            text(dc, cx - tw(dc, estimate, fT22) / 2, cy + Lay.SOLAR_Y,
                fT22, aT22, Pal.DIM, estimate);
            return;
        }
        var altStr = Fmt.round(a[:alt] as Float).format("%d") + "°";
        var hRise = a[:hRise] as Float;
        var dl;
        if (hRise >= 180.0) {
            dl = "sun up all day";
        } else if (hRise <= 0.0) {
            dl = "sun down all day";
        } else if (a[:sunUp] as Boolean) {
            dl = Fmt.duration(a[:nextMin] as Number) + " to sunset";
        } else {
            dl = Fmt.duration(a[:nextMin] as Number) + " to sunrise";
        }
        var ws = tw(dc, solarStr, fT22);
        var wa = tw(dc, altStr, fL20);
        var detailFont = fL20;
        var detailAsc = aL20;
        var wdl = tw(dc, dl, detailFont);
        // Fit the entire text row within the inner edge of the sky ring.
        // Tighten spacing before using the smaller countdown font.
        var edgeY = (Lay.SOLAR_Y - aT22).abs().toFloat();
        var available = (2.0 * Math.sqrt(Lay.CONTENT_R * Lay.CONTENT_R - edgeY * edgeY)).toNumber() - 16;
        var gap = 10;
        var fixedWidth = Lay.SMALL_ADV + ws + Lay.SMALL_ADV + wa + wdl;
        if (fixedWidth + 2 * gap > available) {
            gap = 4;
        }
        if (fixedWidth + 2 * gap > available) {
            detailFont = fL18;
            detailAsc = aL18;
            wdl = tw(dc, dl, detailFont);
        }
        var sx = cx - (Lay.SMALL_ADV + ws + gap + Lay.SMALL_ADV + wa + gap + wdl) / 2;
        var base = cy + Lay.SOLAR_Y;
        glyph(dc, sx, base - Lay.ICON_SMALL, fI16, "U", Pal.GOLD);
        text(dc, sx + Lay.SMALL_ADV, base, fT22, aT22, Pal.GOLD, solarStr);
        sx += Lay.SMALL_ADV + ws + gap;
        glyph(dc, sx, base - Lay.ICON_SMALL, fI16, "L", Pal.ALT_ICON);
        text(dc, sx + Lay.SMALL_ADV, base, fL20, aL20, Pal.ALT_TEXT, altStr);
        sx += Lay.SMALL_ADV + wa + gap;
        text(dc, sx, base, detailFont, detailAsc, Pal.DIM, dl);
    }

    // ------------------------------------------------------------------ vitals

    private function drawVitals(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        var base = cy + Lay.VIT_Y;

        // Heart rate + 4 h trace
        var hr = currentHr();
        var colHr = cx - Lay.VIT_DX;
        vital(dc, colHr, base, "H", (hr != null) ? Fmt.round(hr).format("%d") : "--", null);
        drawSpark(dc, colHr, base + 13, base + 30);

        // Stress (live) + 10 segments
        vital(dc, cx, base, "X", (mStress != null) ? Fmt.round(mStress).format("%d") : "--", null);
        drawSegments(dc, cx, base + 18, mStress);

        // Native recovery replaces the unsupported external-HRV field.
        var colV = cx + Lay.VIT_DX;
        var recovery = RecoveryTime.display(mRecoveryMin);
        vital(dc, colV, base, "R", recovery[:value] as String, recovery[:unit]);
        var label = recovery[:label] as String;
        text(dc, colV - tw(dc, label, fL18) / 2, base + 33, fL18, aL18, Pal.DIM, label);
    }

    private function vital(dc as Graphics.Dc, colX as Number, base as Number, ic as String, val as String, unit) as Void {
        var font = fN42;
        var asc = aN42;
        var wv = tw(dc, val, font);
        var wu = (unit != null) ? tw(dc, unit as String, fL18) + 3 : 0;
        // Leave room for sunrise/set labels beside the outer vital columns.
        if (Lay.ICON_ADV + wv + wu > 96) {
            font = fN34;
            asc = aN34;
            wv = tw(dc, val, font);
        }
        if (Lay.ICON_ADV + wv + wu > 96) {
            font = fN28;
            asc = aN28;
            wv = tw(dc, val, font);
        }
        var x = colX - (Lay.ICON_ADV + wv + wu) / 2;
        glyph(dc, x, base - Lay.ICON_MAIN, fI22, ic, Pal.CORAL);
        text(dc, x + Lay.ICON_ADV, base, font, asc, Pal.INK, val);
        if (unit != null) {
            text(dc, x + Lay.ICON_ADV + wv + 3, base, fL18, aL18, Pal.DIMMER, unit as String);
        }
    }

    private function drawSpark(dc as Graphics.Dc, colX as Number, yTop as Number, yBot as Number) as Void {
        if (mHrSpark == null) {
            return;
        }
        var s = mHrSpark as Array;
        var n = s.size();
        var lo = 999.0;
        var hi = 0.0;
        var cnt = 0;
        for (var i = 0; i < n; i++) {
            if (s[i] != null) {
                var v = s[i] as Float;
                if (v < lo) { lo = v; }
                if (v > hi) { hi = v; }
                cnt += 1;
            }
        }
        if (cnt < 2) {
            return;
        }
        if (hi - lo < 12.0) {
            var mid = (hi + lo) / 2.0;
            lo = mid - 6.0;
            hi = mid + 6.0;
        }
        var x0 = colX - 38.0;
        var dx = 76.0 / (n - 1);
        var hgt = (yBot - yTop).toFloat();
        dc.setPenWidth(2);
        dc.setColor(Pal.CORAL, Graphics.COLOR_TRANSPARENT);
        var px = 0.0;
        var py = 0.0;
        var started = false;
        for (var j = 0; j < n; j++) {
            if (s[j] != null) {
                var x = x0 + j * dx;
                var y = yBot - ((s[j] as Float) - lo) / (hi - lo) * hgt;
                if (started) {
                    dc.drawLine(px, py, x, y);
                }
                px = x;
                py = y;
                started = true;
            } else {
                started = false; // Missing samples are gaps, not an invented connecting trace.
            }
        }
        if (started) {
            dc.fillCircle(px, py, 2.5);
        }
    }

    private function drawSegments(dc as Graphics.Dc, colX as Number, y as Number, val) as Void {
        var w = 7.0;
        var g = 2.0;
        var x0 = colX - (10 * w + 9 * g) / 2.0;
        var filled = (val != null) ? val.toFloat() / 10.0 : 0.0;
        for (var i = 0; i < 10; i++) {
            var x = x0 + i * (w + g);
            dc.setColor(Pal.TRACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, 7, 1.5);
            var f = filled - i;
            if (f > 0.0) {
                if (f > 1.0) {
                    f = 1.0;
                }
                var fw = w * f;
                if (fw < 2.0) {
                    fw = 2.0;
                }
                dc.setColor(Pal.CORAL, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(x, y, fw, 7, 1.5);
            }
        }
    }

    // ------------------------------------------------------------------ movement

    // Steps today | 7 daily bars (oldest -> today) | 7-day total
    private function drawRowA(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        var base = cy + Lay.ROWA_Y;
        var sStr = (mSteps != null) ? Fmt.thousands(mSteps as Number) : "--";
        var wStr = (m7d != null) ? Fmt.thousands(m7d as Number) : "--";
        var ws = tw(dc, sStr, fN34);
        var w7 = tw(dc, wStr, fN28);
        var weekLabel = m7dComplete ? "7d" : "7d*";
        var wu = tw(dc, weekLabel, fL18);
        var barsW = 97;
        var gap = 14;
        var edgeY = (Lay.ROWA_Y + 2).toFloat();
        var available = (2.0 * Math.sqrt(Lay.CONTENT_R * Lay.CONTENT_R - edgeY * edgeY)).toNumber() - 16;
        var core = Lay.ICON_ADV + ws + w7 + 3 + wu;
        if (core + 2 * gap + barsW > available) {
            gap = 6;
            barsW = available - core - 2 * gap;
            if (barsW > 97) { barsW = 97; }
        }
        var showBars = barsW >= 35;
        var middle = showBars ? 2 * gap + barsW : 18;
        var x = cx - (core + middle) / 2;

        glyph(dc, x, base - Lay.ICON_MAIN, fI22, "S", Pal.MINT);
        x += Lay.ICON_ADV;
        text(dc, x, base, fN34, aN34, Pal.INK, sStr);
        x += ws;
        if (showBars) {
            x += gap;
            drawBars(dc, x, base, barsW);
            x += barsW + gap;
        } else {
            x += middle;
        }
        text(dc, x, base, fN28, aN28, Pal.INK, wStr);
        text(dc, x + w7 + 3, base, fL18, aL18, Pal.DIMMER, weekLabel);
    }

    private function drawBars(dc as Graphics.Dc, x0 as Number, base as Number, width as Number) as Void {
        if (mBars == null) {
            return;
        }
        var b = mBars as Array;
        var mx = 1;
        for (var i = 0; i < 7; i++) {
            if (b[i] != null && (b[i] as Number) > mx) {
                mx = b[i] as Number;
            }
        }
        var past = Pal.scale(Pal.MINT, 0.42);
        var barWidth = (width - 6 * 3.0) / 7.0;
        var stride = barWidth + 3.0;
        for (var j = 0; j < 7; j++) {
            if (b[j] == null) {
                // An absent day is a grey dot, not a zero-step green bar.
                dc.setColor(Pal.TRACK, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x0 + j * stride + barWidth / 2.0, base - 1, 1);
                continue;
            }
            var h = (b[j] as Number) * 30.0 / mx;
            if (h < 2.0) {
                h = 2.0;
            }
            dc.setColor((j == 6) ? Pal.MINT : past, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x0 + j * stride, base - h, barWidth, h, 1.5);
        }
    }

    // Weekly intensity minutes (bar = progress to goal) | calories | floors
    private function drawRowB(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        var base = cy + Lay.ROWB_Y;
        var iStr = (mIntWeek != null) ? Fmt.thousands(mIntWeek as Number) : "--";
        var gStr = (mIntGoal != null) ? "/" + (mIntGoal as Number).format("%d") : "";
        var kStr = (mCal != null) ? Fmt.thousands(mCal as Number) : "--";
        var fStr = (mFloors != null) ? (mFloors as Number).format("%d") : "--";
        var valueFont = fN28;
        var valueAsc = aN28;
        var wiv = tw(dc, iStr, valueFont);
        var wi = Lay.ICON_ADV + wiv + ((gStr.length() > 0) ? tw(dc, gStr, fL18) + 1 : 0);
        var wk = Lay.ICON_ADV + tw(dc, kStr, valueFont);
        var wf = Lay.ICON_ADV + tw(dc, fStr, valueFont);
        var gap = 26;
        // Include the goal line below the baseline in the circle-fit bound.
        var edgeY = (Lay.ROWB_Y + 11).toFloat();
        var available = (2.0 * Math.sqrt(Lay.CONTENT_R * Lay.CONTENT_R - edgeY * edgeY)).toNumber() - 16;
        if (wi + wk + wf + 2 * gap > available) {
            gap = (available - wi - wk - wf) / 2;
            if (gap < 8) { gap = 8; }
        }
        if (wi + wk + wf + 2 * gap > available) {
            valueFont = fT22;
            valueAsc = aT22;
            wiv = tw(dc, iStr, valueFont);
            wi = Lay.ICON_ADV + wiv + ((gStr.length() > 0) ? tw(dc, gStr, fL18) + 1 : 0);
            wk = Lay.ICON_ADV + tw(dc, kStr, valueFont);
            wf = Lay.ICON_ADV + tw(dc, fStr, valueFont);
        }
        var x = cx - (wi + gap + wk + gap + wf) / 2;

        glyph(dc, x, base - Lay.ICON_MAIN, fI22, "I", Pal.MINT);
        text(dc, x + Lay.ICON_ADV, base, valueFont, valueAsc, Pal.INK, iStr);
        if (gStr.length() > 0) {
            text(dc, x + Lay.ICON_ADV + wiv + 1, base, fL18, aL18, Pal.DIMMER, gStr);
        }
        dc.setColor(Pal.TRACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, base + 7, wi, 3, 1.5);
        if (mIntWeek != null && mIntGoal != null && (mIntGoal as Number) > 0) {
            var f = (mIntWeek as Number).toFloat() / (mIntGoal as Number);
            if (f > 1.0) { f = 1.0; }
            var fw = wi * f;
            if (fw >= 1.0) {
                dc.setColor(Pal.MINT, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(x, base + 7, fw < 3.0 ? 3.0 : fw, 3, 1.5);
            }
        }
        x += wi + gap;
        glyph(dc, x, base - Lay.ICON_MAIN, fI22, "K", Pal.MINT);
        text(dc, x + Lay.ICON_ADV, base, valueFont, valueAsc, Pal.INK, kStr);
        x += wk + gap;
        glyph(dc, x, base - Lay.ICON_MAIN, fI22, "F", Pal.MINT);
        text(dc, x + Lay.ICON_ADV, base, valueFont, valueAsc, Pal.INK, fStr);
    }

    // ------------------------------------------------------------------ environment & status

    private function tempStr(c) as String {
        var t = c.toFloat();
        if (mStatuteTemp) {
            t = t * 9.0 / 5.0 + 32.0;
        }
        return Fmt.round(t).format("%d");
    }

    // Item: [glyph or null, label before the value or null, value, suffix or null]
    private function itemWidth(dc as Graphics.Dc, it as Array) as Number {
        var w = tw(dc, it[2] as String, fN28);
        if (it[0] != null) { w += Lay.ICON_ADV; }
        if (it[1] != null) { w += tw(dc, it[1] as String, fL18) + 4; }
        if (it[3] != null) { w += 5 + tw(dc, it[3] as String, fL18); }
        return w;
    }

    private function rowWidth(dc as Graphics.Dc, items as Array, gap as Number) as Number {
        var total = gap * (items.size() - 1);
        for (var i = 0; i < items.size(); i++) {
            total += itemWidth(dc, items[i] as Array);
        }
        return total;
    }

    // Temperature with the day's high/low | humidity | UV (rain chance instead when likely).
    private function drawEnv(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        var base = cy + Lay.ENV_Y;
        var stale = (mWxAgeMin != null) && ((mWxAgeMin as Number) > Lay.STALE_MIN);
        var iconCol = stale ? Pal.scale(Pal.SKY, 0.5) : Pal.SKY;
        var valCol = stale ? Pal.DIM : Pal.INK;
        // Old weather may dim its icon, but never its small text. WX reports age.
        var subCol = Pal.DIMMER;

        var items = [];
        var cond = (mCond != null) ? condGlyph(mCond as Number) : "?";
        var hiLo = (mHiC != null && mLoC != null) ? tempStr(mHiC) + "/" + tempStr(mLoC) : null;
        items.add([cond, null, (mTempC != null) ? tempStr(mTempC) + "°" : "--", hiLo]);
        items.add(["D", null, (mHum != null) ? Fmt.round(mHum).format("%d") + "%" : "--", null]);
        if (mRainPct != null && (mRainPct as Number) >= Lay.RAIN_MIN) {
            items.add(["u", null, (mRainPct as Number).format("%d") + "%", null]);
        } else {
            items.add([null, "UV", (mUv != null) ? Fmt.round(mUv).format("%d") : "--", null]);
        }

        // Tighten spacing before dropping the high/low, then the third item.
        var gap = 16;
        var y = (Lay.ENV_Y + 2).toFloat();
        var avail = (2.0 * Math.sqrt(Lay.CONTENT_R * Lay.CONTENT_R - y * y)).toNumber() - 16;
        if (rowWidth(dc, items, gap) > avail) {
            gap = 10;
        }
        if (rowWidth(dc, items, gap) > avail) {
            var first = items[0] as Array;
            first[3] = null;
        }
        if (rowWidth(dc, items, gap) > avail && items.size() > 2) {
            items = items.slice(0, 2);
        }

        var x = cx - rowWidth(dc, items, gap) / 2;
        for (var j = 0; j < items.size(); j++) {
            var it = items[j] as Array;
            var ix = x;
            if (it[0] != null) {
                glyph(dc, ix, base - Lay.ICON_MAIN, fI22, it[0] as String, iconCol);
                ix += Lay.ICON_ADV;
            }
            if (it[1] != null) {
                text(dc, ix, base, fL18, aL18, Pal.SKY, it[1] as String);
                ix += tw(dc, it[1] as String, fL18) + 4;
            }
            text(dc, ix, base, fN28, aN28, valCol, it[2] as String);
            if (it[3] != null) {
                ix += tw(dc, it[2] as String, fN28) + 5;
                text(dc, ix, base, fL18, aL18, subCol, it[3] as String);
            }
            x += itemWidth(dc, it) + gap;
        }
    }

    // Weather.CONDITION_* -> icon glyph. 0-26 checked against the API docs.
    private function condGlyph(n as Number) as String {
        var night = !((mAstro as Dictionary)[:sunUp] as Boolean);
        if (n == 0 || n == 23 || n == 40) { return night ? "n" : "c"; }     // clear, mostly clear, fair
        if (n == 1 || n == 22 || n == 52) { return night ? "q" : "p"; }    // partly cloudy / clear, thin clouds
        if (n == 2 || n == 20) { return "C"; }                              // mostly cloudy, cloudy
        if (n == 6 || n == 12 || n == 28) { return "t"; }                   // thunder
        if (n == 4 || n == 7 || n == 10 || (n >= 16 && n <= 19) || n == 21 || n == 34
                || n == 43 || n == 44 || (n >= 46 && n <= 48) || n == 50 || n == 51) { return "s"; }
        if (n == 8 || n == 9 || n == 29 || n == 30 || n == 33 || n == 35 || (n >= 37 && n <= 39)) { return "f"; }
        if (n == 5 || n == 32 || n == 36 || n == 41 || n == 42) { return "w"; }
        if (n == 3 || n == 11 || (n >= 13 && n <= 15) || (n >= 24 && n <= 27)
                || n == 31 || n == 45 || n == 49) { return "r"; }         // rain, showers, drizzle
        return "?";                                                       // unknown or future condition code
    }

    // Weather observation age | battery | elevation
    private function drawStatus(dc as Graphics.Dc, cx as Number, cy as Number) as Void {
        var base = cy + Lay.STAT_Y;
        var gap = 10;
        var wxAdv = tw(dc, "WX", fL18) + 4;
        var rStr = "--";
        if (mWxAgeMin != null) {
            rStr = (mWxAgeMin < 60) ? mWxAgeMin.format("%d") + "m" : (mWxAgeMin / 60).format("%d") + "h";
        }
        var bStr = Fmt.round(mBattery).format("%d") + "%";
        var wr = tw(dc, rStr, fT22);
        var wb = tw(dc, bStr, fL20);

        var eStr = "--";
        if (mAltM != null) {
            var e = mAltM.toFloat();
            if (mStatuteElev) {
                e = e * 3.28084;
            }
            eStr = Fmt.thousands(Fmt.round(e));
        }
        var eUnit = mStatuteElev ? "ft" : "m";
        var we = tw(dc, eStr, fL20);
        var wu = tw(dc, eUnit, fL18) + 2;

        // Keep inside the ring: drop the unit first, then the elevation.
        var y = (Lay.STAT_Y + 2).toFloat();
        var avail = (2.0 * Math.sqrt(Lay.CONTENT_R * Lay.CONTENT_R - y * y)).toNumber() - 16;
        var core = wxAdv + wr + gap + Lay.ICON_ADV + wb;
        var showElev = true;
        if (core + gap + Lay.SMALL_ADV + we + wu > avail) {
            wu = 0;
        }
        if (core + gap + Lay.SMALL_ADV + we + wu > avail) {
            showElev = false;
        }
        var total = core + (showElev ? gap + Lay.SMALL_ADV + we + wu : 0);
        var x = cx - total / 2;

        text(dc, x, base, fL18, aL18, Pal.SKY, "WX");
        x += wxAdv;
        text(dc, x, base, fT22, aT22, Pal.INK, rStr);
        x += wr + gap;

        var top = base - 23;
        glyph(dc, x, top, fI22, "T", Pal.DIMMER);
        var pct = mBattery.toFloat() / 100.0;
        if (pct > 1.0) { pct = 1.0; }
        var fill = Fmt.round(14.0 * pct);
        if (fill < 0) { fill = 0; }
        dc.setColor(pct < 0.15 ? Pal.CORAL : Pal.DIMMER, Graphics.COLOR_TRANSPARENT);
        if (fill > 0) { dc.fillRectangle(x + 5, top + 11, fill, 6); }
        x += Lay.ICON_ADV;
        text(dc, x, base, fL20, aL20, Pal.DIM, bStr);
        x += wb + gap;

        if (showElev) {
            glyph(dc, x, base - Lay.ICON_SMALL, fI16, "m", Pal.DIMMER);
            x += Lay.SMALL_ADV;
            text(dc, x, base, fL20, aL20, Pal.DIM, eStr);
            if (wu > 0) {
                text(dc, x + we + 2, base, fL18, aL18, Pal.DIMMER, eUnit);
            }
        }
    }

}
