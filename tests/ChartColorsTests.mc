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

(:test)
function weatherColorsCompareGlyphContentsAcrossAllocations(logger) {
    var glyphs = ["c", "p", "t", "n", "q", "C", "f", "r", "s", "w"];
    var expected = [ChartColors.WEATHER_SUN, ChartColors.WEATHER_SUN,
        ChartColors.WEATHER_SUN, ChartColors.WEATHER_MOON,
        ChartColors.WEATHER_MOON, ChartColors.WEATHER_CLOUD,
        ChartColors.WEATHER_FOG, ChartColors.WEATHER_RAIN,
        ChartColors.WEATHER_SNOW, ChartColors.WEATHER_WIND];
    for (var i = 0; i < glyphs.size(); i++) {
        Test.assertEqual(ChartColors.condition(glyphs[i]), expected[i]);
        // Produce a separate string at runtime; == cannot compare its contents.
        var dynamicGlyph = ("prefix" + glyphs[i]).substring(6, 7) as String;
        Test.assertEqual(ChartColors.condition(dynamicGlyph), expected[i]);
    }
    Test.assertEqual(ChartColors.WEATHER_SUN, 0xFFF000);
    Test.assertEqual(ChartColors.condition("?"), Pal.DIMMER);
    Test.assertEqual(ChartColors.condition("future"), Pal.DIMMER);
    return true;
}

(:test)
function ultravioletColorsUseDisplayedRiskCategory(logger) {
    var levels = [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 15];
    var expected = [ChartColors.GREEN, ChartColors.GREEN, ChartColors.GREEN,
        ChartColors.YELLOW, ChartColors.YELLOW, ChartColors.ORANGE,
        ChartColors.ORANGE, ChartColors.RED, ChartColors.RED,
        ChartColors.PURPLE, ChartColors.PURPLE];
    for (var i = 0; i < levels.size(); i++) {
        Test.assertEqual(ChartColors.uvIndex(levels[i]), expected[i]);
    }
    Test.assertEqual(ChartColors.uvIndex(null), Pal.DIMMER);
    Test.assertEqual(ChartColors.uvIndex(-1), Pal.DIMMER);
    Test.assertEqual(ChartColors.uvIndex("2"), Pal.DIMMER);
    Test.assertEqual(ChartColors.uvIndex(2.5), Pal.DIMMER);
    return true;
}
