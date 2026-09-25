import Toybox.Lang;

// Bright text and fixed icon accents on true black (AMOLED).
module Pal {
    const INK = 0xF1EBDF;
    const DIM = 0xE2DDD4;      // small labels: warm off-white, never dark grey
    const DIMMER = 0xDCD8D0;   // units and secondary labels remain readable
    const CORAL = 0xFF7B6B;   // body
    const MINT = 0x5FD6A4;    // movement
    const SKY = 0x7CB6FF;     // environment
    const GOLD = 0xFFC46B;    // sun / solar time
    const SUN = 0xFFDB8E;
    const HALO = 0x33271A;    // GOLD at ~20% over black
    const RISE_ICON = 0xFF995C; // orange arrow / horizon beneath a yellow sun
    const SET_ICON = 0x7CB6FF;  // blue arrow / horizon beneath a yellow sun
    const TRACK = 0x2C2C31;
    const TICK = 0x6D685E;
    const PEAK_ICON = 0xFFC46B;   // noon-peak label at the top of the ring
    const PEAK_TEXT = 0xFFE0A0;
    const ALT_ICON = 0xD9A95C;    // current sun elevation in the solar line
    const ALT_TEXT = 0xFFE0A0;
    const MOON_LIT = 0xE4E6F6;
    const MOON_DARK = 0x262940;


    function scale(c as Number, f as Float) as Number {
        var r = (((c >> 16) & 0xFF) * f).toNumber();
        var g = (((c >> 8) & 0xFF) * f).toNumber();
        var b = ((c & 0xFF) * f).toNumber();
        return (r << 16) | (g << 8) | b;
    }

    function lerp(c1 as Number, c2 as Number, f as Float) as Number {
        var r1 = (c1 >> 16) & 0xFF;
        var g1 = (c1 >> 8) & 0xFF;
        var b1 = c1 & 0xFF;
        var r = (r1 + (((c2 >> 16) & 0xFF) - r1) * f + 0.5).toNumber();
        var g = (g1 + (((c2 >> 8) & 0xFF) - g1) * f + 0.5).toNumber();
        var b = (b1 + ((c2 & 0xFF) - b1) * f + 0.5).toNumber();
        return (r << 16) | (g << 8) | b;
    }
}

module Fmt {

    // 60690 -> "60,690"
    function thousands(n as Number) as String {
        var neg = n < 0;
        var chars = (neg ? -n : n).format("%d").toCharArray();
        var len = chars.size();
        var out = "";
        for (var i = 0; i < len; i++) {
            if (i > 0 && (len - i) % 3 == 0) {
                out += ",";
            }
            out += chars[i];
        }
        return neg ? "-" + out : out;
    }

    // Minutes after midnight -> "7:07" (12 h, no suffix) or "19:07" (24 h).
    function clock(mins as Number, is24 as Boolean) as String {
        var m = ((mins % 1440) + 1440) % 1440;
        var h = m / 60;
        var mm = m % 60;
        if (!is24) {
            h = h % 12;
            if (h == 0) {
                h = 12;
            }
            return h.format("%d") + ":" + mm.format("%02d");
        }
        return h.format("%02d") + ":" + mm.format("%02d");
    }

    // 190 -> "3h 10m", 45 -> "45m"
    function duration(mins as Number) as String {
        if (mins < 60) {
            return mins.format("%d") + "m";
        }
        return (mins / 60).format("%d") + "h " + (mins % 60).format("%d") + "m";
    }

    // Weather observation age: "30m", "2h"
    function age(mins as Number) as String {
        if (mins < 90) {
            return mins.format("%d") + "m";
        }
        return ((mins + 30) / 60).format("%d") + "h";
    }

    function round(x as Numeric) as Number {
        var f = x.toFloat();
        return (f < 0.0) ? (f - 0.5).toNumber() : (f + 0.5).toNumber();
    }
}
