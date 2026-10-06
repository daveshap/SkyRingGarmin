# Weather contrast, rotation, and READY — September 28, 2026

**Historical September record.** Its timer-free rotation and wake-reset descriptions were superseded by the October 6 [weather-rotation refactor](WEATHER_ROTATION_UPDATE.md). The colors, native data sources, and READY presentation remain; current lifecycle and scheduling are described in the new guide.

This update builds on the corrected weather-color package and completes the September 28 release. The owner reported that the current build "all seems to work" and requested publication. It adds three small changes.

## More contrast

Humidity, dew-point, and UV numbers now blend 65% toward warm off-white, increased from 30%. Their icons and the UV label keep saturated identity/risk colors. Temperature text and stale-data handling retain their existing behavior.

## READY restored

Zero from Garmin's native hourly recovery source displays `0h` with the `READY` caption. Positive values show their raw hours with `RECOVERY`; missing data stays `--` with `RECOVERY`. Recovery complications, minute calculations, retries, and first-frame blanking remain removed.

## Rotation survives delayed frames

The prior rotation reset after every frame gap over five seconds. Its `elapsed % 4` phase could also keep selecting the same reading when callbacks arrived four seconds or a minute apart. These are reproducible weaknesses, though no device callback trace establishes which caused the reported stall.

The slot now tracks the displayed selection and its start time. Once that selection has had two seconds, the next awake frame switches once and starts a new dwell. This preserves the two-second cadence under normal updates, avoids catch-up loops, and prevents delayed frames from repeatedly choosing the same phase. Duplicate callbacks cannot accelerate rotation. An observed show/wake transition or clock rollback resets to humidity. Data refreshes and frame gaps do not reset it. If only one moisture reading is available, it stays visible.

Garmin documents once-per-second updates during the brief high-power window and once-per-minute updates during low power. No timer, forced redraw loop, always-on behavior, or display-timeout override is added. Rotation runs only through existing awake drawing. It cannot animate while Garmin supplies no frames; waking the display resumes it.

Reference: [Garmin WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html).

## Status

The September 28 publication preserves the runtime and resources from the owner-confirmed polish build. Generic SDK builds and source-derived checks passed; the 26 native test functions compiled but were not executed in the Garmin VM. The local FR965 device profile remains unavailable. The owner's confirmation establishes their observed experience with this build; it does not quantify battery use, runtime margin, or every firmware/data edge case. See [VALIDATION.md](VALIDATION.md) for the exact scope and [BUILD_WINDOWS.md](BUILD_WINDOWS.md) for an `fr965` build using the existing developer key.
