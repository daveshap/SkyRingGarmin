# History and readability release — September 25, 2026

The owner installed this build on a Forerunner 965 and confirmed that it works, including stress history, on September 25, 2026. This publication preserves that tested runtime and its resources. The previous published build remains available at commit `78f1a1ac774af6b008278f3e35150477a5e17a61` for rollback. See [VALIDATION.md](VALIDATION.md) for the scope of that confirmation and the development checks.

## What changed and why

- Replace the stress gauge with a four-hour colored history, matching the HR trace. The large current-stress number already shows the current level; the trace adds context about how that level changed.
- Remove the entire weather-age, battery, and elevation footer, including the battery/elevation reads. These fields were distracting and crowded the lower display. They are not relocated; floors climbed stays as the preferred daily climbing metric.
- Use the space for larger native text and icons, larger charts, and wider vertical spacing. Text requests increase from 88/44/38/32/24/22/20 to 92/48/42/36/26/24/22 pixels; icon cells increase from 26/20 to 28/22 pixels. The allocated HR chart area grows from 76 × 17 to 84 × 25 pixels; the new stress chart uses the same layout area.

HR and stress use a shared four-hour window: 24 ten-minute averages, oldest at the left and newest at the right. They rebuild together approximately every five minutes during ordinary full refreshes and after clock rollback. Each native history scan is newest-first and capped at 1,024 samples. Missing data stays a gap; valid stress zero stays zero. The held current stress reading is never copied into the historical chart.

Both vertical axes adjust to the available values, with a minimum span of 12 bpm for HR and 20 points for stress. The absolute color thresholds below do not move with those axes. The charts need at least two populated buckets to draw, and lines connect only adjacent populated buckets. Isolated older buckets without a neighboring measurement may have no visible mark; the most recent bucket gets an endpoint dot when the chart passes that two-bucket minimum. A blank trace therefore need not mean that the current reading is unavailable.

The ring, Sun/Moon calculations, native font family, icon identity and colors, seven-day goal colors, recovery confirmation, and wake-only lifecycle remain as in the preceding color/recovery build. Weather age is no longer visible but still controls stale-weather styling internally. The enlarged weather row can omit optional high/low, then UV/rain, when necessary to fit; temperature/conditions and humidity take priority.

## Color meaning

Colors apply only to the HR trace, stress trace, and seven daily step bars. Icons and numbers keep their existing colors.

| Color | Hex | HR trace, BPM | Stress trace, rounded mean score |
| --- | --- | --- | --- |
| Purple | `#A64DFF` | Below 60 | 0–14 |
| Blue | `#2D7DFF` | 60–under 70 | 15–25 |
| Green | `#19E68C` | 70–under 90 | 26–50 |
| Yellow | `#FFE338` | 90–under 110 | 51–65 |
| Orange | `#FF8A22` | 110–under 130 | 66–75 |
| Red | `#FF4048` | 130+ | 76–100 |

HR colors use the ten-minute bucket averages; stress colors use rounded ten-minute averages. Both are independent of the automatic height scale. Adjacent half-segments take their nearest bucket's color. Gaps remain gaps; invalid HR samples cannot become a false resting point. These are fixed display bands rather than personalized training zones. Purple stress means a very low score, not an inferred sleep stage. A measured stress zero can appear as a purple trace.

Daily step bars are saturated green below the recorded goal and yellow at or above it. Each past bar uses that date's own `ActivityMonitor.History.stepGoal`; today uses `ActivityMonitor.Info.stepGoal`. Missing or invalid goals remain green, without inventing an achievement. Missing days remain gray dots. There are no extra goal numbers. Today remains the rightmost bar, and height still represents daily step count relative to the largest visible day.

## Recovery confirmation and its limits

The owner observed a brief `1m` after waking even though Garmin's built-in recovery screen had been at zero. The baseline already clears the displayed value and fetches the native complication on wake; it has no local recovery countdown, default-one value, or persistent recovery cache. The native complication reports minutes but exposes no source timestamp. A transient native reading is plausible; it has not been proved on the watch.

The face displays native zero immediately. A first positive wake reading briefly shows `--` until a later normal awake frame, about one second later. It schedules at most two extra recovery-only reads, near +1s and +3s. Normal minute/callback reads satisfy those deadlines; late frames do not generate a catch-up loop. A genuine `1m` still displays as `1m` after confirmation. Missing data remains `--`.

This is a bounded confirmation/refresh mitigation, not proof of a firmware fix. If Garmin keeps returning a stale positive value, the face cannot distinguish it from a genuine value. Using the whole-hour `ActivityMonitor.Info.timeToRecovery` as a zero override would erase valid final-hour minutes, so that alternative was rejected.

There are no added timers, forced updates, background services, storage writes, or changes to wake-only behavior. All rechecks occur after the existing awake guard. Normal rendering adds a bounded number of color changes and line segments; device battery use has not been measured.

## Build, rollback, and follow-up checks

1. Keep your working source folder and device-built `SkyRing.prg` as the rollback copy.
2. Clone or download this revision into a clean folder and open the folder containing `manifest.xml` in VS Code.
3. Build for **Forerunner 965 / fr965**, with your existing developer key and `monkey.jungle`.
4. Install using the same `.prg` filename and application ID as before. Detailed instructions are in [BUILD_WINDOWS.md](BUILD_WINDOWS.md).
5. Confirm that the former WX/battery/elevation footer is gone, text is larger, the remaining rows fit, and sunrise/sunset labels do not collide with the body values. Check the largest step and recovery numbers you normally see.
6. Confirm both colored four-hour traces, current stress still displayed above its trace, and genuine gaps during unavailable stress periods. A measured stress zero must not be treated as missing. Confirm several normal sleep/wake cycles; sleeping stays black.
7. When Garmin's recovery is zero, check that it reads READY after waking. A pending positive read can briefly show `--`; it must not get stuck. Recheck the following morning. When recovery is genuinely positive, confirm that its value returns after approximately one second.
8. Confirm yellow bars against each day's recorded goal, especially if adaptive goals changed. Today is the rightmost bar; a missing goal deliberately cannot turn a bar yellow.

If the blip persists, record whether it lasts less than one second, around three seconds, or longer, and whether the native recovery screen still reads zero. That distinguishes a first-frame transient from a sustained discrepancy without pretending that a minute-valued API has a freshness timestamp.

No prebuilt `.prg` is included: the local generic build is for source checking and is not a device-targeted installable artifact. [VALIDATION.md](VALIDATION.md) records what was and was not executed.

## Simulator finding

The owner saw a current stress value but a blank stress trace in the SDK 9.2.0 simulator, then confirmed that the same build displayed stress history on the physical watch. Current stress and historical stress use separate Garmin sources, so one can be available without the other. A [Garmin forum report](https://forums.garmin.com/developer/connect-iq/f/connect-iq-web-store/441912/emulator-sets-sensor-history-samples-time-into-future) describes simulator history timestamps in the future. This is a plausible explanation for samples being rejected by the four-hour history window, but no raw timestamp log established it for this particular simulator session. No simulator-specific workaround, fabricated history, or diagnostic source changes are included in this release.

## Official API references

- [Recovery complication](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html#COMPLICATION_TYPE_RECOVERY_TIME-const): minute-valued native reading.
- [Complication fields](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications/Complication.html): no observation timestamp.
- [WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html): normal high-power updates.
- [SensorHistory](https://developer.garmin.com/connect-iq/api-docs/Toybox/SensorHistory.html): measured HR and stress history.
- [Activity history](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/History.html): recorded per-day steps and step goals.
- [Activity info](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html): today's step goal and the less precise whole-hour recovery alternative.
