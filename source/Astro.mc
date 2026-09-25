import Toybox.Lang;
import Toybox.Math;

// Solar position from Astronomical Almanac approximations; lunar position
// from Lunar (Meeus periodic ephemeris). Double day counts avoid 32-bit
// Float loss of sidereal precision. All returned angles are degrees.
module Astro {

    const RAD = 0.017453292519943295d;

    function w360(x as Numeric) as Double {
        var v = x.toDouble();
        var n = (v / 360.0d).toLong();
        var r = v - n * 360.0d;
        if (r < 0.0d) {
            r += 360.0d;
        }
        return r;
    }

    function w180(x as Numeric) as Double {
        var r = w360(x);
        return (r > 180.0d) ? r - 360.0d : r;
    }

    function sind(x as Numeric) as Double {
        return Math.sin(x.toDouble() * RAD).toDouble();
    }

    function cosd(x as Numeric) as Double {
        return Math.cos(x.toDouble() * RAD).toDouble();
    }

    function asind(x as Numeric) as Double {
        var v = x.toDouble();
        if (v > 1.0d) { v = 1.0d; }
        if (v < -1.0d) { v = -1.0d; }
        return (Math.asin(v) / RAD).toDouble();
    }

    function atan2d(y as Numeric, x as Numeric) as Double {
        return (Math.atan2(y.toDouble(), x.toDouble()) / RAD).toDouble();
    }

    // Hour angle (degrees, 0..180) at which the sun sits at altitude h0.
    // 180 = never goes below h0 that day, 0 = never reaches h0.
    function hourAngle(h0 as Numeric, lat as Numeric, dec as Numeric) as Double {
        var c = (sind(h0) - sind(lat) * sind(dec)) / (cosd(lat) * cosd(dec));
        if (c <= -1.0d) { return 180.0d; }
        if (c >= 1.0d) { return 0.0d; }
        return (Math.acos(c) / RAD).toDouble();
    }

    // unix: UTC seconds. lat/lon: degrees (east positive). tzSec: local offset incl. DST.
    function compute(unix as Number, lat as Float, lon as Float, tzSec as Number) as Dictionary {
        var d = unix.toDouble() / 86400.0d - 10957.5d;   // days since J2000.0

        // --- Sun ---
        var g = w360(357.529d + 0.98560028d * d);
        var q = w360(280.459d + 0.98564736d * d);
        var sunLon = w360(q + 1.915d * sind(g) + 0.020d * sind(2.0d * g));
        var eps = 23.439d - 0.00000036d * d;
        var sunRa = w360(atan2d(cosd(eps) * sind(sunLon), cosd(sunLon)));
        var sunDec = asind(sind(eps) * sind(sunLon));
        var eqtMin = w180(q - sunRa) * 4.0d;              // equation of time, minutes

        var utcH = (unix % 86400).toDouble() / 3600.0d;
        var meanH = w360((utcH + lon / 15.0d) * 15.0d) / 15.0d;                  // mean solar time
        var trueH = w360((utcH + lon / 15.0d + eqtMin / 60.0d) * 15.0d) / 15.0d; // sundial time
        var sunH = (trueH - 12.0d) * 15.0d;               // hour angle, -180..180, 0 = solar noon

        // Sun elevation above the horizon now, and today's maximum (at solar noon).
        var sunAlt = asind(sind(lat) * sind(sunDec) + cosd(lat) * cosd(sunDec) * cosd(sunH));
        var peak = 90.0d - (lat.toDouble() - sunDec).abs();

        var hRise = hourAngle(-0.833d, lat, sunDec);
        var hGold = hourAngle(6.0d, lat, sunDec);
        var hCivil = hourAngle(-6.0d, lat, sunDec);
        var hNaut = hourAngle(-12.0d, lat, sunDec);
        var hAstro = hourAngle(-18.0d, lat, sunDec);

        // Local clock minutes of sunrise / sunset (-1 when the sun does not rise or set).
        var noonUtcH = 12.0d - lon / 15.0d - eqtMin / 60.0d;
        var tzH = tzSec.toDouble() / 3600.0d;
        var riseMin = -1;
        var setMin = -1;
        if (hRise > 0.0d && hRise < 180.0d) {
            riseMin = (w360((noonUtcH - hRise / 15.0d + tzH) * 15.0d) / 15.0d * 60.0d + 0.5d).toNumber() % 1440;
            setMin = (w360((noonUtcH + hRise / 15.0d + tzH) * 15.0d) / 15.0d * 60.0d + 0.5d).toNumber() % 1440;
        }

        // Minutes until the next horizon crossing.
        var up = (sunH > -hRise) && (sunH < hRise);
        var toNext;
        if (up) {
            toNext = hRise - sunH;
        } else if (sunH >= hRise) {
            toNext = 360.0d - sunH - hRise;
        } else {
            toNext = -hRise - sunH;
        }

        // Lunar periodic ephemeris: phase, local hour angle, apparent altitude.
        var lunar = Lunar.position(unix, lat, lon);

        return {
            :sunH => sunH.toFloat(),
            :alt => sunAlt.toFloat(),
            :peak => peak.toFloat(),
            :trueMin => (trueH * 60.0d).toNumber() % 1440,
            :meanMin => (meanH * 60.0d).toNumber() % 1440,
            :hRise => hRise.toFloat(),
            :hGold => hGold.toFloat(),
            :hCivil => hCivil.toFloat(),
            :hNaut => hNaut.toFloat(),
            :hAstro => hAstro.toFloat(),
            :riseMin => riseMin,
            :setMin => setMin,
            :sunUp => up,
            :nextMin => (toNext / 15.0d * 60.0d).toNumber(),
            :moonH => lunar[:hourAngle],
            :moonAlt => lunar[:altitude],
            :moonUp => lunar[:horizon] > 0,
            :moonAz => lunar[:azimuth],
            :illum => lunar[:illumination],
            :waxing => lunar[:waxing],
            :south => lat < 0.0
        };
    }
}
