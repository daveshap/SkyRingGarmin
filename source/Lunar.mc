import Toybox.Lang;
import Toybox.Math;

// Local-only lunar ephemeris. Meeus, Astronomical Algorithms, chapter 47.
// Coefficient tables 47.A/B are mathematical data; checked against PyMeeus.
// UTC approximates UT1 (sub-second difference); TT = UTC + 69.184 s for the
// current leap-second era. Marker brightness uses a conventional level sea
// horizon, lunar semidiameter and standard refraction, not terrain/weather.
module Lunar {
    const RAD = 0.017453292519943295d;
    const TT_MINUS_UTC = 69.184d;
    var LR as Array = [
        [0, 0, 1, 0, 6288774, -20905355],
        [2, 0, -1, 0, 1274027, -3699111],
        [2, 0, 0, 0, 658314, -2955968],
        [0, 0, 2, 0, 213618, -569925],
        [0, 1, 0, 0, -185116, 48888],
        [0, 0, 0, 2, -114332, -3149],
        [2, 0, -2, 0, 58793, 246158],
        [2, -1, -1, 0, 57066, -152138],
        [2, 0, 1, 0, 53322, -170733],
        [2, -1, 0, 0, 45758, -204586],
        [0, 1, -1, 0, -40923, -129620],
        [1, 0, 0, 0, -34720, 108743],
        [0, 1, 1, 0, -30383, 104755],
        [2, 0, 0, -2, 15327, 10321],
        [0, 0, 1, 2, -12528, 0],
        [0, 0, 1, -2, 10980, 79661],
        [4, 0, -1, 0, 10675, -34782],
        [0, 0, 3, 0, 10034, -23210],
        [4, 0, -2, 0, 8548, -21636],
        [2, 1, -1, 0, -7888, 24208],
        [2, 1, 0, 0, -6766, 30824],
        [1, 0, -1, 0, -5163, -8379],
        [1, 1, 0, 0, 4987, -16675],
        [2, -1, 1, 0, 4036, -12831],
        [2, 0, 2, 0, 3994, -10445],
        [4, 0, 0, 0, 3861, -11650],
        [2, 0, -3, 0, 3665, 14403],
        [0, 1, -2, 0, -2689, -7003],
        [2, 0, -1, 2, -2602, 0],
        [2, -1, -2, 0, 2390, 10056],
        [1, 0, 1, 0, -2348, 6322],
        [2, -2, 0, 0, 2236, -9884],
        [0, 1, 2, 0, -2120, 5751],
        [0, 2, 0, 0, -2069, 0],
        [2, -2, -1, 0, 2048, -4950],
        [2, 0, 1, -2, -1773, 4130],
        [2, 0, 0, 2, -1595, 0],
        [4, -1, -1, 0, 1215, -3958],
        [0, 0, 2, 2, -1110, 0],
        [3, 0, -1, 0, -892, 3258],
        [2, 1, 1, 0, -810, 2616],
        [4, -1, -2, 0, 759, -1897],
        [0, 2, -1, 0, -713, -2117],
        [2, 2, -1, 0, -700, 2354],
        [2, 1, -2, 0, 691, 0],
        [2, -1, 0, -2, 596, 0],
        [4, 0, 1, 0, 549, -1423],
        [0, 0, 4, 0, 537, -1117],
        [4, -1, 0, 0, 520, -1571],
        [1, 0, -2, 0, -487, -1739],
        [2, 1, 0, -2, -399, 0],
        [0, 0, 2, -2, -381, -4421],
        [1, 1, 1, 0, 351, 0],
        [3, 0, -2, 0, -340, 0],
        [4, 0, -3, 0, 330, 0],
        [2, -1, 2, 0, 327, 0],
        [0, 2, 1, 0, -323, 1165],
        [1, 1, -1, 0, 299, 0],
        [2, 0, 3, 0, 294, 0],
        [2, 0, -1, -2, 0, 8752]
    ];
    var B as Array = [
        [0, 0, 0, 1, 5128122],
        [0, 0, 1, 1, 280602],
        [0, 0, 1, -1, 277693],
        [2, 0, 0, -1, 173237],
        [2, 0, -1, 1, 55413],
        [2, 0, -1, -1, 46271],
        [2, 0, 0, 1, 32573],
        [0, 0, 2, 1, 17198],
        [2, 0, 1, -1, 9266],
        [0, 0, 2, -1, 8822],
        [2, -1, 0, -1, 8216],
        [2, 0, -2, -1, 4324],
        [2, 0, 1, 1, 4200],
        [2, 1, 0, -1, -3359],
        [2, -1, -1, 1, 2463],
        [2, -1, 0, 1, 2211],
        [2, -1, -1, -1, 2065],
        [0, 1, -1, -1, -1870],
        [4, 0, -1, -1, 1828],
        [0, 1, 0, 1, -1794],
        [0, 0, 0, 3, -1749],
        [0, 1, -1, 1, -1565],
        [1, 0, 0, 1, -1491],
        [0, 1, 1, 1, -1475],
        [0, 1, 1, -1, -1410],
        [0, 1, 0, -1, -1344],
        [1, 0, 0, -1, -1335],
        [0, 0, 3, 1, 1107],
        [4, 0, 0, -1, 1021],
        [4, 0, -1, 1, 833],
        [0, 0, 1, -3, 777],
        [4, 0, -2, 1, 671],
        [2, 0, 0, -3, 607],
        [2, 0, 2, -1, 596],
        [2, -1, 1, -1, 491],
        [2, 0, -2, 1, -451],
        [0, 0, 3, -1, 439],
        [2, 0, 2, 1, 422],
        [2, 0, -3, -1, 421],
        [2, 1, -1, 1, -366],
        [2, 1, 0, 1, -351],
        [4, 0, 0, 1, 331],
        [2, -1, 1, 1, 315],
        [2, -2, 0, -1, 302],
        [0, 0, 1, 3, -283],
        [2, 1, 1, -1, -229],
        [1, 1, 0, -1, 223],
        [1, 1, 0, 1, 223],
        [0, 1, -2, -1, -220],
        [2, 1, -1, -1, -220],
        [1, 0, 1, 1, -185],
        [2, -1, -2, -1, 181],
        [0, 1, 2, 1, -177],
        [4, 0, -2, -1, 176],
        [4, -1, -1, -1, 166],
        [1, 0, 1, -1, -164],
        [4, 0, 1, -1, 132],
        [1, 0, -1, -1, -119],
        [4, -1, 0, -1, 115],
        [2, -2, 0, 1, 107]
    ];

