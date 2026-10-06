# Findings, removed experiments, and known limits

This records what we learned while moving from RowWatch to SkyRing and repairing the sky calculations. It distinguishes reported device behavior, source changes, and checks that have not been run on the target watch. The working `main` publication includes the **Moon horizon correction** delivered September 30 and approved for publication October 2. The October 6 candidate adds side-by-side clocks and a humidity/dew-point rotation refactor; the latter still needs watch validation. It retains the September 28 weather/recovery polish: native whole-hour recovery with READY at zero, vivid layered weather icons, UV risk colors, and alternating humidity/dew point. It retains colored HR/stress histories, goal-colored step bars, larger native text/icons, and no bottom status footer. Current Sun/Moon positions and Moon phase remain; lunar event predictions do not.

## What has actually been verified

| Evidence | What it establishes | What it does not establish |
|---|---|---|
| User installed earlier RowWatch builds on a Forerunner 965 and reported that they worked | The development, signing, sideloading, and basic dashboard approach worked on the user's watch | It does not validate later SkyRing changes |
| User supplied SkyRing screenshots and feedback after font, spacing, and lunar changes | Those revisions rendered; the native-font revision looked better to the user | Screenshots cannot prove refresh behavior, numerical accuracy, or battery life |
| User reported intermittent black screens after sleep | There was a real wake/display problem in an earlier revision | No instrumented device trace established one exclusive cause |
| Garmin reported a watchdog stack through `onUpdate → refresh → refreshLunarEvents → events → position → coordinates` | The old synchronous lunar-event calculation exceeded the callback's execution allowance | It does not establish an exact watchdog threshold or blame `cosD()` itself |
| User reported lunar rise/set fields blanking after the bounded-worker replacement | That replacement did not meet the user's reliability expectations | The report does not establish whether scheduling, cache invalidation, location, or another lifecycle condition caused every blank |
| Owner installed the September 25 history/readability build and reported it works on the FR965, including stress history | The previously blank simulated stress trace is available on the owner's physical watch | This is not a measurement of battery life, runtime margin, or every edge case |
| Owner reported on September 28 that the polish build "all seems to work" and requested publication | That weather/recovery baseline was accepted | The report does not itemize every weather state, overnight recovery case, or firmware edge case |
| Owner requested publication of the working version on October 2, after the September 30 Moon candidate | Publication is authorized for the Moon-horizon revision | No instrumented on-watch astronomy or performance log was supplied |
| Generic SDK 9.2.0 compilation passed for the October 2 restored publication | Its release and native test sources compiled; 30 Monkey C test functions compiled | The FR965 device profile was missing locally; this was not an FR965 simulator run or execution of those tests |
| Source-derived arithmetic and reference checks passed | Checked Sun/Moon geometry, lunar reference values, horizon state, phase, and UTC/location handling agree with the recorded expectations | A JavaScript arithmetic replay is not Garmin VM execution or a device performance measurement |

**The owner accepted the September 28 polish baseline and authorized publication of the working version on October 2.** The earlier September 25 report separately established that stress history worked on the physical FR965 despite a blank simulated chart. Neither report quantifies memory use, watchdog margin, battery consumption, or a complete overnight recovery regression. See [VALIDATION.md](VALIDATION.md) for the scope of confirmation and remaining checks.

## Fonts and readability

Earlier SkyRing experiments used generated bitmap atlases for text. The user reported chunky text and, in another iteration, outline-like or broken-looking glyphs. We removed that text rendering path rather than continuing to tune generated glyphs. The precise contribution of atlas generation, transparency, and rendering to each screenshot was not isolated on-device.

All current text requests Garmin's native `RobotoCondensedRegular`, with `RobotoRegular` and built-in font fallbacks. Font ascents are measured once during layout. This follows the text approach that worked in RowWatch. The remaining bitmap font resources contain **icons only**, not letters or numeric readings. Native font availability and exact rendering still depend on the device.

Small labels deliberately use bright off-white colors, including `#E2DDD4` and `#DCD8D0`. Colorful sunrise and sunset glyphs remain distinct: orange/yellow for sunrise and blue/yellow for sunset. The outer ring was retained when lunar event labels were removed. The later history/readability update removes the status footer and uses its space for larger native text, larger icons, and more separation between rows.

