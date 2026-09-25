import Toybox.Test;
import Toybox.Lang;

(:test)
function heartRateColorsUseAbsoluteBpmBoundaries(logger) {
    Test.assertEqual(ChartColors.heartRate(null), Pal.TRACK);
    Test.assertEqual(ChartColors.heartRate(-1), Pal.TRACK);
    var rates = [0, 59, 59.9, 60, 69.9, 70, 89.9, 90, 109.9, 110, 129.9, 130, 200];
    var expected = [Pal.TRACK, ChartColors.PURPLE, ChartColors.PURPLE,
        ChartColors.BLUE, ChartColors.BLUE, ChartColors.GREEN, ChartColors.GREEN,
        ChartColors.YELLOW, ChartColors.YELLOW, ChartColors.ORANGE,
        ChartColors.ORANGE, ChartColors.RED, ChartColors.RED];
    for (var i = 0; i < rates.size(); i++) {
        Test.assertEqual(ChartColors.heartRate(rates[i]), expected[i]);
    }
    return true;
}

(:test)
function stressColorsKeepRestBoundaryAtTwentyFive(logger) {
    var levels = [null, -1, 0, 14, 15, 25, 26, 50, 51, 65, 66, 75, 76, 100, 101];
    var expected = [Pal.TRACK, Pal.TRACK, ChartColors.PURPLE, ChartColors.PURPLE,
        ChartColors.BLUE, ChartColors.BLUE, ChartColors.GREEN, ChartColors.GREEN,
        ChartColors.YELLOW, ChartColors.YELLOW, ChartColors.ORANGE,
        ChartColors.ORANGE, ChartColors.RED, ChartColors.RED, Pal.TRACK];
    for (var i = 0; i < levels.size(); i++) {
        Test.assertEqual(ChartColors.stress(levels[i]), expected[i]);
    }
    Test.assertEqual(ChartColors.stress(14.49), ChartColors.PURPLE);
    Test.assertEqual(ChartColors.stress(14.5), ChartColors.BLUE);
    Test.assertEqual(ChartColors.stress(25.49), ChartColors.BLUE);
    Test.assertEqual(ChartColors.stress(25.5), ChartColors.GREEN);
    return true;
}

(:test)
function stepsChangeColorOnlyAtAKnownPositiveGoal(logger) {
    Test.assertEqual(ChartColors.steps(5999, 6000), ChartColors.GREEN);
    Test.assertEqual(ChartColors.steps(6000, 6000), ChartColors.YELLOW);
    Test.assertEqual(ChartColors.steps(6001, 6000), ChartColors.YELLOW);
    Test.assertEqual(ChartColors.steps(12000, null), ChartColors.GREEN);
    Test.assertEqual(ChartColors.steps(12000, 0), ChartColors.GREEN);
    Test.assertEqual(ChartColors.steps(12000, -1), ChartColors.GREEN);
    Test.assertEqual(ChartColors.steps(0, 6000), ChartColors.GREEN);
    Test.assertEqual(ChartColors.steps(null, 6000), Pal.TRACK);
    Test.assertEqual(ChartColors.steps(-1, 6000), Pal.TRACK);
    return true;
}
