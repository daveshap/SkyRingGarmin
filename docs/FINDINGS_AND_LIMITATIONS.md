# Findings, removed experiments, and known limits

This records what we learned while moving from RowWatch to SkyRing and repairing the sky calculations. It distinguishes reported device behavior, source changes, and checks that have not yet been run on the target watch. The current publication is the **simplified SkyRing** build: current Sun/Moon positions and Moon phase remain; lunar event predictions do not.

## What has actually been verified

| Evidence | What it establishes | What it does not establish |
|---|---|---|
| User installed earlier RowWatch builds on a Forerunner 965 and reported that they worked | The development, signing, sideloading, and basic dashboard approach worked on the user's watch | It does not validate later SkyRing changes |
| User supplied SkyRing screenshots and feedback after font, spacing, and lunar changes | Those revisions rendered; the native-font revision looked better to the user | Screenshots cannot prove refresh behavior, numerical accuracy, or battery life |
| User reported intermittent black screens after sleep | There was a real wake/display problem in an earlier revision | No instrumented device trace established one exclusive cause |
| Garmin reported a watchdog stack through `onUpdate → refresh → refreshLunarEvents → events → position → coordinates` | The old synchronous lunar-event calculation exceeded the callback's execution allowance | It does not establish an exact watchdog threshold or blame `cosD()` itself |
| User reported lunar rise/set fields blanking after the bounded-worker replacement | That replacement did not meet the user's reliability expectations | The report does not establish whether scheduling, cache invalidation, location, or another lifecycle condition caused every blank |
| Generic Connect IQ SDK 9.2.0 release and test compilation passed | The published sources/resources compile in that environment; 14 Monkey C tests compile | The FR965 device profile was missing locally; this was not an FR965 simulator run or execution of those tests |
| Source-derived arithmetic and reference checks passed | Checked Sun/Moon geometry, lunar reference values, horizon state, phase, and UTC/location handling agree with the recorded expectations | A JavaScript arithmetic replay is not Garmin VM execution or a device performance measurement |

**The latest simplified build has not yet been confirmed by the user on FR965 hardware.** Its exact font rasterization, memory use, watchdog margin, firmware lifecycle behavior, and battery consumption remain device checks. See [VALIDATION.md](VALIDATION.md) for the short acceptance check.

## Fonts and readability

Earlier SkyRing experiments used generated bitmap atlases for text. The user reported chunky text and, in another iteration, outline-like or broken-looking glyphs. We removed that text rendering path rather than continuing to tune generated glyphs. The precise contribution of atlas generation, transparency, and rendering to each screenshot was not isolated on-device.

All current text requests Garmin's native `RobotoCondensedRegular`, with `RobotoRegular` and built-in font fallbacks. Font ascents are measured once during layout. This follows the text approach that worked in RowWatch. The remaining bitmap font resources contain **icons only**, not letters or numeric readings. Native font availability and exact rendering still depend on the device.

Small labels deliberately use bright off-white colors, including `#E2DDD4` and `#DCD8D0`. Colorful sunrise and sunset glyphs remain distinct: orange/yellow for sunrise and blue/yellow for sunset. The outer ring and enlarged content layout were retained when lunar event labels were removed.

