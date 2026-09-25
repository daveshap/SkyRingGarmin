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
