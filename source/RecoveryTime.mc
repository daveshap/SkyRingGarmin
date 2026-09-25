import Toybox.Lang;

module RecoveryTime {
    // The documented recovery complication is an integer number of minutes.
    // Unknown or malformed data must never become READY by default/coercion.
    function validMinutes(value) {
        return (value instanceof Number && value >= 0) ? value : null;
    }

    // Garmin's recovery complication reports minutes, not whole hours. Keep
    // the final hour in minutes so 1 minute does not misleadingly become 1h.
    function display(minutes) as Dictionary {
        minutes = validMinutes(minutes);
        if (minutes == null) {
            return { :value => "--", :unit => null, :label => "RECOVERY" };
        }
        var m = minutes.toNumber();
        if (m == 0) {
            return { :value => "0", :unit => "h", :label => "READY" };
        }
        if (m < 60) {
            return { :value => m.format("%d"), :unit => "m", :label => "RECOVERY" };
        }
        return { :value => ((m + 59) / 60).format("%d"), :unit => "h", :label => "RECOVERY" };
    }
}

// Garmin provides no timestamp for this complication. A read immediately on
// waking can therefore not establish source freshness. Give its first positive
// value one later awake frame to settle, then display the actual native value.
// This is a bounded wake-time mitigation, not an inferred recovery countdown.
// The view calls due() only during normal HIGH_POWER frames: no timer, forced
// redraw, background work, or persistent storage belongs here.
class RecoveryReadState {
    private var mWakeAt as Number = -1;
    private var mLastReadAt as Number = -1;
    private var mNextReadAt as Number = -1;

    function initialize() {
    }

    function wake(nowSec as Number) as Void {
        mWakeAt = nowSec;
        mLastReadAt = -1;
        mNextReadAt = nowSec + 1;
    }

    function due(nowSec as Number) as Boolean {
        // A wall-clock rollback restarts the bounded window at the next read.
        return (mLastReadAt >= 0 && nowSec < mLastReadAt)
            || (mNextReadAt >= 0 && nowSec >= mNextReadAt);
    }

    function accept(raw, nowSec as Number) {
        if (mWakeAt < 0 || (mLastReadAt >= 0 && nowSec < mLastReadAt)) {
            wake(nowSec);
        }
        mLastReadAt = nowSec;

        if (mNextReadAt >= 0 && nowSec >= mNextReadAt) {
            // At most two follow-up reads: at about +1s and +3s. A normal
            // minute/callback read can satisfy either deadline. If frames
            // skipped both deadlines, one fresh read is enough; no catch-up.
            mNextReadAt = nowSec < mWakeAt + 3 ? mWakeAt + 3 : -1;
        }

        var minutes = RecoveryTime.validMinutes(raw);
        if (minutes != null && minutes > 0 && nowSec < mWakeAt + 1) {
            // Show -- briefly; do not carry an old READY or manufacture zero.
            // Repeating a read during this same second cannot confirm it.
            return null;
        }
        // Native zero publishes immediately. A genuine one minute remains
        // one minute after confirmation. No value-equality test or rounding
        // threshold can hide a valid short recovery or its natural countdown.
        return minutes;
    }
}
