import Toybox.Test;
import Toybox.System;

(:test)
function awakeModeWinsOverStaleSleepAndHideCallbacks(logger) {
    // Regression: the old view returned black before asking the display mode.
    var high = System.DISPLAY_MODE_HIGH_POWER;
    Test.assertEqual(WakeState.resolve(high, true, true), high);
    Test.assertEqual(WakeState.resolve(high, false, false), high);
    Test.assertEqual(WakeState.resolve(high, true, false), high);
    return true;
}

(:test)
function offAndLowPowerCannotBeOverriddenByAwakeFlags(logger) {
    var off = System.DISPLAY_MODE_OFF;
    var low = System.DISPLAY_MODE_LOW_POWER;
    Test.assertEqual(WakeState.resolve(off, false, true), off);
    Test.assertEqual(WakeState.resolve(low, false, true), low);
    Test.assert(!WakeState.needsRefresh(off, System.DISPLAY_MODE_HIGH_POWER, 10, 20));
    Test.assert(!WakeState.needsRefresh(low, System.DISPLAY_MODE_HIGH_POWER, 10, 20));
    return true;
}

(:test)
function displayTransitionRefreshesAfterMissingWakeCallback(logger) {
    var high = System.DISPLAY_MODE_HIGH_POWER;
    var low = System.DISPLAY_MODE_LOW_POWER;
    var off = System.DISPLAY_MODE_OFF;
    // Same-minute sleep/wake must bypass the otherwise-valid minute cache.
    Test.assert(WakeState.needsRefresh(high, low, 120, 124));
    Test.assert(WakeState.needsRefresh(high, off, 120, 124));
    Test.assert(!WakeState.needsRefresh(high, high, 124, 125));
    // Also cover a pause with no intervening frame or lifecycle callback.
    Test.assert(WakeState.needsRefresh(high, high, 125, 145));
    Test.assert(WakeState.needsRefresh(high, high, -1, 145));
    Test.assert(WakeState.needsRefresh(high, high, 145, 100));
    return true;
}

(:test)
function callbackStateOnlyAppliesWithoutDisplayModeApi(logger) {
    Test.assertEqual(WakeState.resolve(null, false, true), System.DISPLAY_MODE_HIGH_POWER);
    Test.assertEqual(WakeState.resolve(null, true, true), System.DISPLAY_MODE_LOW_POWER);
    Test.assertEqual(WakeState.resolve(null, false, false), System.DISPLAY_MODE_OFF);
    return true;
}
