import Toybox.Test;

// Independent USNO Hillsborough, NC reference: 2026-09-24 20:00 EDT.
// https://aa.usno.navy.mil/data/celnav ; public city-center 36.075,-79.10.
// Keep each test to one current-position calculation, not an event search.
(:test)
function lunarPositionMatchesUSNO(logger) {
    var p = Lunar.position(1790294400, 36.075, -79.10);
    Test.assert((p[:hourAngle] + 57.380713).abs() < 0.03);
    Test.assert((p[:altitude] - 20.67).abs() < 0.06);
    Test.assert((p[:azimuth] - 115.903174).abs() < 0.03);
    Test.assert((p[:illumination] - 0.9671).abs() < 0.002);
    Test.assertEqual(p[:waxing], true);
    Test.assert(p[:horizon] > 0);
    return true;
}

(:test)
function lunarLongitudeIsEastPositive(logger) {
    // Same instant, longitude changed by +179.10 degrees; hour angle must
    // change by the same amount. Latitude does not affect geocentric H.
    var p = Lunar.position(1790294400, -36.075, 100.0);
    Test.assert((p[:hourAngle] - 121.719287).abs() < 0.03);
    Test.assert((p[:illumination] - 0.9671).abs() < 0.002);
    Test.assertEqual(p[:waxing], true);
    return true;
}

(:test)
function lunarBelowHorizonBeforeUSNORise(logger) {
    // 17:57 EDT: ten minutes before the reference 18:07 moonrise.
    // This is the original failure case: raw hour angle incorrectly puts the
    // Moon above the dial's diameter before it has actually risen.
    var p = Lunar.position(1790287020, 36.075, -79.10);
    Test.assert(p[:horizon] < 0);
    Test.assert(p[:hourAngle] > -90 && p[:hourAngle] < 0);
    return true;
}

(:test)
function lunarSeptember30MorningUsesLocalHorizon(logger) {
    // Reported bug: 2026-09-30 10:00 EDT in Hillsborough. The Moon is
    // about 16.57 degrees high, although its hour angle is nearly 90.
    var p = Lunar.position(1790776800, 36.075, -79.10);
    Test.assert((p[:altitude] - 16.57).abs() < 0.06);
    Test.assert(p[:hourAngle] > 85 && p[:hourAngle] < 90);
    var ring = Astro.moonRingAngle(p[:hourAngle], p[:altitude], p[:azimuth]);
    Test.assert(ring > 65 && ring < 75);
    return true;
}

(:test)
function lunarRingHasIndependentEastWestHorizon(logger) {
    Test.assert((Astro.moonRingAngle(-60, 0, 90) + 90).abs() < 0.001);
    Test.assert((Astro.moonRingAngle(60, 0, 270) - 90).abs() < 0.001);
    Test.assert(Astro.moonRingAngle(-60, 20, 90) > -90);
    Test.assert(Astro.moonRingAngle(60, 20, 270) < 90);
    Test.assert(Astro.moonRingAngle(-60, -20, 90) < -90);
    Test.assert(Astro.moonRingAngle(60, -20, 270) > 90);
    return true;
}

(:test)
function lunarRingTransitsAndDegenerateProjectionStayDefined(logger) {
    Test.assert(Astro.moonRingAngle(0, 45, 180).abs() < 0.001);
    Test.assert(Astro.moonRingAngle(0, 45, 0).abs() < 0.001);
    Test.assert((Astro.moonRingAngle(180, -45, 0).abs() - 180).abs() < 0.001);
    Test.assertEqual(Astro.moonRingAngle(-90, 0, 0), -90.0);
    Test.assertEqual(Astro.moonRingAngle(90, 0, 180), 90.0);
    return true;
}

(:test)
function lunarRingBelowHorizonBeforeRise(logger) {
    var p = Lunar.position(1790287020, 36.075, -79.10);
    var ring = Astro.moonRingAngle(p[:hourAngle], p[:altitude], p[:azimuth]);
    Test.assert(p[:altitude] < 0);
    Test.assert(ring < -90);
    return true;
}

(:test)
function lunarAboveHorizonAfterUSNORise(logger) {
    // 18:17 EDT: ten minutes after the reference 18:07 moonrise.
    var p = Lunar.position(1790288220, 36.075, -79.10);
    Test.assert(p[:horizon] > 0);
    Test.assert(p[:hourAngle] > -90 && p[:hourAngle] < 0);
    return true;
}
