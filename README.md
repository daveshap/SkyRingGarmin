# SkyRing Garmin

A personal **Forerunner 965** watch face: a sky ring around a compact dashboard of activity, recovery, and weather. Built in Garmin Connect IQ / Monkey C for the 454 × 454 AMOLED display.

The current design keeps native, readable text; large icons beside numbers; fixed colors for recognition; bright small labels; and a black sleeping display. Data comes from Garmin's APIs and local astronomy calculations. There is no external account, API key, companion service, or always-on renderer.

<p align="center">
  <img src="SkyRing%20Final.png" alt="SkyRing watch face for the Garmin Forerunner 965" width="454">
</p>

The image above shows an earlier version. The current build adds colored history charts and larger readings, and removes the bottom status row.

## September 25 update

The owner installed this build on a physical Forerunner 965 and confirmed that it works, including stress history. The published application source and resources match that tested build.

- **Colored HR and stress histories:** both show the previous four hours. Stress history replaces the meter because the number already gives the current score; the trace adds the trend.
- **Daily step-goal colors:** the seven step bars stay green below each day's recorded goal and turn yellow when that goal is met. No extra goal labels.
- **More readable layout:** the WX-age, battery, and elevation footer is removed. Larger native text, larger icons, and more vertical spacing give priority to the remaining readings. Floors climbed stays.
- **Recovery refresh:** a bounded confirmation after wake reduces exposure to a transient first positive reading. Zero displays immediately. The reported morning `1m` blip has not yet been independently reproduced or conclusively resolved.

See [release notes](docs/RELEASE_NOTES.md) for the reasoning, exact thresholds, data rules, and rollback reference.

## What is on the face

- **Sky:** current Sun and Moon positions, phase-changing Moon disc, twilight/daylight ring, colorful sunrise/sunset icons and times, solar time, solar altitude, time until the next sun event, and estimated daily peak solar altitude.
- **Body:** heart rate and Garmin stress with matching four-hour colored traces, and native recovery time.
- **Movement:** today's steps, seven daily step bars and their total, weekly intensity minutes against Garmin's goal, calories, and floors climbed.
- **Weather:** condition icon, temperature, optional high/low, humidity, and UV or rain probability.

Clock and date follow the watch's settings. The former WX-age, battery, and elevation footer is removed to give the remaining readings more room.

`7d` means **today plus the previous six local calendar dates**, not the last 168 hours. `7d*` marks incomplete history. Weather observation age is still checked internally for stale styling, but is no longer displayed. The ring represents **hour angle**, not compass direction or a literal horizon: marker brightness separately indicates whether the body is above or below the calculated horizon.

## Reading the histories

The charts group native Garmin history into 24 ten-minute averages, oldest on the left and newest on the right, and refresh about every five minutes while awake. Missing observations stay gaps; a measured stress score of zero is valid. Current stress comes from a separate native reading and is never copied into missing history.

| Color | Heart rate, BPM | Stress, rounded average |
| --- | --- | --- |
| Purple | Below 60 | 0–14 |
| Blue | 60–under 70 | 15–25 |
| Green | 70–under 90 | 26–50 |
| Yellow | 90–under 110 | 51–65 |
| Orange | 110–under 130 | 66–75 |
| Red | 130+ | 76–100 |

Chart heights scale to the available readings, but these color thresholds stay fixed. They are display bands, not personalized heart-rate zones or sleep-stage detection. Icons and current readings keep their established colors.

**Simulator note:** the owner saw a blank stress trace in the SDK 9.2.0 simulator, then confirmed it worked on the watch. A [report from another SDK 9.2.0 user](https://forums.garmin.com/developer/connect-iq/f/connect-iq-web-store/441912/emulator-sets-sensor-history-samples-time-into-future) describes future-dated stress-history samples, which this face correctly excludes. That is consistent with the symptom; the owner's raw simulator timestamps were not captured. No timestamp workaround or diagnostic code was added to this release.

## Build on Windows

Install Garmin's Connect IQ SDK and the FR965 device profile, Java 11 or newer, VS Code, and Garmin's Monkey C extension. Open **this repository's root folder**, build for `fr965` with your developer key, and test in the simulator. Copy the resulting `.prg` into the watch's `GARMIN/APPS/` folder to sideload.

Use the complete [Windows setup and install guide](docs/BUILD_WINDOWS.md) for the exact steps, test commands, and troubleshooting. Keep the signing key outside the repository. Source and icon resources are included; a prebuilt watch binary is not.

## Documentation

| Guide | What it explains |
| --- | --- |
| [Release notes](docs/RELEASE_NOTES.md) | What changed, why, exact color and history logic, recovery behavior, and the previous baseline. |
| [Every display element](docs/DISPLAY_GUIDE.md) | What each number, icon, chart, and color means; how it is obtained; why it is included; missing/stale data and fit rules. |
| [Architecture and maintenance](docs/ARCHITECTURE.md) | Source map, lifecycle, refresh schedule, native APIs, permissions, layout, and editing constraints. |
| [Findings and limitations](docs/FINDINGS_AND_LIMITATIONS.md) | What worked, what failed, what was removed, and what remains unknown. |
| [Sun and Moon calculations](docs/LUNAR_CALCULATIONS.md) | Time/location conventions, rim mapping, lunar phase, horizon shading, reference values, and accuracy limits. |
| [Build, test, and sideload on Windows](docs/BUILD_WINDOWS.md) | Prerequisites, simulator/device builds, signing, optional checks, and common build issues. |
| [Validation record](docs/VALIDATION.md) | Exact checks completed and the boundary between source checks and actual Garmin execution. |

## Current scope and status

This release continues the **simplified SkyRing build** developed after RowWatch. Moonrise/moonset and next-full/new-moon dates remain removed, including the event-search machinery that caused a watchdog crash and later unreliable loading fields. Current Sun/Moon position and current phase remain. The footer is now removed; the brighter text and colorful sun-event icons are retained.

HRV, sleep data, VO2 max, exercise load, acclimation, and chest-strap connection state are **not displayed**. Body Battery, SpO2, and respiration are deliberately absent. Reasons and API caveats are documented in the findings guide; absence from this build is not a blanket claim that Garmin can never expose a metric.

The owner confirmed this history/readability build working on the FR965 on September 25, 2026. Generic SDK compilation and source-derived host checks also passed; 29 native test functions compiled but were not executed in Garmin's VM here. **The FR965 simulator/profile is unavailable in the development environment.** The watch confirmation is a functional check, not a measured battery-life, watchdog-headroom, or exhaustive lifecycle claim. The morning recovery discrepancy remains an observation to recheck.

## Repository contents

`source/` holds the Monkey C modules; `resources/` contains the launcher and two icon atlases; `tests/` contains Monkey C regression tests. `tools/check_candidate.js` checks helper logic outside Garmin's VM (the filename is retained from pre-release testing); `tools/check_rim_positions.js` checks sky-position arithmetic. `tools/gen_icons.py` regenerates icon artwork only; normal builds use the committed resources. `monkey.jungle` builds the face; `monkey-tests.jungle` adds the native tests.

The project targets only `fr965` and declares minimum API 4.2.0. Other devices and languages have not been validated. Start from a fresh checkout when upgrading from older ZIP versions so removed source files cannot remain in the build.