Reference: Garmin [Graphics / getVectorFont](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics.html#getVectorFont-instance_function).

## Wake, sleep, and battery policy

The requirement is a wake-only face. The code has no always-on renderer, animation timer, or scrolling content. It does not try to hold the display awake or override system brightness/timeout preferences.

`WakeState.resolve()` treats `System.getDisplayMode()` as authoritative where available. Lifecycle flags are a compatibility fallback, so an old sleeping/visibility flag cannot by itself keep a display that reports HIGH_POWER black. OFF returns before drawing or reading data. LOW_POWER clears to black and returns before data work. A detected resume or gap invalidates refresh state, and `onExitSleep()` requests a repaint.

This addresses a plausible failure path found in the earlier lifecycle code; it is not proof that every reported black screen had the same cause. Keep the regression scenarios for stale flags, resume gaps, and clock rollback. An actual repeated sleep/wake test remains necessary after firmware or lifecycle changes.

Most readings and sky calculations refresh on wake and once per minute while awake. Stress/recovery changes can request an awake refresh; callbacks received during sleep mark data dirty without forcing sensor reads. Current HR has its own read/fallback path. Local location storage is rewritten only after sufficient movement, rather than every minute. These are deliberate cost controls, not a measured battery-life guarantee.

References: Garmin [WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html) and [System display mode](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getDisplayMode-instance_function).

## Recovery and other body readings

Garmin's recovery complication reports **minutes**. The current formatter shows `READY` at zero, minutes below 60, and rounded-up hours at 60 or more. Thus 1 minute displays as `1m`, not `1h`; 61 minutes displays as `2h`. Missing/invalid data displays `--`.

An earlier report of `1h` when the watch's recovery screen was ready could have involved rounding or stale data. Without a contemporaneous raw complication value, the cause is not proven. The current code fixes the final-hour presentation and rereads recovery on wake, minute refresh, and an awake complication change. It does not invent its own recovery estimate or guarantee that Garmin's provider updates at the exact instant another built-in screen does.

Stress uses Garmin's complication, with a recent valid history sample as fallback. It can retain a valid value for up to 30 minutes when a new sample is unavailable. That means the display is not always an instantaneous stress measurement. Historical sample timestamps are retained so rereading one old sample does not make it fresh again. HR and elevation likewise depend on whichever Garmin samples are available; the face does not improve the underlying sensor's accuracy.

Reference: Garmin [Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html), especially recovery time and stress.

## Requested readings that are absent

| Reading | Current decision and reason |
|---|---|
| Overnight HRV / HRV status | Not implemented. No documented native source usable by this project was established. An external-service/API-key approach was rejected because the user wants Garmin's own ecosystem only. This is not a claim that all future Garmin APIs, devices, or third-party complications can never provide HRV. Beat-to-beat data would also not automatically reproduce Garmin's overnight HRV status. |
| Respiration | Removed at the user's request because they did not find it useful/accurate enough. A documented respiration complication exists; this is a product choice, not an API impossibility. |
| VO2 max | Removed at the user's request because it changes slowly and occupied space. Garmin documents VO2 complications; they are not used here. |
| Sleep | Not implemented or validated on this target. Current Garmin documentation lists a sleep-score complication starting with API 6.0.2; that alone does not establish availability on the user's FR965 firmware. |
| Exercise load, altitude acclimation, heat acclimation | Not implemented. A reliable supported source for these specific readings on this target was not established during this work. Training status, where exposed, should not be silently substituted for numerical exercise load. |
| Chest-strap connection indicator | Not implemented or proven. A general Bluetooth/phone connection indicator does not establish that a specific HR strap is connected or supplying the displayed HR. |
| Body Battery and SpO2 | Deliberately excluded by the user. |

Revisit an omitted reading only when its exact meaning, public source, target support, and failure behavior can be demonstrated. Do not add speculative identifiers or require an outside account just to fill a slot.

## Weather and activity semantics

The weather icon uses Garmin's **condition code**, not merely daytime/nighttime. Clear and partly cloudy states have day/night variants; cloudy, rain, snow, thunder, fog, and wind conditions have their own groups. Unknown codes display `?`. Cloud cover is not inferred from the user's view of the sky.

Garmin's `CurrentConditions` is cached weather. The face reads its observation time and displays its age as `WX`; rereading the object does not fetch a new observation. This project does not make network weather requests or guarantee weather updates at a fixed interval. A stale or geographically different station observation can disagree with conditions at the user's wrist.

The last weather field shows **precipitation chance at 30% or more**, otherwise UV. It does not switch simply because the condition is cloudy or sunny. Narrow layouts may omit high/low temperatures and then that last field to avoid overlap. Elevation may similarly lose its unit or be omitted from the footer when it will not fit.

The `7d` step total is **today so far plus the previous six local calendar dates**. It moves forward each local date, rather than resetting with the intensity-minutes week. It is not an exact trailing 168-hour sum. Garmin daily history is matched by date, so missing dates and DST are not treated as fixed 24-hour buckets. An explicit zero is valid; missing history is not fabricated as zero. `7d*` indicates an incomplete total. Weekly intensity minutes and its goal are Garmin's own values, not a reconstruction of literal minutes in HR zones. Floors displays the climbed total without a daily goal.

References: Garmin [CurrentConditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html), [Weather conditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html), and [ActivityMonitor](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor.html). The date-window implementation is in `source/DaySteps.mc`.

## Moon position, the watchdog failure, and the simplification

The rim is a **local-hour-angle dial**. Top means upper meridian transit; bottom means lower transit. Left approaches upper transit and right moves away. It is not a compass and not a literal altitude plot. A Moon marker in the upper semicircle does not by itself prove the Moon is above the horizon. Lunar declination differs from solar declination; the colored ring describes the Sun's cycle.

Each body's horizon state is computed separately and affects marker brightness. The Moon remains visible, but dim, below the modeled horizon. Its illuminated disc follows the current phase and waxing/waning state. Hemisphere orientation is conventional; the exact apparent tilt of the illuminated limb is not rendered.

UTC, real location, double-precision day counts, and lunar coordinates matter. The current reference check is tied to an explicit instant and location, not an undated search snippet. See [LUNAR_CALCULATIONS.md](LUNAR_CALCULATIONS.md) for the captured USNO comparison and method. A cached weather station or old location can still give an inaccurate position after travel. Without a usable real location, markers are suppressed and the ring is neutral instead of presenting a time-zone estimate as a physical sky position.

The failed event experiment repeatedly calculated lunar coordinates across a 48-hour window, with additional crossing refinement, inside one screen update. The supplied watchdog stack and that code path identify the expensive search. Drawing the rim marker was not the bulk operation. Caching helped later updates but did not protect the first calculation with an empty cache.

A replacement spread event calculations across bounded awake updates and retained progress across sleeps. Numerical and source scheduling checks did not establish satisfactory watch behavior: the user still reported blank event fields. Rather than add more state and visual clutter, the current build removes moonrise/set, next-full/new predictions, their workers, caches, lifecycle hooks, and placeholders entirely. They are not merely hidden. The footer has its earlier spacing again.

The retained lunar calculation evaluates **one current position** during a normal astronomy refresh. There is no future-event scan. Sunrise/sunset and their colorful icons remain. Current Moon phase remains; a future full/new date is a separate calculation and is absent.

## Lessons for future changes

- Test an empty cache and the first visible frame. A correct result and a fast warm cache do not make an expensive first callback safe.
- Separate mathematical accuracy from Garmin runtime behavior. Generic compilation and host-side replay cannot establish watchdog margin or battery cost.
- Describe the display's semantics explicitly: hour angle versus altitude, cached weather versus a new observation, daily history versus an exact elapsed-time window.
- Keep unavailable data visibly unavailable. Do not substitute a different health metric or reset old observation timestamps.
- Preserve the working wake-only policy, native text, bright labels, and readable spacing. Add a field only when its value outweighs its cost in runtime, state, and screen area.

For a new on-device failure, capture the full Garmin stack, build/revision, firmware, whether it followed wake, and whether location/weather data were available. That evidence is more useful than repeatedly adjusting an unverified cause.
