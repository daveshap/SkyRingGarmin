import Toybox.Test;

(:test)
function recoveryDisplaysRawWholeHours(logger) {
    var values = [0, 1, 7, 96];
    for (var i = 0; i < values.size(); i++) {
        var shown = RecoveryTime.displayHours(values[i]);
        Test.assertEqual(shown[:value], values[i].format("%d"));
        Test.assertEqual(shown[:unit], "h");
        Test.assertEqual(shown[:label], values[i] == 0 ? "READY" : "RECOVERY");
    }
    return true;
}

(:test)
function recoveryZeroHoursShowsReadyCaption(logger) {
    Test.assertEqual(RecoveryTime.validHours(0), 0);
    var zero = RecoveryTime.displayHours(0);
    Test.assertEqual(zero[:value], "0");
    Test.assertEqual(zero[:unit], "h");
    // READY is the selected caption for Garmin's raw zero-hour reading.
    Test.assertEqual(zero[:label], "READY");
    return true;
}

(:test)
function recoveryMissingOrInvalidHoursStayUnknown(logger) {
    var invalid = [null, -1, "7", 7.5, true];
    for (var i = 0; i < invalid.size(); i++) {
        Test.assertEqual(RecoveryTime.validHours(invalid[i]), null);
        var shown = RecoveryTime.displayHours(invalid[i]);
        Test.assertEqual(shown[:value], "--");
        Test.assertEqual(shown[:unit], null);
        Test.assertEqual(shown[:label], "RECOVERY");
    }
    return true;
}
