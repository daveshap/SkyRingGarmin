# SkyRing Garmin

A personal **Forerunner 965** watch face: a sky ring around a compact dashboard of activity, recovery, and weather. Built in Garmin Connect IQ / Monkey C for the 454 × 454 AMOLED display.

**Current release: September 28, 2026.** The owner confirmed the latest build works and approved publication. Application source and resources match the tested `SkyRing_Polish_2026-09-28.zip`; publication updates the documentation. The previous published release remains available at [15f0fdf](https://github.com/daveshap/SkyRingGarmin/commit/15f0fdf10e00b5548edf1724d9d54d8fb63fd5ba).

SkyRing uses native, readable text; large icons beside numbers; fixed colors for recognition; bright small labels; and a black sleeping display. Data comes from Garmin's APIs and local astronomy calculations. There is no external account, API key, companion service, or always-on renderer.

<p align="center">
  <img src="SkyRing%20Final.png" alt="SkyRing watch face for the Garmin Forerunner 965" width="454">
</p>

This image shows an earlier layout. The current build has colored HR/stress histories, larger readings, alternating humidity/dew point, and vivid weather icons. The bottom battery/weather-age/elevation row has been removed.

## What is on the face

| Area | Information |
| --- | --- |
| Sky | Current Sun and Moon positions, phase-changing Moon disc, twilight/daylight ring, colorful sunrise/sunset times, solar time and altitude, next sun-event countdown, estimated daily peak solar altitude. |
| Body | Current heart rate and stress, their four-hour colored histories, native recovery hours. |
| Movement | Today's steps, seven daily step bars and their total, weekly intensity minutes against Garmin's goal, calories, floors climbed. |
| Weather | Colorful condition icon, temperature, optional high/low, alternating relative humidity/dew point, UV risk or rain probability. |

Clock and date follow the watch's settings. `7d` means **today plus the previous six local calendar dates**; `7d*` marks incomplete history. Weather is Garmin's cached observation. The ring represents **hour angle**; marker brightness separately indicates whether the body is above or below the calculated horizon.

## September 28 changes

- **Recovery:** reads `ActivityMonitor.Info.timeToRecovery` directly in whole hours. Zero displays `0h` with **READY**; positive hours retain **RECOVERY**; unavailable data shows `--`. Recovery-minute complications, local countdowns, deliberate blanking, and wake retries are removed.
- **Weather icons:** lemon-yellow Sun and lightning; lavender Moon; silver clouds; blue rain; cyan snow; teal fog; mint wind. Compound icons have separate colored accents and silver cloud layers. The String comparison bug that bypassed these colors is fixed.
- **Humidity and dew point:** share a stable-width slot with distinct blue-droplet and violet thermometer/drop icons. Normal awake updates alternate every two seconds. The selected reading persists across data refreshes; delayed frames switch once when due instead of repeatedly restarting humidity.
- **UV and contrast:** saturated UV labels follow standard risk categories, while their numbers are paler. Humidity, dew-point, and UV numbers blend 65% toward warm off-white. Rain probability replaces UV at 30% or higher.
- **Power behavior:** uses normal awake callbacks and cached native weather. No timer, faster polling, display-timeout override, or always-on drawing was added.

See [release notes](docs/RELEASE_NOTES.md), [weather details](docs/WEATHER_UPDATE.md), [recovery rationale](docs/RAW_HOURS_UPDATE.md), and [the final polish](docs/POLISH_UPDATE.md) for the implementation and reasoning.

## Reading the histories

HR and stress traces show the previous four hours as 24 ten-minute averages, oldest on the left, and refresh about every five minutes while awake. Missing observations remain gaps; measured stress zero is valid. Current stress is read separately and is never copied into missing history.

| Color | Heart rate, BPM | Stress, rounded average |
| --- | --- | --- |
| Purple | Below 60 | 0–14 |
| Blue | 60–under 70 | 15–25 |
| Green | 70–under 90 | 26–50 |
| Yellow | 90–under 110 | 51–65 |
| Orange | 110–under 130 | 66–75 |
| Red | 130+ | 76–100 |

Chart heights scale to available readings; color thresholds stay fixed. These are display bands, not personalized heart-rate zones or sleep-stage detection. Each daily step bar is green below its recorded goal and yellow at or above it. An unavailable historical goal does not inherit today's goal.

**Simulator note:** the owner saw a blank stress trace in the SDK 9.2.0 simulator, then confirmed it worked on the watch. A [separate SDK 9.2.0 report](https://forums.garmin.com/developer/connect-iq/f/connect-iq-web-store/441912/emulator-sets-sensor-history-samples-time-into-future) describes future-dated stress samples, which SkyRing excludes. That is consistent with the symptom; the owner's simulator timestamps were not captured. No timestamp workaround is included.

## Build on Windows

Install Garmin's Connect IQ SDK and the FR965 device profile, Java 11 or newer, VS Code, and Garmin's Monkey C extension. Open the repository root, build for `fr965` with your developer key, and copy the resulting `.prg` into the watch's `GARMIN/APPS/` folder to sideload.

Use the [Windows setup and install guide](docs/BUILD_WINDOWS.md) for detailed steps. Keep the signing key outside the repository. Source and icon resources are included; no prebuilt watch binary is supplied. When upgrading an older ZIP, use a fresh folder so removed source files cannot remain in the build.

## Documentation

| Guide | Contents |
| --- | --- |
| [Release notes](docs/RELEASE_NOTES.md) | Changes, reasoning, release history, and rollback reference. |
| [Display guide](docs/DISPLAY_GUIDE.md) | Every icon, number, chart, color, data source, and missing-data rule. |
| [Weather update](docs/WEATHER_UPDATE.md) | Conditions, UV categories, dew point, String comparison fix, and rotation. |
| [Raw recovery hours](docs/RAW_HOURS_UPDATE.md) | Source choice, previous recovery failures, and vivid palette. |
| [Final polish](docs/POLISH_UPDATE.md) | Delayed-frame rotation fix, paler numbers, and READY caption. |
| [Architecture](docs/ARCHITECTURE.md) | Source map, lifecycle, refresh schedule, native APIs, permissions, and layout. |
| [Findings and limitations](docs/FINDINGS_AND_LIMITATIONS.md) | What worked, failed, or was removed, with remaining uncertainty. |
| [Sun and Moon calculations](docs/LUNAR_CALCULATIONS.md) | Time/location conventions, rim positions, phase, horizon shading, and accuracy. |
| [Windows build guide](docs/BUILD_WINDOWS.md) | Setup, simulator, signing, tests, and sideloading. |
| [Validation record](docs/VALIDATION.md) | Owner acceptance, build checks, host regression results, and historical investigations. |

## Scope and validation

The September 28 build is the current owner-confirmed working version. Generic SDK 9.2.0 release and test compilations passed; 26 native test functions compiled. Source-derived host checks pass for data handling, colors, rotation, recovery, and wake/sleep guards. The development environment lacks the FR965 profile/simulator, so it did not execute native tests in Garmin's VM. Owner acceptance is a functional observation; battery life and exhaustive firmware behavior have not been measured.

Current Sun/Moon position and lunar phase remain. Moonrise/moonset and next-full/new-moon dates remain removed, along with the event-search machinery that caused a watchdog crash and unreliable loading fields. The former battery/weather-age/elevation footer is removed to give priority to the remaining readings. Floors climbed stays.

HRV, sleep data, VO2 max, exercise load, acclimation, and chest-strap connection state are not displayed. Body Battery, SpO2, and respiration are deliberately absent. The findings guide records the decisions and API caveats.

The project targets only `fr965` and declares minimum API 4.2.0. Other devices and languages have not been validated.

## Repository contents

`source/` holds the Monkey C modules; `resources/` contains the launcher and icon atlases; `tests/` contains native regression tests. Text uses Garmin's native fonts; the bitmap resources contain icons only.

`tools/check_candidate.js` checks source-derived helper and lifecycle logic; `tools/check_weather.js` checks weather drawing with distinct string objects, rotation, and the prior color-selection failure; `tools/check_rim_positions.js` checks astronomy arithmetic. These host checks run outside Garmin's VM. `tools/gen_icons.py` regenerates icons when needed; normal builds use the committed resources. `monkey.jungle` builds the face; `monkey-tests.jungle` adds native tests.
