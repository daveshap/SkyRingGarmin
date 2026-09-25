# Architecture and maintenance

## Design intent

SkyRing is a personal glanceable dashboard for the Forerunner 965. It favors stable visual locations, a consistent icon vocabulary, native text, and a handful of meaningful groups. The sky ring adds context without requiring a second screen. The clock is now prominent; the earlier RowWatch prototype prioritized rows more strictly.

The icon palette groups body/recovery in coral, movement in mint, weather in blue, and solar information in gold. Most values are warm off-white. Icons and numbers keep those colors. `ChartColors` supplies fixed saturated display bands for the HR and stress traces, plus green/yellow daily step-goal highlighting. Charts remain tied to adjacent measurements: HR history, stress history, daily steps, and intensity-goal completion.

## Source map

| File | Responsibility |
| --- | --- |
| `source/SkyRingApp.mc` | Garmin application entry point and initial watch-face view. No network/background service. |
| `source/SkyRingView.mc` | Lifecycle callbacks, Garmin data reads, caches, text metrics, drawing, fit rules, icons, and layout constants. |
| `source/WakeState.mc` | Resolve actual display mode; decide when returning to the face requires fresh data. |
| `source/Astro.mc` | Current solar geometry, displayed solar times, ring thresholds, and one current lunar-position call. |
| `source/Lunar.mc` | Current lunar coordinates, phase, hour angle, altitude, azimuth, and horizon test. No future-event search. |
| `source/DaySteps.mc` | Date-based seven-day aggregation, de-duplication, missing-day distinction, and per-date goal association. |
| `source/RecoveryTime.mc` | Recovery-minute formatting and bounded initial-reading confirmation using normal awake frames. |
| `source/ChartColors.mc` | Fixed BPM/stress display bands and goal-met color; no sensor reads or state. |
| `source/HistoryBuckets.mc` | Fixed-size 24-bucket accumulator shared by four-hour HR and stress histories; preserves missing values and measured stress zero. |
| `source/Fmt.mc` | Fixed palette and numerical/time formatting. |
| `resources/fonts/` | Two bitmap **icon** atlases. No bitmap text font. |
| `tools/gen_icons.py` | Source artwork and optional atlas generation using Pillow and Inkscape. |
| `tools/check_rim_positions.js` | Host arithmetic/geometry regression checks using translated production methods. |
| `tools/check_candidate.js` | Host-side source-derived history, drawing, cache, recovery, goal, color, and lifecycle checks; not Garmin VM execution. |
| `tests/` | Date/steps/goals, history buckets, chart colors, wake-state, recovery, and lunar-position regression tests. |

## Display lifecycle

The view extends `WatchUi.WatchFace`. `System.getDisplayMode()` is authoritative when available. Cached visibility/sleep callback flags are only the compatibility fallback; they cannot suppress an actually awake display on the FR965.

- **OFF:** return before drawing, reading sensors, or calculating the sky.
- **LOW_POWER:** clear to black and return. No always-on drawing or partial updates.
- **HIGH_POWER:** refresh when needed and render the full face.

`onShow()` and `onExitSleep()` invalidate the minute and HR-fallback polling caches and request one redraw. A display-mode transition, clock rollback, or gap of more than five seconds between awake frames also invalidates those caches. This catches resumes even when expected callbacks are absent. `onEnterSleep()` requests a clearing update when visible. `onHide()` updates the local visibility state.

Native stress/recovery complication callbacks mark data dirty even while sleeping. They request an update only when awake. The next awake callback rereads the data. There is no timer, animation, scroll loop, GPS subscription, or brightness/timeout override.

`RecoveryReadState.wake(nowSec)` is rearmed by that same existing wake/resume detection; it does not change display mode or wake flags. It holds the first positive native recovery value until a later second, publishes native zero immediately, and schedules at most two recovery-only rereads at approximately +1/+3 seconds. `due()` is checked only after the OFF/LOW_POWER returns and only when neither full refresh nor a dirty complication read ran in that frame. Every result, including null/error, goes through `accept()` so unavailable data cannot cause unbounded polling or preserve an old READY state. Clock rollback restarts the window. No recovery data is persisted.

## Refresh and data ownership

| Data/work | Schedule in this implementation |
| --- | --- |
| Current clock | Read and rendered on each awake update; seconds are not displayed. |
| Location, current astronomy, activity, weather, stress, recovery | Minute cache, invalidated on wake/resume. |
| Stress and recovery notification | Reread on next awake dirty update, even within the same minute. |
| Recovery after wake | At most two extra reads near +1s/+3s on ordinary awake frames; no repeated astronomy/history work. |
| Current HR | Prefer activity's current HR on each awake render. |
| HR fallback | Search up to 32 recent samples, at most every 30 seconds; accept observations no more than five minutes old. |
| Four-hour HR and stress traces | Shared four-hour window, 24 ten-minute averages each; rebuilt together approximately every five minutes during full refreshes and after clock rollback. |
| Stress fallback/hold | Preserve the observation timestamp; expire after 30 minutes without a usable replacement. |
| Moonrise/set or full/new date | No code path remains. |

