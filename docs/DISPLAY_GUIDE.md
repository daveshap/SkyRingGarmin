# Display guide: what each element means

This guide describes the source in this repository, including its limitations. It is not a list of features planned during earlier RowWatch or SkyRing experiments. The current design is a wake-only dashboard for the Forerunner 965: a sky-cycle ring, three body readings, two movement rows, and weather. The former WX-age, battery, and elevation footer is removed.

## Reading the face at a glance

| Position | Element | Meaning |
| --- | --- | --- |
| Top, beneath the ring | Small peak-Sun icon and degrees | Approximate maximum solar elevation at solar noon |
| Header | Date and large clock | Local day/date and device time |
| Beneath clock | Sun icon, time, angle, countdown | Apparent solar time; current solar elevation; time to sunrise or sunset |
| Outer ring | Color bands, Sun, Moon | Solar daylight/twilight cycle; each body's current local hour angle; current lunar phase |
| Left and right edges | Colorful rising/setting Sun icons and times | Local sunrise and sunset clock times |
| Body row | Heart, stress gauge, stopwatch | Heart rate, stress, and Garmin recovery time |
| Under body values | Two traces and recovery caption | Four-hour HR and stress trends, and `RECOVERY` or `READY` |
| First movement row | Footprints, seven bars, `7d` | Today's steps, seven daily totals, and their rolling sum |
| Second movement row | Chevrons, flame, stairs | Weekly intensity minutes/goal, daily calories, daily floors climbed |
| Weather row | Conditions, temperature/high-low, droplet, UV or umbrella | Cached Garmin weather |

