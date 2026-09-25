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
    Test.assertEqual(RecoveryTime.display("1")[:value], "--");
    return true;
}

(:test)
function recoveryWakeTransientOneDoesNotFlashOrManufactureReady(logger) {
    var state = new RecoveryReadState();
    state.wake(100);
    Test.assertEqual(state.accept(1, 100), null);
    Test.assertEqual(state.accept(1, 100), null);
    Test.assert(!state.due(100));
    Test.assert(state.due(101));
    Test.assertEqual(state.accept(0, 101), 0);
    Test.assert(!state.due(102));
    Test.assert(state.due(103));
    Test.assertEqual(state.accept(0, 103), 0);
    Test.assert(!state.due(104));
    Test.assert(!state.due(160));
    return true;
}

(:test)
function recoveryGenuineLastMinuteSurvivesSettling(logger) {
    var state = new RecoveryReadState();
    // Cold initialization is safe even before an explicit wake call.
    Test.assertEqual(state.accept(1, 100), null);
    Test.assertEqual(state.accept(1, 101), 1);
    Test.assertEqual(RecoveryTime.display(state.accept(1, 103))[:unit], "m");
    Test.assertEqual(state.accept(0, 120), 0);
    // Recalculations while continuously awake remain actual native values.
    Test.assertEqual(state.accept(30, 160), 30);
    return true;
}

(:test)
function recoveryZeroImmediateUnknownNeverBecomesReady(logger) {
    var state = new RecoveryReadState();
    state.wake(200);
    Test.assertEqual(state.accept(0, 200), 0);
    Test.assertEqual(state.accept(null, 201), null);
    Test.assertEqual(state.accept(-1, 203), null);
    Test.assertEqual(state.accept("1", 204), null);
    Test.assertEqual(state.accept(null, 260), null);
    Test.assert(!state.due(260));
    return true;
}

(:test)
function recoveryCountdownMayChangeBetweenReads(logger) {
    var state = new RecoveryReadState();
    state.wake(300);
    Test.assertEqual(state.accept(61, 300), null);
    Test.assertEqual(state.accept(60, 301), 60);
    Test.assertEqual(state.accept(59, 303), 59);
    Test.assert(!state.due(304));
    return true;
}

(:test)
function recoveryLateFrameDoesNotQueueCatchUpReads(logger) {
    var state = new RecoveryReadState();
    state.wake(400);
    Test.assertEqual(state.accept(1, 400), null);
    Test.assert(state.due(404));
    Test.assertEqual(state.accept(1, 404), 1);
    Test.assert(!state.due(404));
    Test.assert(!state.due(450));
    return true;
}

(:test)
function recoveryWakeAndClockRollbackRearmWithoutStaleDisplay(logger) {
    var state = new RecoveryReadState();
    state.wake(500);
    Test.assertEqual(state.accept(0, 500), 0);
    state.accept(0, 501);
    state.accept(0, 503);
    Test.assert(!state.due(510));
    Test.assert(state.due(450));
    Test.assertEqual(state.accept(1, 450), null);
    Test.assert(!state.due(450));
    Test.assert(state.due(451));
    Test.assertEqual(state.accept(1, 451), 1);
    Test.assertEqual(state.accept(0, 453), 0);
    Test.assert(!state.due(454));
    state.wake(700);
    Test.assertEqual(state.accept(1, 700), null);
    Test.assertEqual(state.accept(0, 701), 0);
    return true;
}
