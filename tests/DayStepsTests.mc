import Toybox.Test;
import Toybox.Lang;

(:test)
function stepsUseSixDatesAndLiveToday(logger) {
    var day = DaySteps.dayNumber(2026, 9, 24);
    var r = DaySteps.summarize(day, 123, [[day - 7, 9999], [day - 6, 100],
        [day - 5, 200], [day - 4, 300], [day - 3, 400], [day - 2, 500],
        [day - 1, 600], [day, 9999], [day + 1, 9999], [day - 1, 9999]]);
    Test.assertEqual(r[:sum], 2223);
    Test.assertEqual(r[:count], 7);
    Test.assert(r[:complete]);
    var bars = r[:bars] as Array;
    Test.assertEqual(bars[0], 100);
    Test.assertEqual(bars[6], 123);
    return true;
}

(:test)
function stepsMissingDaysStayMissing(logger) {
    var day = DaySteps.dayNumber(2026, 9, 24);
    var r = DaySteps.summarize(day, 123, [[day - 6, 100], [day - 4, 0],
        [day - 2, null], [day - 2, -1], [day - 1, 600]]);
    Test.assertEqual(r[:sum], 823);
    Test.assertEqual(r[:count], 4);
    Test.assert(!r[:complete]);
    var bars = r[:bars] as Array;
    Test.assertEqual(bars[1], null);
    Test.assertEqual(bars[2], 0);
    Test.assertEqual(bars[4], null);
    var none = DaySteps.summarize(day, null, []);
    Test.assertEqual(none[:sum], null);
    var live = DaySteps.summarize(day, 123, []);
    Test.assertEqual(live[:sum], 123);
    Test.assert(!live[:complete]);
    return true;
}

(:test)
function stepsCivilDatesCrossLeapYearAndDst(logger) {
    Test.assertEqual(DaySteps.dayNumber(1970, 1, 1), 719163);
    Test.assertEqual(DaySteps.dayNumber(2024, 3, 1) - DaySteps.dayNumber(2024, 2, 28), 2);
    Test.assertEqual(DaySteps.dayNumber(1900, 3, 1) - DaySteps.dayNumber(1900, 2, 28), 1);
    Test.assertEqual(DaySteps.dayNumber(2026, 1, 1) - DaySteps.dayNumber(2025, 12, 31), 1);
    // These are 23-hour / 25-hour days locally but still one calendar day each.
    Test.assertEqual(DaySteps.dayNumber(2026, 3, 9) - DaySteps.dayNumber(2026, 3, 8), 1);
    Test.assertEqual(DaySteps.dayNumber(2026, 11, 2) - DaySteps.dayNumber(2026, 11, 1), 1);
    return true;
}

(:test)
function stepsMidnightDropsOldestDate(logger) {
    var day = DaySteps.dayNumber(2026, 9, 24);
    var records = [[day - 6, 100], [day - 5, 200], [day - 4, 300],
        [day - 3, 400], [day - 2, 500], [day - 1, 600], [day, 700]];
    Test.assertEqual(DaySteps.summarize(day, 700, records)[:sum], 2800);
    Test.assertEqual(DaySteps.summarize(day + 1, 0, records)[:sum], 2700);
    return true;
}

(:test)
function stepGoalsFollowTheirAcceptedDates(logger) {
    var day = DaySteps.dayNumber(2026, 9, 25);
    var r = DaySteps.summarizeWithGoals(day, 7500, 7000, [
        [day - 7, 99999, 1], [day + 1, 99999, 1], [day, 99999, 1],
        [day - 6, 8000, 9000], [day - 5, 6000, 5000],
        [day - 4, 3000], [day - 3, 0, 6500],
        [day - 2, 4000, null], [day - 1, 5000, 5500],
        [day - 5, 6000, 99999], [day - 4, 3000, 1]
    ]);
    var bars = r[:bars] as Array;
    var goals = r[:goals] as Array;
    Test.assertEqual(r[:sum], 33500);
    Test.assert(r[:complete]);
    Test.assertEqual(goals[0], 9000);
    Test.assertEqual(goals[1], 5000); // Later duplicate cannot change the goal.
    Test.assertEqual(goals[2], null); // Cannot borrow a duplicate/today's goal.
    Test.assertEqual(goals[3], 6500); // Measured zero still owns its day's goal.
    Test.assertEqual(goals[4], null);
    Test.assertEqual(goals[5], 5500);
    Test.assertEqual(goals[6], 7000);
    Test.assertEqual(bars[6], 7500); // Live data always owns today.
    return true;
}

(:test)
function missingOrInvalidGoalsDoNotInventAchievement(logger) {
    var day = DaySteps.dayNumber(2026, 9, 25);
    var r = DaySteps.summarizeWithGoals(day, 0, 0, [
        [day - 6, 4000, 0], [day - 5, 4000, -1],
        [day - 4, 4000, "5000"], [day - 3, null, 5000],
        [day - 2, -1, 5000], [day - 1, 4000, null]
    ]);
    var goals = r[:goals] as Array;
    for (var i = 0; i < 7; i++) { Test.assertEqual(goals[i], null); }
    Test.assertEqual(r[:sum], 16000);
    Test.assertEqual(r[:count], 5);
    // Preserve the old entry point and two-field records without assigning goals.
    var old = DaySteps.summarize(day, 100, [[day - 1, 200]]);
    Test.assertEqual(old[:sum], 300);
    Test.assertEqual((old[:goals] as Array)[5], null);
    Test.assertEqual((old[:goals] as Array)[6], null);
    return true;
}
