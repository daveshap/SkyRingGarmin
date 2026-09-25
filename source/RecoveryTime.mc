import Toybox.Lang;

module RecoveryTime {
    // Garmin's recovery complication reports minutes, not whole hours. Keep
    // the final hour in minutes so 1 minute does not misleadingly become 1h.
    function display(minutes) as Dictionary {
        if (minutes == null || minutes < 0) {
            return { :value => "--", :unit => null, :label => "RECOVERY" };
        }
        var m = minutes.toNumber();
        if (m == 0) {
            return { :value => "0", :unit => "h", :label => "READY" };
        }
        if (m < 60) {
            return { :value => m.format("%d"), :unit => "m", :label => "RECOVERY" };
        }
        return { :value => ((m + 59) / 60).format("%d"), :unit => "h", :label => "RECOVERY" };
    }
}
