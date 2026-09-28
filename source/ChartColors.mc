import Toybox.Lang;

// Colors for charts, UV risk, and weather artwork. HR/stress bands are display
// choices; UV uses the standard EPA/NWS exposure categories.
module ChartColors {
    const PURPLE = 0xA64DFF;
    const BLUE = 0x2D7DFF;
    const GREEN = 0x19E68C;
    const YELLOW = 0xFFE338;
    const ORANGE = 0xFF8A22;
    const RED = 0xFF4048;
    const WEATHER_SUN = 0xFFF000;   // saturated lemon; matches Pal.SUN
    const WEATHER_MOON = 0xBD80FF;  // vivid lavender
    const WEATHER_CLOUD = 0xDCEBFF; // bright cool silver, also used by cloud overlays
    const WEATHER_FOG = 0x33E1C6;   // vivid teal
    const WEATHER_RAIN = 0x258CFF;  // saturated blue
    const WEATHER_SNOW = 0x26E6FF;  // icy cyan
    const WEATHER_WIND = 0x34F0A0;  // bright mint
    const WEATHER_HUMIDITY = 0x329BFF; // vivid blue RH droplet; distinct from dew point

    // Glyph selection still comes from Garmin conditions and the existing
    // solar day/night check. These colors affect weather artwork only.
    // String == tests identity in Monkey C; compare contents across modules.
    function condition(glyph as String) as Number {
        if (glyph.equals("c") || glyph.equals("p") || glyph.equals("t")) { return WEATHER_SUN; }
        if (glyph.equals("n") || glyph.equals("q")) { return WEATHER_MOON; }
        if (glyph.equals("C")) { return WEATHER_CLOUD; }
        if (glyph.equals("f")) { return WEATHER_FOG; }
        if (glyph.equals("r")) { return WEATHER_RAIN; }
        if (glyph.equals("s")) { return WEATHER_SNOW; }
        if (glyph.equals("w")) { return WEATHER_WIND; }
        return Pal.DIMMER;
    }

    // The caller passes the same rounded whole index shown on screen. Missing
    // data is neutral, not a low-risk green zero. UV has no upper category cap.
    function uvIndex(shown) as Number {
        if (!(shown instanceof Number) || shown < 0) { return Pal.DIMMER; }
        if (shown <= 2) { return GREEN; }
        if (shown <= 5) { return YELLOW; }
        if (shown <= 7) { return ORANGE; }
        if (shown <= 10) { return RED; }
        return PURPLE;
    }

    // Use the measured BPM (including averaged samples), never the sparkline's
    // auto-scaled height, so the same rate has the same color on every day.
    function heartRate(bpm) as Number {
        if (bpm == null || bpm <= 0) { return Pal.TRACK; }
        if (bpm < 60) { return PURPLE; }
        if (bpm < 70) { return BLUE; }
        if (bpm < 90) { return GREEN; }
        if (bpm < 110) { return YELLOW; }
        if (bpm < 130) { return ORANGE; }
        return RED;
    }

    // Garmin rest is 0-25. Purple is only a visual subdivision of that range;
    // a low stress reading does not identify sleep or a sleep stage.
    // All filled meter segments use this one current-reading color.
    function stress(level) as Number {
        if (level == null || level < 0 || level > 100) { return Pal.TRACK; }
        var shown = Fmt.round(level); // Match the whole-number stress readout.
        if (shown < 15) { return PURPLE; }
        if (shown <= 25) { return BLUE; }
        if (shown <= 50) { return GREEN; }
        if (shown <= 65) { return YELLOW; }
        if (shown <= 75) { return ORANGE; }
        return RED;
    }

    // A missing/invalid goal does not mean achieved. Only the goal reported for
    // this exact date can turn its bar yellow; missing step days remain grey.
    function steps(count, goal) as Number {
        if (count == null || count < 0) { return Pal.TRACK; }
        if (goal instanceof Number && goal > 0 && count >= goal) { return YELLOW; }
        return GREEN;
    }
}
