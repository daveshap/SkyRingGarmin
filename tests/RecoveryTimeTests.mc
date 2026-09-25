import Toybox.Test;

(:test)
function recoveryPreservesLastHourMinutesAndTrueZero(logger) {
    var ready = RecoveryTime.display(0);
    Test.assertEqual(ready[:value], "0");
    Test.assertEqual(ready[:label], "READY");
    var one = RecoveryTime.display(1);
    Test.assertEqual(one[:value], "1");
    Test.assertEqual(one[:unit], "m");
    Test.assertEqual(one[:label], "RECOVERY");
    Test.assertEqual(RecoveryTime.display(59)[:value], "59");
    Test.assertEqual(RecoveryTime.display(59)[:unit], "m");
    Test.assertEqual(RecoveryTime.display(60)[:value], "1");
    Test.assertEqual(RecoveryTime.display(60)[:unit], "h");
    Test.assertEqual(RecoveryTime.display(61)[:value], "2");
    return true;
}

(:test)
function missingRecoveryCannotClaimReady(logger) {
    var missing = RecoveryTime.display(null);
    Test.assertEqual(missing[:value], "--");
    Test.assertEqual(missing[:unit], null);
    Test.assertEqual(missing[:label], "RECOVERY");
    Test.assertEqual(RecoveryTime.display(-1)[:value], "--");
    return true;
}
