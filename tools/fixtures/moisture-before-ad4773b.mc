// Regression-only fixture: exact methods from commit ad4773b.
// Never included in the app source path.

function onExitSleep() as Void {
        mSleeping = false;
        mLastFrameAt = -1;
        mRefreshKey = -1;
        mHrHistoryPollAt = -1;
        // Do not gate this on an old visibility flag either.
        WatchUi.requestUpdate();
    }

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
        // Restart the weather slot only at an observed wake/show transition.
        // A slow frame gap still refreshes data without repeatedly pinning RH.
        if (mLastFrameAt < 0 || mode != mLastDisplayMode) {
            mEnvCycleAt = -1;
        }
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
        drawEnv(dc, cx, cy, now.value());
    }

function updateWeatherCycle(nowSec as Number) as Void {
        if (mEnvCycleAt < 0 || nowSec < mEnvCycleAt) {
            mEnvCycleAt = nowSec;
            mEnvShowDew = false;
        } else if (nowSec - mEnvCycleAt >= 2) {
            mEnvCycleAt = nowSec;
            mEnvShowDew = !mEnvShowDew;
        }
    }
