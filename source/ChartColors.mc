import Toybox.Lang;

// Fixed, saturated chart colors. These are display bands, not personalized HR
// zones or clinical thresholds. Icons and numeric text keep their own palette.
module ChartColors {
    const PURPLE = 0xA64DFF;
    const BLUE = 0x2D7DFF;
    const GREEN = 0x19E68C;
    const YELLOW = 0xFFE338;
    const ORANGE = 0xFF8A22;
    const RED = 0xFF4048;

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