A cached Garmin weather observation is not a direct live sensor or an app-controlled download. This code has no way to promise when Garmin will obtain a new observation. Refreshing the view only rereads what Garmin currently supplies.

Each chart requests native history newest-first and reads at most 1,024 samples per rebuild. If this cap truncates unusually dense data, older missing buckets remain gaps. The renderer requires at least two populated buckets, joins only adjacent populated buckets, and adds an endpoint dot only for a populated latest bucket. Consequently isolated older points may have no visible mark. Both charts use measured history only; the held current stress number is never inserted into the trace. Battery and elevation reads were removed with the footer. Weather observation age remains an internal stale-style input. Actual runtime cost, the full render cost, and battery impact still need FR965 profiling. Removing the known multi-day lunar search does not establish an unlimited rendering budget.

## Location and units

Location preference is: Garmin weather observation position, activity's current location, saved location, then a longitude estimate from standard time-zone offset. The face does not start GPS. Weather-station coordinates may differ from the wearer's exact position. Saved coordinates have no age/quality indicator; a trip can leave the old location in use until Garmin supplies another.

`validDeg()` rejects non-numeric coordinates, near-pole/antimeridian extremes, and `(0,0)` as unavailable. This is a practical guard against firmware placeholders, not worldwide geographic support. A real observation near those excluded values would also be suppressed.

The only current persistent storage item used by the face is `loc`, a latitude/longitude pair. It is rewritten when the saved value is absent or either coordinate changes by more than 0.1 degrees. An accepted current coordinate is used immediately even below that persistence threshold. It stays on the watch; the project makes no network requests. Old versions' lunar-event keys are not read by this build.

Without a usable position, latitude-dependent markers and sunrise/set graphics are suppressed; the ring is neutral and the solar-time estimate is explicitly marked. Time-zone changes affect civil labels, not physical Sun/Moon position. Temperature units follow Garmin settings; the clock follows 12/24-hour preference. English is the only declared language.

## Permissions and native sources

The manifest requests `SensorHistory`, `Positioning`, and `ComplicationSubscriber`. These support historical readings, access to existing location data, and native stress/recovery notifications. There is no `Communications` or background permission. Registration/read failures for complications lead to fallback or unavailable readings, not an external fetch.

The full per-element API and formatting details are in [DISPLAY_GUIDE.md](DISPLAY_GUIDE.md). Missing data is generally `--`, incomplete weekly step history is `7d*`, and unknown weather is `?`. These meanings must remain distinct from measured zero.

## Layout and fonts

The layout is specific to 454 × 454 pixels. Ring centreline radius is 220 with a 12-pixel stroke; markers use radius 214 with a maximum 12-pixel backing disc, keeping them within the 227-pixel display radius. Inner content checks use radius 211. The footer is removed. Baselines are clock y=149, solar detail y=181, body values y=235, steps y=314, intensity/calories/floors y=352, and weather y=390. HR and stress charts reserve an 84 × 25-pixel layout area at y=248–273 (previously 76 × 17 pixels for HR). The drawable trace depends on populated adjacent buckets; the allocated width is not a promise of an uninterrupted edge-to-edge line.

Text uses native `RobotoCondensedRegular` with `RobotoRegular` fallback. The view requests sizes 92, 48, 42, 36, 26, 24, and 22 pixels and measures ascent and text width. A built-in-font fallback exists if vector font lookup fails; its appearance is not validated across devices. Identifiers such as `fN42` or `icons22` are legacy names: actual text/icon sizes increased during readability work.

Main/small bitmap icon cells are 28/22 pixels. The atlas filenames remain `icons22` and `icons16`. Sunrise/sunset combine separate colored arrow/horizon and sun layers. The moon is drawn geometrically from current phase, not a fixed atlas glyph.

Fit rules prioritize primary readings: tighten spacing and history-chart width first, select smaller numeric fonts where implemented, then omit optional weather details. With the larger type and lower weather row, high/low may disappear more often; temperature/conditions and humidity retain priority over UV/rain. The display guide records the exact omissions. Do not use a generated preview to claim Garmin font metrics or device rendering have passed.

## Changes to preserve

1. Keep actual display mode authoritative and all data work behind the awake guard.
2. Reuse the native text path; changing bitmap icons does not justify replacing text fonts.
3. Keep missing values distinct from zero and preserve observation ages.
4. Avoid whole-day/multi-day numerical searches in a display callback. Measure the cold-cache path, not just warm-cache updates.
5. Keep lunar current position independent of solar horizon colors and civil time-zone labels.
6. Verify new data fields on the target firmware/API instead of assuming every built-in Garmin screen has a public equivalent.
7. Build with `monkey.jungle`; use `monkey-tests.jungle` only for native test builds. The release source path excludes tests.
8. Keep signing keys, local settings, generated binaries, and private diagnostic logs out of commits.

## References

- [Garmin WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html)
- [System display mode](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html)
- [Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html)
- [ActivityMonitor](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html)
- [SensorHistory](https://developer.garmin.com/connect-iq/api-docs/Toybox/SensorHistory.html)
- [Graphics and native fonts](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html)
- [Local astronomy conventions and references](LUNAR_CALCULATIONS.md)
