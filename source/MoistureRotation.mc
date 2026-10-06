import Toybox.Lang;

// Presentation state only. Use monotonic milliseconds, never civil time or
// weather-observation age. Rendering and data refreshes do not own this clock.
class MoistureRotation {
    private var mActive as Boolean = false;
    private var mBothAvailable as Boolean = false;
    private var mChangedAt as Number = 0;
    private var mShowDew as Boolean = false;

    function pause() as Void {
        mActive = false;
        // Preserve the selected reading across sleep and duplicate wake events.
    }

    function update(nowMs as Number, bothAvailable as Boolean) as Void {
        if (!mActive || bothAvailable != mBothAvailable || nowMs < mChangedAt) {
            mActive = true;
            mBothAvailable = bothAvailable;
            mChangedAt = nowMs;
            return;
        }
        if (isDue(nowMs)) {
            mShowDew = !mShowDew;
            mChangedAt = nowMs;
        }
    }

    function isRotating() as Boolean {
        return mActive && mBothAvailable;
    }

    function isDue(nowMs as Number) as Boolean {
        // A wrapped/reset monotonic counter gets a new dwell on the next frame.
        return isRotating() && (nowMs < mChangedAt || nowMs - mChangedAt >= 2000);
    }

    function showDew() as Boolean {
        return mShowDew;
    }
}
