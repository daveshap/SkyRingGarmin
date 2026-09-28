# Weather colors and alternating dew point — September 26–28, 2026

The September 28 release includes the original UV/dew-point features, corrected vivid weather colors, and the final rotation/contrast polish. The owner reported that the current build "all seems to work" and requested publication. See [RAW_HOURS_UPDATE.md](RAW_HOURS_UPDATE.md) for the raw-hours recovery change and [POLISH_UPDATE.md](POLISH_UPDATE.md) for the final display adjustments.

The weather work started from the watch-validated September 25 build, commit `15f0fdf10e00b5548edf1724d9d54d8fb63fd5ba`. `ChartColors.mc` provides UV category and condition-icon colors; `Fmt.mc` defines the fixed lavender dew-point color; `SkyRingView.mc` colors the readings, draws layered condition icons, and alternates humidity with native dew point. The icon generator and main icon atlas gained a dew-point glyph and two cloud overlays. The atlas grew from 24 to 27 glyphs within the same 256 × 128-pixel image. No additional row, text font, weather request, timer, or always-on renderer was added.

## September 28 color-selection fix

The owner tested the earlier Hours/Vivid candidate in Garmin's simulator and found the partly cloudy Sun was still off-white. The palette constants were correct, but the code used `==` to compare String objects across functions/modules. Those comparisons test identity rather than string contents. The weather mapping could therefore miss `p` and return the neutral default; the cloud-overlay checks could miss as well. This matches the single-color icon in the supplied screenshot.

The fix uses `String.equals()` in `ChartColors.condition()` and `drawConditionIcon()`. The nullable row fields use literal receivers, such as `"UV".equals(it[1])`, so UV and humidity/dew-point colors also work without null dereferences. The existing partly cloudy icon is drawn lemon yellow (`#FFF000`), then only its cloud outline is overlaid in cool silver (`#DCEBFF`). Its upper-left Sun pixels remain yellow. Moon, rain, snow and lightning retain their own accent colors under their cloud overlays.

Earlier JavaScript-adapted checks incorrectly treated string `==` as content equality, masking this Monkey C bug. The new focused regression check uses distinct boxed string objects and content comparisons, checks the actual drawing calls, and verifies the pre-fix implementation fails the same cases. Native Monkey C tests also construct strings at runtime so they cannot depend on shared literal identity. Host checks and generic compilation do not substitute for running the Garmin simulator.

This comparison fix changed no color constants, icon/font resources, geometry, recovery behavior, weather data acquisition, or wake/sleep code. The current release combines it with native raw-hour recovery, the September 26 weather features, and the final [rotation/contrast polish](POLISH_UPDATE.md). The superseded September 27 recovery complication/fallback implementation is absent.

