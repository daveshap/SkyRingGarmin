# Raw recovery hours and vivid weather — September 28, 2026

**Included follow-ups:** the weather-color fix corrects String identity comparisons that could bypass this palette, and the polish update improves contrast and rotation and restores READY at zero hours. See [WEATHER_UPDATE.md](WEATHER_UPDATE.md#september-28-color-selection-fix) and [POLISH_UPDATE.md](POLISH_UPDATE.md). All are included in the September 28 owner-confirmed release.

This change started from the September 27 recovery package. Its September 26 weather features were verified against the original ZIP, including the icon resources, UV risk colors, paler UV reading, native dew-point data, unique humidity/dew-point icons, and two-second awake switching. The current source also includes the subsequent color-selection and polish corrections.

## Recovery uses a single source

The user requested raw hours after the minute complication continued showing `1m`. SkyRing now reads only `ActivityMonitor.getInfo().timeToRecovery`, which Garmin documents as whole hours and supports on the FR965. The displayed integer is the returned value: 0 becomes `0h`, 1 becomes `1h`, and 7 becomes `7h`. The latest polish restores the requested `READY` caption for zero, keeping `0h` visible. Positive or missing data keeps `RECOVERY`. This is a caption rule on the native whole-hour value, not a new minute-level calculation.

Null, missing, malformed, or negative data shows `--`. Each read clears the previous result, so a failed read cannot preserve an old value indefinitely. Reads occur at normal wake/minute refreshes while awake. Stress callbacks do not trigger additional recovery reads.

Removed: recovery complication ID and subscription; minute formatting; fallback arbitration; first-frame suppression; the +1/+3-second retry state; and paired-source debug logging. There is no private countdown or background polling. This bypasses the problematic minute source; it does not prove why that source returned 1. The earlier investigation remains as a historical record.

Official reference: [ActivityMonitor.Info.timeToRecovery](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html#timeToRecovery-var). The direct source may have different rounding/update timing from the built-in recovery glance; raw hours are used as requested.

## Vivid icon palette

| Icon or accent | Color | RGB |
| --- | --- | --- |
| Sun / lightning | Saturated lemon yellow | `#FFF000` |
| Moon | Vivid lavender | `#BD80FF` |
| Clouds | Bright cool silver | `#DCEBFF` |
| Fog / haze | Teal | `#33E1C6` |
| Rain / umbrella | Saturated blue | `#258CFF` |
| Snow | Cyan | `#26E6FF` |
| Wind | Bright mint | `#34F0A0` |
| Relative humidity | Vivid blue | `#329BFF` |
| Dew point | Violet | `#B275FF` |

The same lemon sun color is used for the moving rim marker, solar-time icon, peak-sun icon, and sunrise/sunset sun arcs. Sunrise keeps its orange horizon/arrow and sunset its blue horizon/arrow. Solar numbers, temperature text, the sky-ring gradient, and lunar phase geometry keep their existing behavior.

Compound weather icons keep a silver cloud with a separately colored sun, moon, rain, snow, or lightning accent. Weather icons no longer dim with observation age; they retain consistent, vivid identity colors. The existing softer stale-weather reading text remains. The below-horizon astronomical Sun still dims to show its horizon state, independently of the weather icon.

No icon atlas or text font was regenerated. No widget was moved or resized. Sleep remains black under Garmin's normal display lifecycle. UV categories and paler UV numbers, humidity/dew-point rotation, seven-day steps, HR/stress histories, and all sky calculations are retained.

## Build and status

Extract into a fresh folder and build `monkey.jungle` for `fr965` with the same developer key and installed `.prg` filename as before. This avoids accidentally building an older extracted project. No prebuilt generic executable is included.

The owner reported that the current polish build "all seems to work" on September 28 and requested this publication. Its runtime and resources are preserved. Generic compilation and source-derived checks are recorded in [VALIDATION.md](VALIDATION.md); local FR965 simulator execution and quantitative performance/battery measurements remain unavailable. The original cause of the minute-source discrepancy remains unproved; the current face no longer uses that source.
