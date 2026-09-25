import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Native Garmin data only. No network service, API key, or background fetch.
class SkyRingApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        return [new SkyRingView()];
    }
}
