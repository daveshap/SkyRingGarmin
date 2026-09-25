# SkyRing Garmin

A personal **Forerunner 965** watch face: a sky ring around a compact dashboard of activity, recovery, and weather. Built in Garmin Connect IQ / Monkey C for the 454 × 454 AMOLED display.

The current design keeps native, readable text; large icons beside numbers; fixed colors for recognition; bright small labels; and a black sleeping display. Data comes from Garmin's APIs and local astronomy calculations. There is no external account, API key, companion service, or always-on renderer.

<p align="center">
  <img src="SkyRing%20Final.png" alt="SkyRing watch face for the Garmin Forerunner 965" width="454">
</p>

## What is on the face

- **Sky:** current Sun and Moon positions, phase-changing Moon disc, twilight/daylight ring, colorful sunrise/sunset icons and times, solar time, solar altitude, time until the next sun event, and estimated daily peak solar altitude.
- **Body:** heart rate with a four-hour trace, Garmin stress with a segmented indicator, and native recovery time.
- **Movement:** today's steps, seven daily step bars and their total, weekly intensity minutes against Garmin's goal, calories, and floors climbed.
- **Weather:** condition icon, temperature, optional high/low, humidity, and UV or rain probability.
- **Footer:** weather-observation age, battery, and elevation when space allows. Clock and date follow the watch's settings.

`7d` means **today plus the previous six local calendar dates**, not the last 168 hours. `7d*` marks incomplete history. `WX 30m` is the observation's age, not a promised refresh interval. The ring represents **hour angle**, not compass direction or a literal horizon: marker brightness separately indicates whether the body is above or below the calculated horizon.

## Build on Windows

Install Garmin's Connect IQ SDK and the FR965 device profile, Java 11 or newer, VS Code, and Garmin's Monkey C extension. Open **this repository's root folder**, build for `fr965` with your developer key, and test in the simulator. Copy the resulting `.prg` into the watch's `GARMIN/APPS/` folder to sideload.

Use the complete [Windows setup and install guide](docs/BUILD_WINDOWS.md) for the exact steps, test commands, and troubleshooting. Keep the signing key outside the repository. Source and icon resources are included; a prebuilt watch binary is not.

## Documentation

| Guide | What it explains |
| --- | --- |
| [Every display element](docs/DISPLAY_GUIDE.md) | What each number, icon, chart, and color means; how it is obtained; why it is included; missing/stale data and fit rules. |
| [Architecture and maintenance](docs/ARCHITECTURE.md) | Source map, lifecycle, refresh schedule, native APIs, permissions, layout, and editing constraints. |
| [Findings and limitations](docs/FINDINGS_AND_LIMITATIONS.md) | What worked, what failed, what was removed, and what remains unknown. |
| [Sun and Moon calculations](docs/LUNAR_CALCULATIONS.md) | Time/location conventions, rim mapping, lunar phase, horizon shading, reference values, and accuracy limits. |
| [Build, test, and sideload on Windows](docs/BUILD_WINDOWS.md) | Prerequisites, simulator/device builds, signing, optional checks, and common build issues. |
| [Validation record](docs/VALIDATION.md) | Exact checks completed and the boundary between source checks and actual Garmin execution. |

## Current scope and status

The imported source is the **simplified SkyRing build** developed after RowWatch. It removes moonrise/moonset and next-full/new-moon dates, including the event-search machinery that caused a watchdog crash and later unreliable loading fields. Current Sun/Moon position and current phase remain. The footer's earlier spacing is restored; the brighter text and colorful sun-event icons are retained.

HRV, sleep data, VO2 max, exercise load, acclimation, and chest-strap connection state are **not displayed**. Body Battery, SpO2, and respiration are deliberately absent. Reasons and API caveats are documented in the findings guide; absence from this build is not a blanket claim that Garmin can never expose a metric.

Previous development versions were reported working on the owner's FR965. This exact simplified source passes generic Connect IQ release/test compilation and source-derived position/geometry checks. **It has not yet been confirmed on the FR965 simulator or watch in the development environment.** There is no measured battery-life or watchdog-headroom claim.

## Repository contents

`source/` holds the Monkey C modules; `resources/` contains the launcher and two icon atlases; `tests/` contains 14 Monkey C tests. `tools/check_rim_positions.js` replays position and drawing arithmetic outside Garmin's VM. `tools/gen_icons.py` regenerates icon artwork only; normal builds use the committed resources. `monkey.jungle` builds the face; `monkey-tests.jungle` adds the native tests.

The project targets only `fr965` and declares minimum API 4.2.0. Other devices and languages have not been validated. Start from a fresh checkout when upgrading from older ZIP versions so removed source files cannot remain in the build.
