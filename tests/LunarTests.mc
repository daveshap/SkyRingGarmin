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
    // Upper semicircle is NOT a horizon boundary on an hour-angle dial.
    var p = Lunar.position(1790287020, 36.075, -79.10);
    Test.assert(p[:horizon] < 0);
    Test.assert(p[:hourAngle] > -90 && p[:hourAngle] < 0);
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