The icon identifies a reading; its fixed color identifies a group. Coral is body data, mint is movement, blue is weather, and gold is solar information. Most numerical values are warm off-white. **Icons and numerical values keep their fixed colors.** Saturated data-dependent colors apply to the HR trace, stress trace, and seven daily step bars only; see the [release color table](RELEASE_NOTES.md#color-meaning).

## Ring and sky information

### What position on the rim means

Both markers use **local hour angle**. The top is upper meridian transit, the bottom is lower transit, the left side approaches upper transit, and the right side follows it. The mathematical mapping is:

- `x = centerX + radius × sin(hourAngle)`
- `y = centerY − radius × cos(hourAngle)`

This is a daily sky-cycle dial. It is not a compass bearing, and a marker at the top does not mean the body is directly overhead. A marker in the upper half does not by itself prove that body is above the horizon. Latitude and the body's declination also matter. In particular, the Moon does not share the Sun's horizon crossings or colored daylight band.

Above/below-horizon status is calculated separately and changes marker brightness. Both markers remain visible below the horizon so the face continues to show their progress. There is no current moonrise/set time or next full/new-moon prediction.

### Ring colors and elapsed shading

`Astro.compute()` supplies hour angles for solar elevation thresholds; `buildStops()` and `ringColor()` turn them into a continuous color gradient.

| Portion of the solar cycle | Appearance |
| --- | --- |
| Around solar noon | Pale gold |
| Toward low Sun; +6° elevation boundary | Warm gold/orange |
| Sunrise/sunset; −0.833° solar-center threshold | Orange |
| Civil twilight boundary; −6° | Rose |
| Nautical twilight boundary; −12° | Violet |
| Astronomical twilight boundary; −18° | Indigo |
| Deep night toward lower transit | Dark blue |

The part of the solar cycle already passed is shaded to 32% of its original RGB values. It resets across lower transit, approximately solar midnight; it is not tied precisely to civil midnight. Color describes computed solar geometry, not observed cloud cover or sky color. Small ticks identify solar noon and sunrise/sunset. A passed sunrise/set tick becomes subdued, while the corresponding colored icon stays colorful.

The ring radius is 220 pixels on the 454-pixel display, with a 12-pixel stroke. Marker centers sit at radius 214 to keep their graphics inside the display edge. These dimensions deliberately use more of the screen than the earlier inset layout.

### Sun marker, peak elevation, and solar detail line

The Sun is a gold disc with eight rays so it remains distinct from a full Moon. It is rendered at half brightness below the calculated solar horizon. `Astro.compute()` derives its hour angle from longitude, UTC, and the equation of time, using Astronomical Almanac approximations.

The small degrees value above the date is the approximate maximum elevation at solar noon: `90° − abs(latitude − solarDeclination)`. The angle beside solar time is the Sun's current geometric center elevation. These are different quantities. A small negative current elevation can coexist with the Sun being classified as up, because the rise/set criterion includes the conventional apparent upper-limb allowance.

Solar time is apparent solar time, or sundial time, in `HH:MM` format. It always uses 24-hour notation even when the large clock uses 12-hour time. Apparent solar noon is 12:00; longitude and the equation of time explain why it differs from the civil clock. The code also computes mean solar time internally, but does not display it.

The text to its right gives the time to the next sunrise or sunset, such as `2h 25m to sunset`. It uses the current day's simplified solar solution, not a multi-day event search. At polar limits it instead says `sun up all day` or `sun down all day`. Spacing tightens first if the line is long; its countdown text can then drop from the 24-pixel font to 22 pixels.

### Sunrise and sunset

The left edge shows sunrise and the right edge sunset. Both are calculated locally by `Astro.compute()`; this version does **not** call Garmin's `Weather.getSunrise()` or `Weather.getSunset()`, although those APIs exist. Sharing the solar solution keeps the times, ring boundaries, and countdown consistent.

Times follow the device's 12/24-hour preference and are rounded to the nearest minute. In 12-hour mode these small side times omit an am/pm suffix; the rising/setting icon provides context. The icons combine a yellow Sun with an orange rising arrow/horizon or blue setting arrow/horizon. Their colors do not fade after the event. Times and icons are omitted when the solution has no sunrise/set for that day.

### Moon marker and phase

`Lunar.position()` calculates current lunar coordinates using the Meeus chapter 47 periodic series. Local sidereal time minus right ascension gives hour angle. Altitude includes a spherical parallax correction and conventional refraction. Brightness uses a separate standard upper-limb horizon test.

The Moon is a phase-shaped disc with a thin outline. The illuminated fraction changes continuously; it is not a fixed waxing-gibbous bitmap. Waxing is lit on the right in the northern hemisphere and on the left in the southern hemisphere, with the reverse for waning. This is a conventional phase orientation, not the exact apparent tilt of the Moon in the sky. Below the horizon its lit portion uses 60% brightness. Its dark portion and outline preserve visibility around new moon.

The Sun is drawn after the Moon. If they occupy nearly the same part of the rim around conjunction, the Sun can cover some or all of the Moon marker. There is no separate collision-displacement layout that would move either marker away from its calculated position.

Terrain, buildings, observer height, and actual atmospheric refraction are not modeled. Clouds cannot alter the astronomical position. See [LUNAR_CALCULATIONS.md](LUNAR_CALCULATIONS.md) for the reference comparison and precision limits.

### Which location is used

The location source, in order, is:

1. Garmin weather's `observationLocationPosition`.
2. `Activity.getActivityInfo().currentLocation`.
3. The last valid position saved by this watch face.
4. A rough longitude estimated from the time-zone offset, with latitude unavailable.

The face does not activate GPS to acquire a new fix. A weather station or saved position may differ from the wearer's current position, and this code does not expose its age. That is an important reason an otherwise sound sky calculation can disagree with an observation while traveling.

With only the time-zone estimate, the ring becomes neutral, the Sun/Moon markers and location-dependent labels are suppressed, and `LOCATION --` appears. The solar-time estimate is prefixed with `~` and accompanied by `location needed`. The code rejects invalid coordinate ranges and the common `0,0` placeholder; this also means a genuine location exactly at `0,0` is not supported by that validation rule.

## Date and civil time

The date uses `Gregorian.info()` with medium formatting, displayed as day of week, day number, and month. The large clock uses `System.getClockTime()` and respects `System.getDeviceSettings().is24Hour`. It displays minutes, without a seconds field. Twelve-hour mode has a separate smaller `am` or `pm` suffix.

The date is cached with the normal data refresh; time is read each awake redraw. The watch controls its clock and time zone. The face does not set either.

## Body readings

### Heart rate and the four-hour trace

The heart icon identifies a beats-per-minute value. `currentHr()` first tries `Activity.getActivityInfo().currentHeartRate`, rejecting zero and Garmin's invalid-sample sentinel. If unavailable, it looks for a valid `ActivityMonitor.getHeartRateHistory()` sample no older than five minutes. That fallback is polled at most every 30 seconds, scans at most 32 samples, and retains the original observation time. If neither source qualifies, the value is `--`.

The small trace comes from `SensorHistory.getHeartRateHistory()`, summarized into 24 ten-minute averages over the preceding four hours. It is rebuilt with the stress trace approximately every five minutes during full refreshes, or after clock rollback. Both charts use the same four-hour window and shared `HistoryBuckets` accumulator. Each native iterator runs newest-first with a maximum of 1,024 samples, so unexpectedly dense history cannot cause an unbounded scan; older omitted buckets remain gaps. Missing buckets break the line; they are not joined by an invented trace. Invalid/zero HR samples and timestamps outside the window are excluded. Fewer than two populated buckets yields no chart. Lines join adjacent populated buckets only; isolated older buckets may therefore be invisible even when two or more buckets contain measurements. The vertical scale follows the available values, with a minimum 12-bpm range, so line steepness is not comparable between different time windows. The trace has no displayed numerical axis.

Color uses the actual average BPM, independent of that vertical scale: below 60 purple, 60–under 70 blue, 70–under 90 green, 90–under 110 yellow, 110–under 130 orange, and 130+ red. Each adjoining half-segment takes its nearest bucket's color; the last-point marker takes that bucket's color. These are fixed display bands, not Garmin's personalized exercise zones. Averaging means a brief peak may be lower in the chart than its instantaneous HR reading.

This is a glanceable trend attached to the heart-rate reading. Neither the large value nor the trace identifies whether an optical sensor or chest strap supplied Garmin's data. There is no chest-strap connection indicator in this version.

### Stress and the four-hour trace

Stress comes first from the native `COMPLICATION_TYPE_STRESS` complication. If it is absent or outside 0–100, `SensorHistory.getStressHistory()` provides the newest valid sample from the preceding 30 minutes. Missing/moving samples are skipped. The last good value is held for up to 30 minutes when no new value is available; then the display becomes `--`.

The trace below it uses measured `SensorHistory.getStressHistory()` samples in 24 ten-minute averages over the preceding four hours, on the same schedule and time axis as HR. Values outside 0–100 are rejected, but measured zero is valid. Missing or movement-related gaps break the line; the held current number is never used to fill historical gaps. Fewer than two populated buckets yields no chart. Lines join adjacent populated buckets only; isolated older buckets may therefore be invisible even when two or more buckets contain measurements. The vertical scale follows the available values with a minimum 20-point range, so the colors convey absolute stress even when the scale changes.

Each bucket uses its rounded mean score for color: 0–14 purple, 15–25 blue, 26–50 green, 51–65 yellow, 66–75 orange, and 76–100 red. Adjacent half-segments take their nearest bucket's color. Purple identifies the lowest stress band; it does not infer deep sleep or a sleep stage. A measured zero can appear as a purple trace; missing data stays a gap. The large number still shows the current stress reading, independently of these historical averages. A blank simulator chart does not by itself establish a watch failure: the owner observed exactly that discrepancy and confirmed this build displays stress history on the physical FR965. See [VALIDATION.md](VALIDATION.md) for the simulator finding and its limits.

History samples retain their actual observation timestamp. The complication path does not provide an observation timestamp in this implementation: a valid complication value is treated as current when read. Consequently the face cannot independently detect a stale value repeatedly returned by that source. There is no stress-age indicator on screen.

### Recovery time

The stopwatch is Garmin's native `COMPLICATION_TYPE_RECOVERY_TIME`, read as minutes through `Complications.getComplication()`. It is reread on wake, each normal minute refresh, and when a subscribed complication change is handled while awake. A complication failure clears the cached reading instead of preserving an old result indefinitely.

Recovery uses a bounded wake confirmation: a native zero displays immediately, while a first positive reading displays `--` until a later awake frame, approximately one second later. Recovery-only rechecks occur around +1 and +3 seconds on normal awake updates, unless a normal minute/callback read already satisfies them. Late frames do not trigger catch-up loops. There are no timers, extra wake requests, or persistent recovery state. A genuine 1-minute reading remains `1m` after confirmation. This reduces exposure to a transient initial reading; it cannot identify a stale value Garmin continues to return because the complication has no freshness timestamp.

`RecoveryTime.display()` intentionally handles the final hour differently:

| Native recovery value | Display |
| --- | --- |
| Missing or invalid | `--`, caption `RECOVERY` |
| 0 minutes | `0h`, caption `READY` |
| 1–59 minutes | Exact whole minutes, such as `24m` |
| 60 minutes or more | Hours rounded upward, such as 61 minutes → `2h` |

This avoids turning one minute into `1h`, which previously made an almost-finished recovery period misleading. `READY` means Garmin reports zero recovery time; the watch face does not calculate a separate readiness assessment or count down from a private timer. Garmin can still return data later than its built-in screen changes.

Recovery occupies a slot used for an unsuccessful external-HRV experiment. **HRV is not implemented in this build.** No API key, external service, or estimated substitute is present.

## Movement readings

### Today's steps, seven daily bars, and the rolling total

The footprint value is `ActivityMonitor.getInfo().steps`, formatted with thousands separators. The value on the right is the sum of **today plus the preceding six local calendar dates**. It is neither Garmin's calendar-week total nor a precise trailing 168-hour window.

`DaySteps.summarizeWithGoals()` combines today's live value and goal with dated `ActivityMonitor.getHistory()` records. The live counter owns today; a history record cannot add today a second time. Records outside the window, future dates, and duplicate dates are ignored. Date arithmetic accounts for leap years and does not assume every local day lasts exactly 24 hours.

Seven bars run oldest to newest, with today at the right. Heights remain scaled to the largest available day in that seven-day window. Every valid bar is saturated green until that date's own goal is met, then yellow at or above the goal. Today's goal is `ActivityMonitor.Info.stepGoal`; past goals are `ActivityMonitor.History.stepGoal` from the same accepted record as the count. A missing/nonpositive goal leaves the bar green; today's adaptive goal is never substituted for a missing historical goal. A measured zero gets a minimal green bar; an unavailable date gets a gray dot. Height still shows steps, not percentage of goal, and no extra goal label is added.

- `7d` means all seven dates have a usable reading.
- `7d*` means the total includes only the available dates; it is incomplete.
- `--` means no usable step total is available.

The face does not fetch a longer history from Garmin Connect or fill absent days with zero. The bar group narrows when numbers require more room, then disappears if less than 35 pixels remain. The two numerical totals remain the priority.

### Weekly intensity minutes and goal

The chevrons identify `ActivityMonitor.Info.activeMinutesWeek.total`; the small `/goal` suffix is `activeMinutesWeekGoal`. This uses Garmin's current week and configured goal, independently of the seven-day step window. Garmin defines this total as moderate minutes plus **twice** vigorous minutes. It is therefore not literal time in heart-rate zones, and the face does not reconstruct raw zone minutes.

A thin mint underline beneath this specific value shows the ratio to its displayed goal, capped visually at 100%. The number can exceed the goal. An unavailable value is `--`; an unavailable goal omits the denominator. If the goal is absent or not positive, the track stays unfilled. No daily step or floor goal number is shown; daily step bars indicate goal achievement by color only.

### Calories and floors climbed

The flame is Garmin's current-day calorie total from `ActivityMonitor.Info.calories`, in kilocalories. It is the supplied daily calories-burned field, not a calculation of workout-only/active calories by this face.

The stair icon is `ActivityMonitor.Info.floorsClimbed`, today's total floors climbed. It is not metres/feet of ascent, elevation gain over seven days, or progress toward a floor goal. It intentionally shows only the total. Missing values become `--`.

The intensity/calorie/floor row tightens spacing if needed, then reduces its numerical font from 36 to 26 pixels. Extremely long or unexpected values still need device-layout testing; the design is optimized for typical daily readings.

## Weather

### Source, temperature, high/low, and humidity

`Weather.getCurrentConditions()` supplies Garmin's **most recently cached observation**. A watch-face refresh rereads that cache; it does not force a fresh weather download. The face makes no external network request and has no weather-provider API key.

Current temperature uses `temperature`, converting the native Celsius value to the watch's temperature-unit preference and rounding to a whole degree. The display uses a degree sign without a repeated `F`/`C` suffix. The small `high/low` pair comes from `highTemperature` and `lowTemperature`, which Garmin defines as the forecast high and low for that day. It is not today's measured range from the watch's temperature sensor. The droplet value is `relativeHumidity`, rounded and shown as a percentage.

Unavailable readings display `--`. High/low is omitted unless both values exist. If the row is too wide, it first tightens gaps, then removes high/low, then removes the third UV/rain item. Temperature/conditions and humidity have priority. The enlarged type and lower row position leave less lateral room, so optional high/low may be omitted more often.

### Conditions icon

The icon beside temperature follows Garmin's `condition` value, not just day/night. `condGlyph()` maps the current documented numerical conditions into the following compact families:

| Icon family | Garmin condition codes handled |
| --- | --- |
| Clear Sun / clear Moon | Clear (0), mostly clear (23), fair (40) |
| Partly cloudy Sun / Moon | Partly cloudy (1), partly clear (22), thin clouds (52) |
| Cloud | Mostly cloudy (2), cloudy (20) |
| Thunderstorm | Thunderstorms (6), scattered thunderstorms (12), chance of thunderstorms (28) |
| Snow/ice/mix | 4, 7, 10, 16–19, 21, 34, 43, 44, 46–48, 50, 51 |
| Fog/haze/obscuration | 8, 9, 29, 30, 33, 35, 37–39 |
| Wind/storm | 5, 32, 36, 41, 42 |
| Rain/showers/drizzle | 3, 11, 13–15, 24–27, 31, 45, 49 |
| Question mark | Unknown (53), missing, or a future unrecognized code |

Several distinct Garmin conditions share an icon; a snowflake is not a detailed precipitation-type report. Day/night only changes the clear and partly cloudy families, using calculated solar horizon status. If the icon disagrees with the sky, check Garmin's own weather observation and location before assuming a rendering fault; this face no longer displays observation age.

### UV versus rain chance

The rightmost weather field shows precipitation chance with an umbrella when `precipitationChance >= 30%`. Otherwise it shows rounded `uvIndex` with a `UV` label. If UV is unavailable, that branch shows `UV --`.

**Cloud cover is not the switching rule.** A cloudy observation with 10% precipitation chance still shows UV; a sunny observation with 40% precipitation chance shows rain chance. Neither the hourly nor daily forecast API is currently queried separately. This field comes entirely from `CurrentConditions`, and it may be hidden when the row cannot fit.

### Weather age and stale styling

The visible `WX` timer has been removed. The source still calculates elapsed minutes since Garmin's `observationTime` internally to detect stale weather. This is observation age, not time since the watch face last refreshed. A future timestamp is clamped to age zero; a missing timestamp means age is unknown.

When the known observation age is **more than 120 minutes**, weather icons are dimmed to half their blue intensity and main values switch to the slightly softer off-white. Small weather text remains bright. Cached old readings are not automatically replaced with blanks. Unknown age cannot trigger stale styling; normal colors are not proof of a fresh observation.

## Readability and typography

The entire former footer is removed, including battery and elevation data reads. These fields are not moved into another row. Daily floors climbed stays in the movement row. Reclaimed space allows larger text and icons and more separation between the two history charts, movement rows, and weather. Weather is now the last row; there is no lunar-event line beneath it.

All ordinary text uses Garmin's native `RobotoCondensedRegular`, with `RobotoRegular` fallback. If vector fonts are unavailable, built-in Garmin fonts are used. Requested native sizes are 92 pixels for the clock; 48/42/36 for larger values; and 26/24/22 for other values and labels. Font ascent is measured at layout time. Icon artwork alone uses the bundled bitmap glyph atlases, at 28 and 22 pixels; there is no custom bitmap text font.

Text colors remain bright: primary `#F1EBDF`, secondary `#E2DDD4`, and small units/labels `#DCD8D0`. Ring shading and below-horizon markers can be dim; the small labels and valid historical step bars are bright. The application does not change hardware brightness or screen timeout.

## Refresh, sleep, and practical limits

| Data or behavior | Current policy |
| --- | --- |
| Most metrics, date, weather, position and phase | On wake, then once per minute while awake |
| Main clock and live HR attempt | Each awake redraw supplied by Garmin |
| HR fallback history | At most once per 30 seconds; samples expire after five minutes |
| Four-hour HR and stress traces | Rebuilt together approximately every five minutes during full refreshes, or after clock rollback |
| Recovery and stress | Also reread after subscribed complication changes on an awake frame |
| Recovery wake confirmation | At most two extra native reads near +1s/+3s on normal awake frames; no timers or forced updates |
| Low-power update | Clear to black and return before data/astronomy work |
| Display off | Return without drawing or data work |
| A complication change while asleep | Mark data dirty for the next wake; do not wake the display |

Garmin owns display mode and redraw scheduling. SkyRing does not keep the screen awake with a timer, does not scroll, and has no always-on renderer. Current Sun/Moon positions are one-minute snapshots, not second-by-second animation. An actual high-power display mode overrides stale lifecycle flags to avoid the earlier stuck-black problem.

The current source deliberately excludes respiration, VO2 max, sleep/HRV status, training load, heat/altitude acclimation, Body Battery, SpO2, and a chest-strap connection indicator. Their absence is a scope/implementation fact, not a claim that every item is impossible in all Garmin apps or firmware versions.

Moonrise/set and next full/new-moon times were removed after an initial event search caused a watchdog crash, a bounded replacement still produced unsatisfactory missing/loading fields, and the added labels crowded the layout. Keeping only current position and phase removes that entire event-search and loading-state path. Native fonts and bright labels address the separate legibility problems. These decisions preserve a readable, basic watch face rather than adding data that cannot be presented reliably.

For the owner's on-watch confirmation, development checks, and remaining validation limits, see [VALIDATION.md](VALIDATION.md).

## Source and official API references

The source is authoritative for this guide: [`SkyRingView.mc`](../source/SkyRingView.mc) reads and draws the fields; [`Fmt.mc`](../source/Fmt.mc) holds formatting/colors; [`DaySteps.mc`](../source/DaySteps.mc), [`RecoveryTime.mc`](../source/RecoveryTime.mc), [`HistoryBuckets.mc`](../source/HistoryBuckets.mc), [`Astro.mc`](../source/Astro.mc), and [`Lunar.mc`](../source/Lunar.mc) provide the specialized calculations.

Relevant official API contracts, checked against the SDK documentation included with the development tools:

- [ActivityMonitor.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html) and [ActiveMinutes](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/ActiveMinutes.html): daily counters and weighted intensity minutes.
- [Activity.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/Activity/Info.html) and [SensorHistory](https://developer.garmin.com/connect-iq/api-docs/Toybox/SensorHistory.html): available current/history readings.
- [Complications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html): native subscribed recovery and stress values.
- [Weather](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html) and [CurrentConditions](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html): cached weather, units, condition codes, and observation time.
- [WatchFace](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html) and [System](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html): lifecycle, display mode, clock, and settings.
