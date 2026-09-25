import Toybox.Test;
import Toybox.Lang;
import Toybox.ActivityMonitor;

(:test)
function stressHistoryKeepsMeasuredZeroAndMissingGaps(logger) {
    var now = 14400;
    var h = new HistoryBuckets(now, 0, 100);
    h.add(0, 0);
    h.add(600, 25);
    h.add(900, 75.0);
    h.add(1200, null);
    h.add(1800, -1);
    h.add(2400, 101);
    h.add(3000, "20");
    h.add(3600, false);
    h.add(null, 40);
    h.add("4200", 40);
    h.add(now, 100);
    var out = h.finish();
    Test.assertEqual(out.size(), 24);
    Test.assertEqual(out[0], 0.0);
    Test.assertEqual(out[1], 50.0);
    for (var i = 2; i < 23; i++) { Test.assertEqual(out[i], null); }
    Test.assertEqual(out[23], 100.0);
    return true;
}

(:test)
function historyTenMinuteEdgesAndWindowBoundsAreStable(logger) {
    var now = 20000;
    var start = now - 14400;
    var h = new HistoryBuckets(now, 0, 100);
    h.add(start - 1, 99);
    h.add(now + 1, 99);
    // Deliberately newest first; timestamps, not record order, choose buckets.
    h.add(now, 100);
    h.add(now - 1, 50);
    h.add(start + 600, 30);
    h.add(start + 599, 20);
    h.add(start, 0);
    var out = h.finish();
    Test.assertEqual(out[0], 10.0);
    Test.assertEqual(out[1], 30.0);
    Test.assertEqual(out[22], null);
    Test.assertEqual(out[23], 75.0);
    // Repeated reads do not divide an already-averaged result a second time.
    Test.assertEqual(h.finish()[23], 75.0);
    return true;
}

(:test)
function heartRateHistoryRejectsMissingAndInvalidSamples(logger) {
    var h = new HistoryBuckets(14400, 1, ActivityMonitor.INVALID_HR_SAMPLE - 1);
    h.add(1, null);
    h.add(2, 0);
    h.add(3, -1);
    h.add(4, ActivityMonitor.INVALID_HR_SAMPLE);
    h.add(5, ActivityMonitor.INVALID_HR_SAMPLE + 1);
    h.add(600, 60);
    h.add(601, 80.0);
    var out = h.finish();
    Test.assertEqual(out[0], null);
    Test.assertEqual(out[1], 70.0);
    Test.assertEqual(out[23], null);
    return true;
}

(:test)
function historyFreshBuildAfterClockRollbackHasNoFutureTail(logger) {
    var oldNow = 50000;
    var oldHistory = new HistoryBuckets(oldNow, 0, 100);
    oldHistory.add(oldNow, 90);
    Test.assertEqual(oldHistory.finish()[23], 90.0);
    var correctedNow = oldNow - 3600;
    var corrected = new HistoryBuckets(correctedNow, 0, 100);
    corrected.add(oldNow, 90);
    corrected.add(correctedNow - 3600, 15);
    var out = corrected.finish();
    Test.assertEqual(out[18], 15.0);
    Test.assertEqual(out[23], null);
    return true;
}