Reference: [Garmin String.equals](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/String.html#equals-instance_function).

## Why and how

The existing blue label identifies weather but gives no clue to ultraviolet exposure risk. Color now supplies that clue in the same space. Use the standard EPA/NWS categories rather than borrowing the HR/stress thresholds:

| Displayed UV | Category | Color | Palette value |
| --- | --- | --- | --- |
| 0–2 | Low | Green | `#19E68C` |
| 3–5 | Moderate | Yellow | `#FFE338` |
| 6–7 | High | Orange | `#FF8A22` |
| 8–10 | Very high | Red | `#FF4048` |
| 11+ | Extreme | Purple | `#A64DFF` |

The `UV` label uses the saturated category color. The number uses a paler shade of the same color, blended 65% toward SkyRing's warm off-white (`#F1EBDF`), giving label and reading some contrast. The existing rounded whole-number reading selects the band, so a raw 2.5 displays as a yellow `UV 3`, not a green 3. The standard category hues use SkyRing's existing saturated RGB values for consistency on black. Missing, nonnumeric, and negative readings display neutral off-white `UV --`; measured zero remains valid.

Garmin's cached `CurrentConditions.uvIndex` remains the source. Colors describe that reading; they do not imply a fresh weather download or a personalized safe-exposure time. UV text keeps its hue even when the observation is old. Existing stale styling still applies to other weather items. Rain chance still replaces UV at 30% or higher, and the existing layout can still omit the last item if space is tight.

## Humidity / dew-point slot

The existing blue humidity droplet and percentage appear first on wake. After two seconds the same slot shows a lavender thermometer-and-drop icon and the dew-point temperature; after another two seconds it returns to humidity. The distinct shape and color identify the reading without adding a `DP` text label. The row reserves the wider reading's measured width and centers each form inside that slot, so adjacent temperature and UV/rain fields do not move merely because the phase changes.

Humidity uses glyph `D` and fixed vivid blue `ChartColors.WEATHER_HUMIDITY` (`#329BFF`). Dew point uses the new glyph `d` and fixed lavender `Pal.DEW` (`#B275FF`). When weather is not known to be stale, each number uses its icon's color blended 65% toward warm off-white (`#F1EBDF`). The icon remains more saturated than the reading. These colors identify the metric; they are not humidity or dew-point risk categories. When the observation is more than 120 minutes old, the moisture icons retain their full colors and the numbers use the existing soft off-white. UV text retains its cached-value risk colors at all ages.

Dew point comes directly from Garmin's cached `CurrentConditions.dewPoint` (Celsius, API 5.1.0), read with a `has` guard during the existing weather refresh. The display converts it to the watch's chosen Fahrenheit/Celsius units using the normal temperature formatter. Zero and negative values are valid. No estimate is calculated and no external service is contacted. If dew point is absent, humidity stays visible; if only dew point is available, it stays visible. If both are missing, the normal humidity placeholder remains.

Garmin calls watch-face `onUpdate()` once per second while in high-power mode. The face uses those existing callbacks to give each displayed selection at least two seconds before flipping once. It tracks the current selection explicitly instead of sampling elapsed time modulo four. Additional callbacks do not accelerate the cycle. Observed show/wake transitions and clock rollback restart at humidity. A delayed callback flips once when due, so four-second or minute-spaced frames cannot keep sampling the same phase. Data refreshes, resume-gap refreshes, and complication notifications do not reset the phase. If Garmin supplies no awake frame, rotation waits for the next one; the face does not extend the native high-power window. OFF and LOW_POWER guards still return before the new display logic; sleeping remains black. No timer, forced redraw, wake lock, or faster sensor/weather polling is introduced.

References: [Garmin CurrentConditions.dewPoint](https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather/CurrentConditions.html#dewPoint-var); [Garmin watch-face lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html).

## Weather-condition colors

The temperature-side condition icon now distinguishes its parts with color. This improves recognition without enlarging the row or changing the temperature number. Garmin's condition-code selection and existing clear/partly-cloudy day/night logic are unchanged.

| Icon or accent | Color | Hex |
| --- | --- | --- |
| Sun, partly cloudy Sun, thunderstorm lightning | Yellow | `#FFF000` |
| Moon, partly cloudy Moon | Lavender | `#BD80FF` |
| Cloud and cloud overlays | Silver | `#DCEBFF` |
| Fog/haze | Silver-teal | `#33E1C6` |
| Rain | Blue | `#258CFF` |
| Snow | Icy cyan | `#26E6FF` |
| Wind | Mint | `#34F0A0` |
| Unknown condition | Neutral off-white | `Pal.DIMMER`, `#DCD8D0` |

`ChartColors.condition()` selects the base color. `drawConditionIcon()` adds a silver cloud over partly cloudy Sun/Moon and over rain, snow, or thunderstorm icons, leaving the underlying Sun, Moon, precipitation, or lightning accent visible. The append-only atlas additions `g` and `k` supply those cloud layers; existing glyph identities are preserved. All weather icon layers retain their full identity color even when observations are stale. Temperature text keeps its previous styling. These colors describe Garmin's cached condition; they do not infer cloud cover or fetch another forecast.

## Build and validation

Build `monkey.jungle` for `fr965` with the same developer key and install as before; [BUILD_WINDOWS.md](BUILD_WINDOWS.md) has the complete steps. The September 25 commit above remains a rollback point. No generic test executable is supplied as an installable watch build.

Generic SDK 9.2.0 release compilation and source-derived checks passed, including colors, cloud layers, stable switching, native dew-point data, missing values, units, and awake timing. The 26 native test functions compiled but were not executed in the Garmin VM. The original 24 main glyphs retain their pixels and metrics; the three added glyphs fit the same 256 × 128 atlas. An actual-atlas composited preview was visually reviewed. These development checks are separate from the owner's September 28 confirmation of the current build. The local FR965 device profile remains unavailable, and performance and battery impact have not been measured. See [VALIDATION.md](VALIDATION.md) for the exact scope.

References: [EPA, A Guide to the UV Index](https://www.epa.gov/sites/default/files/documents/uviguide.pdf); [NWS UV categories](https://www.weather.gov/ilx/uv-index).
