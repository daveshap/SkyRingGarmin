import Toybox.Lang;

// Display Garmin ActivityMonitor's raw whole hours. No complication minutes,
// private countdown, wake-time suppression, or source arbitration.
module RecoveryTime {
    function validHours(value) {
        return (value instanceof Number && value >= 0) ? value : null;
    }

    function displayHours(hours) as Dictionary {
        hours = validHours(hours);
        if (hours == null) {
            return { :value => "--", :unit => null, :label => "RECOVERY" };
        }
        // READY is the requested caption for Garmin reporting zero whole hours.
        // Keep 0h visible: the underlying source remains hour-resolution data.
        return { :value => hours.format("%d"), :unit => "h", :label => (hours == 0) ? "READY" : "RECOVERY" };
    }
}
