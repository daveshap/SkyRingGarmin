import Toybox.Lang;
import Toybox.System;

// Display mode is the source of truth on the FR965. Lifecycle callbacks are
// advisory: missing/delayed callbacks must never latch an awake display black.
module WakeState {
    function resolve(mode, sleeping as Boolean, visible as Boolean) as Number {
        if (mode != null) {
            return mode;
        }
        // Compatibility only for devices without System.getDisplayMode().
        if (!visible) {
            return System.DISPLAY_MODE_OFF;
        }
        return sleeping ? System.DISPLAY_MODE_LOW_POWER : System.DISPLAY_MODE_HIGH_POWER;
    }

    function needsRefresh(mode as Number, previousMode as Number,
            lastFrameAt as Number, nowSec as Number) as Boolean {
        if (mode != System.DISPLAY_MODE_HIGH_POWER) {
            return false;
        }
        // The gap catches a resume with neither sleep/wake callback nor an
        // intervening off-screen onUpdate. It requests no timers or updates.
        return previousMode != System.DISPLAY_MODE_HIGH_POWER || lastFrameAt < 0
            || nowSec < lastFrameAt || nowSec - lastFrameAt > 5;
    }
}