    function sinD(x) { return Math.sin(x.toDouble() * RAD).toDouble(); }
    function cosD(x) { return Math.cos(x.toDouble() * RAD).toDouble(); }
    function atanD(y, x) { return (Math.atan2(y, x) / RAD).toDouble(); }
    function asinD(x) {
        var v = x.toDouble();
        if (v > 1.0d) { v = 1.0d; }
        if (v < -1.0d) { v = -1.0d; }
        return (Math.asin(v) / RAD).toDouble();
    }
    function wrap(x) {
        var v = x.toDouble();
        var a = v - (v / 360.0d).toLong() * 360.0d;
        return (a < 0.0d) ? a + 360.0d : a;
    }
    function signed(x) { var a = wrap(x); return a > 180.0d ? a - 360.0d : a; }

    // Geocentric equatorial coordinates of date, distance, ecliptic phase.
    function coordinates(unix) as Array {
        var d = (unix.toDouble() + TT_MINUS_UTC) / 86400.0d - 10957.5d;
        var t = d / 36525.0d;
        var t2 = t * t;
        var lp = wrap(218.3164477d + 481267.88123421d*t - 0.0015786d*t2 + t2*t/538841.0d - t2*t2/65194000.0d);
        var dd = wrap(297.8501921d + 445267.1114034d*t - 0.0018819d*t2 + t2*t/545868.0d - t2*t2/113065000.0d);
        var m = wrap(357.5291092d + 35999.0502909d*t - 0.0001536d*t2 + t2*t/24490000.0d);
        var mp = wrap(134.9633964d + 477198.8675055d*t + 0.0087414d*t2 + t2*t/69699.0d - t2*t2/14712000.0d);
        var f = wrap(93.2720950d + 483202.0175233d*t - 0.0036539d*t2 - t2*t/3526000.0d + t2*t2/863310000.0d);
        var e = 1.0d - 0.002516d*t - 0.0000074d*t2;
        var sl = 0.0d; var sr = 0.0d; var sb = 0.0d;
        for (var i=0; i<LR.size(); i++) {
            var r = LR[i] as Array;
            var arg = r[0]*dd + r[1]*m + r[2]*mp + r[3]*f;
            var fac = r[1].abs() == 2 ? e*e : (r[1] == 0 ? 1.0d : e);
            sl += r[4]*fac*sinD(arg); sr += r[5]*fac*cosD(arg);
        }
        for (var j=0; j<B.size(); j++) {
            var b = B[j] as Array;
            var argb = b[0]*dd + b[1]*m + b[2]*mp + b[3]*f;
            var facb = b[1].abs() == 2 ? e*e : (b[1] == 0 ? 1.0d : e);
            sb += b[4]*facb*sinD(argb);
        }
        var a1 = 119.75d + 131.849d*t;
        sl += 3958.0d*sinD(a1) + 1962.0d*sinD(lp-f) + 318.0d*sinD(53.09d + 479264.290d*t);
        sb += -2235.0d*sinD(lp) + 382.0d*sinD(313.45d+481266.484d*t)
            + 175.0d*sinD(a1-f) + 175.0d*sinD(a1+f) + 127.0d*sinD(lp-mp) - 115.0d*sinD(lp+mp);
        var lon = wrap(lp + sl/1000000.0d); var lat = sb/1000000.0d;
        var dist = 385000.56d + sr/1000.0d;
        var eps = 23.439291111d - 0.013004167d*t - 0.000000164d*t2 + 0.000000504d*t2*t;
        var ra = wrap(atanD(sinD(lon)*cosD(eps) - sinD(lat)/cosD(lat)*sinD(eps), cosD(lon)));
        var dec = asinD(sinD(lat)*cosD(eps) + cosD(lat)*sinD(eps)*sinD(lon));
        var l0 = wrap(280.46646d + 36000.76983d*t + 0.0003032d*t2);
        var sunLon = l0 + (1.914602d-0.004817d*t-0.000014d*t2)*sinD(m)
            + (0.019993d-0.000101d*t)*sinD(2.0d*m) + 0.000289d*sinD(3.0d*m);
        var phase = wrap(lon-sunLon);
        var elongCos = cosD(lat)*cosD(phase);
        var ratio = dist/149597870.7d;
        var phaseCos = (ratio-elongCos) / Math.sqrt(1.0d+ratio*ratio-2.0d*ratio*elongCos);
        return [ra, dec, dist, (1.0d+phaseCos)/2.0d, phase < 180.0d];
    }