Reference: Garmin [Graphics / getVectorFont](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html#getVectorFont-instance_function).

## Wake, sleep, and battery policy

The requirement is a wake-only face. There is no always-on renderer or scrolling content. The October 6 candidate adds one guarded 2,000-ms moisture-rotation timer during Garmin's permitted high-power lifecycle. It stops on hide, sleep, OFF, or LOW_POWER and does not hold the display awake or override brightness/timeout preferences. Garmin documents a roughly ten-second high-power window and disallows timers in low power; a longer screen timeout does not authorize extending that window.

`WakeState.resolve()` treats `System.getDisplayMode()` as authoritative where available. Lifecycle flags are a compatibility fallback, so an old sleeping/visibility flag cannot by itself keep a display that reports HIGH_POWER black. OFF returns before drawing or reading data. LOW_POWER clears to black and returns before data work. A detected resume or gap invalidates refresh state, and `onExitSleep()` requests a repaint.

This addresses a plausible failure path found in the earlier lifecycle code; it is not proof that every reported black screen had the same cause. Keep the regression scenarios for stale flags, resume gaps, and clock rollback. An actual repeated sleep/wake test remains necessary after firmware or lifecycle changes.

Most readings and sky calculations refresh on wake and once per minute while awake. Stress changes can request an awake refresh; callbacks received during sleep mark data dirty without forcing sensor reads. Current HR has its own read/fallback path. Local location storage is rewritten only after sufficient movement, rather than every minute. These are deliberate cost controls, not a measured battery-life guarantee.

References: Garmin [WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html) and [System display mode](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getDisplayMode-instance_function).

## Recovery and other body readings

The September 28 release uses only Garmin's native whole-hour recovery API. Its returned value is displayed unchanged as `0h`, `1h`, `7h`, etc.; missing/invalid values remain `--`. The caption is READY at zero native hours; positive or missing data keeps RECOVERY. Recovery complications, minute precision, the old first-frame suppression, recovery-only retries, and debugging machinery are removed.

The September 27 investigation reproduced code-caused blanking but did not establish the cause of the recurring on-watch `1m`. Its historical findings remain in [RECOVERY_INVESTIGATION.md](RECOVERY_INVESTIGATION.md). The current face bypasses that minute source by explicit user request; it does not claim to repair Garmin firmware. The direct source may differ from Garmin's built-in screen near hourly boundaries. [Current behavior](RAW_HOURS_UPDATE.md).

Stress uses Garmin's complication, with a recent valid history sample as fallback. It can retain a valid value for up to 30 minutes when a new sample is unavailable. That means the display is not always an instantaneous stress measurement. Historical sample timestamps are retained so rereading one old sample does not make it fresh again. HR likewise depends on whichever Garmin samples are available; the face does not improve the underlying sensor's accuracy.

Reference: Garmin [Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html), especially recovery time and stress.

## Stress history, simulator behavior, and missing data

The stress meter was replaced with a four-hour history because the large number already communicates current stress. Both HR and stress histories use 24 ten-minute averages and rebuild together about every five minutes while awake. Fixed saturated colors convey the absolute bands even as chart height rescales; purple stress denotes a low measured score, not a sleep-stage classification. Current stress and history are separate data paths: the retained current number is never inserted into the chart.

The owner saw a current stress number and a blank history in the SDK 9.2.0 simulator, then confirmed the same build works on the watch. A [Garmin forum report](https://forums.garmin.com/developer/connect-iq/f/connect-iq-web-store/441912/emulator-sets-sensor-history-samples-time-into-future) describes simulator history timestamps in the future. Such samples fall outside this face's valid historical window, but no raw log proved that was the specific cause in this session. No simulator-specific workaround or diagnostic changes are shipped.

The renderer requires at least two populated buckets and connects only neighboring populated buckets. Isolated older measurements may produce no visible mark. Missing observations are not zeroes and are not joined by fabricated lines; measured stress zero is valid. A blank chart can therefore reflect sparse or unavailable history even when a current number is present. See the [display guide](DISPLAY_GUIDE.md) and [release color table](RELEASE_NOTES.md#color-meaning).

## Requested readings that are absent

| Reading | Current decision and reason |
|---|---|
| Overnight HRV / HRV status | Not implemented. No documented native source usable by this project was established. An external-service/API-key approach was rejected because the user wants Garmin's own ecosystem only. This is not a claim that all future Garmin APIs, devices, or third-party complications can never provide HRV. Beat-to-beat data would also not automatically reproduce Garmin's overnight HRV status. |
| Respiration | Removed at the user's request because they did not find it useful/accurate enough. A documented respiration complication exists; this is a product choice, not an API impossibility. |
| VO2 max | Removed at the user's request because it changes slowly and occupied space. Garmin documents VO2 complications; they are not used here. |
| Sleep | Not implemented or validated on this target. Current Garmin documentation lists a sleep-score complication starting with API 6.0.2; that alone does not establish availability on the user's FR965 firmware. |
| Exercise load, altitude acclimation, heat acclimation | Not implemented. A reliable supported source for these specific readings on this target was not established during this work. Training status, where exposed, should not be silently substituted for numerical exercise load. |
| Chest-strap connection indicator | Not implemented or proven. A general Bluetooth/phone connection indicator does not establish that a specific HR strap is connected or supplying the displayed HR. |
| Battery, weather-age timer, and current elevation | Removed from the bottom row at the owner's request to reduce clutter and improve readability. Weather observation age still controls stale styling internally; daily floors climbed remains. These are layout choices, not missing APIs. |
| Body Battery and SpO2 | Deliberately excluded by the user. |

Revisit an omitted reading only when its exact meaning, public source, target support, and failure behavior can be demonstrated. Do not add speculative identifiers or require an outside account just to fill a slot.

## Weather and activity semantics

The weather icon uses Garmin's **condition code**, not merely daytime/nighttime. Clear and partly cloudy states have day/night variants; cloudy, rain, snow, thunder, fog, and wind conditions have their own groups. Unknown codes display `?`. Cloud cover is not inferred from the user's view of the sky.

The current condition groups have distinctive colors, with a lemon-yellow Sun, lavender Moon, and silver cloud overlays on partly cloudy and rain/snow/thunderstorm icons. Condition-selection rules and temperature text are unchanged. A September 28 correction replaced String identity comparisons with `String.equals()` so condition colors, cloud layers, and weather-row accents select reliably. The icon colors still describe the cached Garmin observation; more colorful artwork does not make that observation fresher or more local.

Garmin's `CurrentConditions` is cached weather. The face reads its observation time for stale-weather styling; the visible `WX` age timer has been removed. Rereading the object does not fetch a new observation. This project does not make network weather requests or guarantee weather updates at a fixed interval. A stale or geographically different station observation can disagree with conditions at the user's wrist.

The last weather field shows **precipitation chance at 30% or more**, otherwise UV. It does not switch simply because the condition is cloudy or sunny. Narrow layouts may omit high/low temperatures and then that last field to avoid overlap. The bottom battery/elevation/weather-age row has been removed entirely; its readings are not relocated.

UV uses standard risk-category colors on its saturated label, with its number blended 65% toward warm off-white. Native humidity and dew point alternate in one fixed-width slot every two seconds during normal awake updates. Humidity uses a blue droplet; dew point uses a lavender thermometer-and-drop icon. Their fresh values use the same 65% pale blend. These moisture colors identify metrics rather than risk levels. Dew point is Garmin's cached `CurrentConditions.dewPoint`, not a local estimate; unavailable dew point leaves humidity visible. The October 6 candidate moves selection and monotonic dwell out of drawing, preserves the selection across sleep and repeated callbacks, and adds one guarded awake redraw timer. Missing either reading stops that timer. It does not fetch weather or keep the screen awake. The owner accepted the September 28 baseline, then later reported that alternation still stalled. Source-level checks reproduce callback-triggered selection resets and show that rotation depended entirely on supplied frames; they do not identify the exact on-watch callback sequence. Earlier tests injected awake frames, so they did not establish that the face could request a needed redraw when those frames were absent. See [the current rotation investigation](WEATHER_ROTATION_UPDATE.md); [weather details](WEATHER_UPDATE.md) and [polish rationale](POLISH_UPDATE.md) preserve the historical implementation.

The `7d` step total is **today so far plus the previous six local calendar dates**. It moves forward each local date, rather than resetting with the intensity-minutes week. It is not an exact trailing 168-hour sum. Garmin daily history is matched by date, so missing dates and DST are not treated as fixed 24-hour buckets. An explicit zero is valid; missing history is not fabricated as zero. Valid daily bars are green below that date's recorded goal and yellow at or above it. Missing goals do not imply success; adaptive historical goals are not replaced with today's target. `7d*` indicates an incomplete total. Weekly intensity minutes and its goal are Garmin's own values, not a reconstruction of literal minutes in HR zones. Floors displays the climbed total without a daily goal.

References: Garmin [CurrentConditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html), [Weather conditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html), and [ActivityMonitor](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html). The date-window implementation is in `source/DaySteps.mc`.

## Moon position, the watchdog failure, and the simplification

The September 30 investigation reproduced a display bug: at 10 a.m. in Hillsborough, the Moon was about 16.57° above the horizon, but its hour angle of about 85.8° placed the old marker almost at 3 o'clock. The ephemeris was accurate against the captured USNO comparison; the drawing used the wrong quantity for the intended visual meaning. Normal once-per-minute refresh was too small an effect to explain the discrepancy.

The Moon now uses an east/up/west projection of its apparent altitude and azimuth. Its center appears above or below the horizontal diameter consistently with its apparent altitude. The projection omits north/south depth, so the dial is not a degree-for-degree altitude scale; it has a degeneracy at a due-north or due-south horizon crossing. The helper provides a deterministic side there, but a one-dimensional rim cannot preserve every three-dimensional sky direction continuously. The Sun remains a **local-hour-angle dial**, and its colored ring still describes the Sun's cycle.

Each body's upper-limb horizon state is computed separately and affects marker brightness. The Moon's center-based projection can cross the diameter slightly after its first illuminated limb becomes visible. The Moon remains visible, but dim, below the modeled horizon. Its illuminated disc follows the current phase and waxing/waning state. Hemisphere orientation is conventional; the exact apparent tilt of the illuminated limb is not rendered.

UTC, real location, double-precision day counts, and lunar coordinates matter. The current reference check is tied to an explicit instant and location, not an undated search snippet. See [LUNAR_CALCULATIONS.md](LUNAR_CALCULATIONS.md) for the captured USNO comparison and method. A cached weather station or old location can still give an inaccurate position after travel. Without a usable real location, markers are suppressed and the ring is neutral instead of presenting a time-zone estimate as a physical sky position.

The failed event experiment repeatedly calculated lunar coordinates across a 48-hour window, with additional crossing refinement, inside one screen update. The supplied watchdog stack and that code path identify the expensive search. Drawing the rim marker was not the bulk operation. Caching helped later updates but did not protect the first calculation with an empty cache.

A replacement spread event calculations across bounded awake updates and retained progress across sleeps. Numerical and source scheduling checks did not establish satisfactory watch behavior: the user still reported blank event fields. Rather than add more state and visual clutter, the current build removes moonrise/set, next-full/new predictions, their workers, caches, lifecycle hooks, and placeholders entirely. They are not merely hidden. That simplification initially restored the footer's spacing. The later history/readability update removes the footer entirely and redistributes the space among the retained readings.

The retained lunar calculation evaluates **one current position** during a normal astronomy refresh. There is no future-event scan. Sunrise/sunset and their colorful icons remain. Current Moon phase remains; a future full/new date is a separate calculation and is absent.

## Lessons for future changes

- Test an empty cache and the first visible frame. A correct result and a fast warm cache do not make an expensive first callback safe.
- Separate mathematical accuracy from Garmin runtime behavior. Generic compilation and host-side replay cannot establish watchdog margin or battery cost.
- Describe the display's semantics explicitly: hour angle versus altitude, cached weather versus a new observation, daily history versus an exact elapsed-time window.
- Keep unavailable data visibly unavailable. Do not substitute a different health metric or reset old observation timestamps.
- Preserve the working wake-only policy, native text, bright labels, and readable spacing. Add a field only when its value outweighs its cost in runtime, state, and screen area.

For a new on-device failure, capture the full Garmin stack, build/revision, firmware, whether it followed wake, and whether location/weather data were available. That evidence is more useful than repeatedly adjusting an unverified cause.