    function position(unix, lat, lon) as Dictionary {
        var c = coordinates(unix);
        var d = unix.toDouble()/86400.0d-10957.5d;
        var t = d/36525.0d;
        var h = signed(280.46061837d+360.98564736629d*d+0.000387933d*t*t-t*t*t/38710000.0d+lon-c[0]);
        var dec = c[1];
        var geoAlt = asinD(sinD(lat)*sinD(dec)+cosD(lat)*cosD(dec)*cosD(h));
        var pi = asinD(6378.14d/c[2]);
        // Spherical altitude parallax is sufficient for a watch icon, <0.01 deg.
        var topoAlt = geoAlt - asinD(sinD(pi)*cosD(geoAlt));
        var refr = 0.0d;
        if (topoAlt > -1.0d && topoAlt < 89.0d) {
            var bend = topoAlt + 10.3d/(topoAlt+5.11d);
            refr = 1.02d/60.0d * cosD(bend)/sinD(bend);
        }
        var az = wrap(atanD(sinD(h), cosD(h)*sinD(lat)-sinD(dec)/cosD(dec)*cosD(lat))+180.0d);
        return {:hourAngle=>h.toFloat(), :altitude=>(topoAlt+refr).toFloat(),
            :azimuth=>az.toFloat(), :illumination=>c[3].toFloat(), :waxing=>c[4],
            :horizon=>(geoAlt - (0.7275d*pi-0.566666667d)).toFloat()};
    }

}
