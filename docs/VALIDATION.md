# Validation — current release and development history

## October 6, 2026 — moisture-rotation refactor candidate

The owner reported that the restored dual-clock layout looks good, but humidity/dew point still stop alternating. The new candidate separates selection/dwell from drawing, uses monotonic milliseconds, and adds one permitted awake-only timer. The changes address reproducible callback-reset and missing-redraw weaknesses. They do not establish the exact cause on the owner's watch because no instrumented callback trace was supplied.

Generic release compilation passed with Connect IQ SDK 9.2.0 and Java 17, with the expected warning that the local `fr965` device profile is absent. Runtime changes are `SkyRingView.mc` and new `MoistureRotation.mc`; the preview and visual design are unchanged. All four source-derived host suites passed: `node tools/check_candidate.js`, `node tools/check_weather.js`, `node tools/check_weather_rotation.js`, and `node tools/check_rim_positions.js`. The new scheduler suite reproduces the callback reset using the exact prior `ad4773b` source fixture, then checks timer-only redraw delivery, native-first and timer-first callback ordering, repeated wake/show callbacks, delayed frames, pause/resume, unavailable readings, monotonic-counter wrap, and civil-clock changes. It also covers queued ticks after stop, missing sleep callbacks with physical OFF/LOW mode, and a late sleep callback while the display reports HIGH_POWER: rendering remains available while timer permission stays revoked. These checks execute adapted production state/update/lifecycle methods with mocked platform scheduling, not Garmin's VM. Earlier PASS results in this file refer to their dated source versions; they must not be read as validation of this new scheduler. Garmin VM execution, physical-watch behavior, battery impact, and callback-time measurements remain unverified. The source-derived checks use mocked scheduling and display modes, which cannot prove firmware timing.

Required watch check: with both cached moisture readings available, observe several two-second switches during a normal wake, let the face sleep, and wake it repeatedly. Confirm that rotation resumes from its preserved selection and that sleep remains black. A paused slot after Garmin ends the permitted high-power window is distinct from an active-window stall. See [WEATHER_ROTATION_UPDATE.md](WEATHER_ROTATION_UPDATE.md).


## October 6, 2026 — restored dual-clock candidate

Runtime source reconstructed from the complete October 2 `SkyRingView.mc` diff, applied to published baseline `0c16b2b`. All other runtime files, resources, manifest, and build configuration are retained. Documentation and preview are regenerated; this is not a byte-for-byte claim about the expired ZIP. Saved to a candidate branch for watch testing, with the working `main` release preserved. The recreated full-face illustration replays actual candidate drawing methods with the icon atlases and a desktop font surrogate; it was visually checked. It is not a simulator screenshot.

Historical October 2 checks: generic SDK 9.2.0 release compilation passed; existing data/weather host checks passed; nine header cases passed overlap/circular-content checks with desktop Roboto Condensed Regular as a font surrogate. These checks were not Garmin VM or physical-watch validation. Fresh restoration checks: all three `tools/check_candidate.js`, `tools/check_weather.js`, and `tools/check_rim_positions.js` passed. Independent comparison confirms the recorded header patch is the only runtime change and all other runtime/resources/build files match the baseline. Fresh generic release compilation also passed with Connect IQ SDK 9.2.0 and Java 17.0.20. The expected missing-`fr965`-profile warning remains; no generic output is included for installation. Garmin VM and physical-watch validation remain pending.

## October 2, 2026 — Moon horizon restoration and publication

The owner requested publication of the working version after delivery of the September 30 Moon-horizon candidate. The publication is based on the September 28 repository commit [`e784b10c50597fd234c242d24eb8779307d5b6ca`](https://github.com/daveshap/SkyRingGarmin/commit/e784b10c50597fd234c242d24eb8779307d5b6ca), with the recorded September 30 source/test patch restored. Workspace maintenance had removed the unpublished candidate folder and ZIP. This is a source restoration, not a byte-for-byte claim about that lost ZIP or its checksum.

The earlier September 30 delivery recorded successful generic release and native-test compilation (30 native test functions compiled), existing source-derived regressions, and full-day Moon-motion checks. These are dated development results; compilation does not execute those tests in Garmin's VM. The user's October 2 publication instruction supplies release authorization, but no instrumented device log or measured runtime/battery result was supplied.

The runtime change adds `Astro.moonRingAngle()` and uses `moonRing` for Moon placement. It leaves the lunar ephemeris and phase, solar ring, weather/recovery data paths, and wake/sleep behavior intact. Regression cases cover the September 30 10 a.m. Hillsborough mismatch, both horizon sides, above/below placement, transit and degenerate projection, and the earlier pre-rise observation. [Meaning and limits](MOON_HORIZON_UPDATE.md).

October 2 checks against the restored publication source:

- Generic Connect IQ SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**.
- Generic native-test compilation: **BUILD SUCCESSFUL**, 30 test functions compiled.
- `node tools/check_candidate.js`: **PASS** for existing data, recovery, lifecycle, history, and color regressions.
- `node tools/check_weather.js`: **PASS** for weather String comparison, vivid layered icons, UV contrast, and humidity/dew-point rotation.
- `node tools/check_rim_positions.js`: **PASS**, including restored Moon regression tests and full-day motion at five locations across two seasonal dates.
- The missing `fr965` profile warning remains. These are generic compilation and source-derived host execution, not native Garmin VM execution. No battery or callback-time measurement is claimed.

The dated records below describe their own versions. Current display semantics are in [DISPLAY_GUIDE.md](DISPLAY_GUIDE.md) and [LUNAR_CALCULATIONS.md](LUNAR_CALCULATIONS.md).


## September 28, 2026 — owner acceptance and publication (historical release)

The owner reported that the latest polish build appears to work and explicitly requested publication. This was the published baseline before the Moon correction. The application source, resources, tests, build configuration, and tools match the delivered `SkyRing_Polish_2026-09-28.zip`; only README/documentation were edited for publication.

Delivered ZIP SHA-256: `8db70a4ff41eed03c30a38aee5b808cd074384dc371988d7286df1305ab6c14f`.

- Generic SDK 9.2.0 release and test builds passed during candidate preparation; 26 native test functions compiled. The delivered files and publication copy were compared byte for byte, so no application rebuild was needed for documentation-only publication.
- Both `node tools/check_candidate.js` and `node tools/check_weather.js` passed again against the publication copy. Coverage includes raw recovery hours and READY, null/error handling, cached histories, awake/sleep gates, vivid compound icons, UV risk colors, paler readings, two-second moisture dwell, delayed/duplicate frames, rollback, and missing weather data.
- Weather rotation was exercised through 120 seconds of one-second host callbacks and through 4/8/60-second callback gaps. The face adds no timer or always-on renderer.
- Earlier condition-color tests had incorrectly inherited JavaScript string equality semantics. The focused weather check now models distinct string objects and proves that reverting to the former comparisons fails the color test.
- The local FR965 profile/simulator remains unavailable. No local Garmin VM test execution, measured battery-life study, or exhaustive firmware validation is claimed. The acceptance report does not identify the exact source of every earlier native recovery discrepancy or callback stall.

Previous published baseline and rollback: [`15f0fdf10e00b5548edf1724d9d54d8fb63fd5ba`](https://github.com/daveshap/SkyRingGarmin/commit/15f0fdf10e00b5548edf1724d9d54d8fb63fd5ba).

**The sections below preserve dated development records.** Candidate/pending-validation wording, test counts, and implementation descriptions in those records refer to those earlier versions. The release status above supersedes their publication status. Current behavior is documented in [DISPLAY_GUIDE.md](DISPLAY_GUIDE.md), [WEATHER_UPDATE.md](WEATHER_UPDATE.md), and [POLISH_UPDATE.md](POLISH_UPDATE.md).

## September 28 polish: rotation, contrast, READY

- Generic SDK 9.2.0 release and native-test compilation: **BUILD SUCCESSFUL**, 26 native test functions compiled. The existing missing-fr965-profile warning remains; native tests were not run in Garmin's VM.
- `node tools/check_candidate.js`: **PASS**. Zero raw hours produces `0h` with READY, positive hours retain RECOVERY, and invalid data stays unknown. Actual update wiring preserves the rotation through minute refreshes and delayed awake frames, freezes it during OFF/LOW, and resets it on observed wake.
- `node tools/check_weather.js`: **PASS**. Actual weather source rotates at 1 Hz for 120 seconds without stopping; late frames at 4/8/60-second intervals flip once instead of pinning one phase. Duplicate frames hold the selection; rollback resets it. Missing values remain placeholders, not invented readings.
- Weather checks retain content-equality regression coverage and the yellow Sun/silver cloud rendering calls. RH/dew/UV values now use the 0.65 pale blend; saturated icons and UV labels remain unchanged. Missing/zero/negative dew, stable neighboring positions, stale styles, and rain priority pass.
- Runtime edits are limited to `RecoveryTime.mc` and `SkyRingView.mc`. Font/icon resources, manifest, data readers, astronomy, wake/sleep guards, and build configuration are unchanged.

The exact callback cadence behind the user's observed stall was not captured. The checks reproduce and remove the frame-gap reset and modulo-alias weaknesses; they do not prove Garmin will keep delivering awake updates after its normal high-power window. No timer, always-on renderer, or timeout override was added. This candidate needs its own simulator/watch confirmation. Nothing has been pushed to GitHub.


## September 28 follow-up: weather color selection

The owner supplied a Garmin simulator screenshot of the earlier Hours/Vivid candidate: the partly cloudy icon was off-white and the UV label remained blue. The source had String identity comparisons where content comparisons were needed. This follow-up fixes those comparisons in the condition palette, cloud overlays, and nullable weather row classifications.

- Generic SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**.
- Generic native-test compilation: **BUILD SUCCESSFUL**, 26 test functions. Two new tests cover runtime-created condition strings and UV category boundaries. Garmin VM execution is not claimed.
- `node tools/check_candidate.js`: **PASS**, preserving raw recovery hours, histories/goals, and awake/sleep behavior.
- `node tools/check_weather.js`: **PASS**. The focused adapter boxes source literals and input strings separately, preserving identity differences. Changing the production palette comparisons back to `==` reproduces the neutral-color fallback; the fixed source selects lemon yellow.
- Actual-source drawing calls: all condition families and all five compound icons select their correct base color and cloud layer. Null-safe UV/RH/dew classification, paler UV numbers, two-second rotation, stale colors, stable neighboring fields, missing/zero/negative dew, and the rain threshold pass.
- Bundled icon masks composited and visually inspected: the partly cloudy Sun retains saturated yellow pixels after its silver cloud overlay. This is an atlas preview, not a Garmin simulator screenshot.
- Runtime diff: only string comparisons and explanatory comments in `ChartColors.mc` and `SkyRingView.mc`. Every resource, font, other runtime module, manifest, and Jungle file is identical to the earlier Hours/Vivid candidate.
- The local FR965 profile remains unavailable; generic builds emit the existing missing-profile warning. The corrected candidate still needs the owner's Garmin simulator/watch check. Nothing was pushed to GitHub.

**Correction to earlier weather validation:** JavaScript primitive string equality masked Monkey C's String identity behavior. The previous host PASS results did not establish correct weather-color routing on Garmin. The focused check above addresses that specific test gap; it is still not a Garmin VM emulator.


## September 28, 2026 raw-hours and vivid-weather candidate

- Generic SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**.
- Generic native-test compilation: **BUILD SUCCESSFUL**, 24 test functions. Compilation does not execute Garmin's test VM.
- `node tools/check_candidate.js`: **PASS**. Actual-source checks cover raw0h/1h/7h, invalid/missing values, clearing on read errors, wake/minute refresh, stress callback isolation, OFF/LOW_POWER guards, clock rollback, and absence of the recovery complication/minute/retry/debug path. Existing history and goal checks also pass.
- Independent actual-source weather checks: **PASS** for every condition family and compound overlay at observation ages0/120/121/300minutes, full-strength icon palettes, unchanged temperature text, paler UV numbers, rain threshold29/30%, two-second humidity/dew-point phases, stable neighboring positions, and zero/negative/missing dew point.
- Icon-mask compositing visually reviewed; no icon resource/font changes. This is artwork review, not a Garmin-rendered screenshot.
- Original September26 and September27 ZIP comparison confirms that the latter included the former's weather resources, palette, UV colors, and dew-point changes. The new candidate retains those features with the vivid palette.
- Both generic builds report the expected missing-fr965-profile warning. No local FR965 simulator or physical-watch validation is claimed. Build for fr965 with the owner's key before installation.

This candidate displays the native hourly source directly and bypasses recovery complications. It does not claim a Garmin firmware fix. Current behavior: [RAW_HOURS_UPDATE.md](RAW_HOURS_UPDATE.md). All earlier sections below describe their dated versions.


## September 27, 2026 unpublished recovery candidate

This candidate starts from the September 26 weather package. The investigation reproduced a code-caused first-frame blank for every positive recovery value, including 420 minutes. That suppression is removed. A positive native-hour fallback handles unavailable complication data, and complication setup operations are isolated. The recurring on-watch `1m` symptom remains unconfirmed; optional diagnostics capture both source values without guessing a replacement.

- Generic SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**.
- Generic native-test compilation: **BUILD SUCCESSFUL**, 30 test functions. Compilation does not execute Garmin tests.
- Separate temporary DEBUG=true source compilation: **BUILD SUCCESSFUL**; the delivered source retains DEBUG=false.
- `node tools/check_candidate.js`: **PASS**. Tests execute adapted production methods for immediate 420-minute display, native 7-hour fallback, valid 0/1 precedence, missing/error cases, clearing old fallback values, isolated setup failures, bounded rereads, clock rollback, and OFF/LOW_POWER guards.
- Diagnostic host paths with DEBUG on/off: **PASS**, including six-record/once-per-second limits, paired raw values, and preservation of a valid recovery reading when unit metadata access throws.
- Local FR965 profile/simulator is unavailable; both compilations carry the expected missing-device-profile warning. No physical-watch or Garmin-VM validation is claimed for this candidate.
- Source diff is limited to recovery handling/complication setup, its tests, and documentation. The September 26 weather changes and all icon resources are preserved.

On the watch, check immediate positive recovery after wake, the fallback during a missing primary reading, and normal sleep/wake behavior. For the recurring one-minute discrepancy, use [RECOVERY_DEBUG.md](RECOVERY_DEBUG.md) to capture raw values alongside the native screen and firmware version. No claimed firmware workaround should be inferred from host checks. See [RECOVERY_INVESTIGATION.md](RECOVERY_INVESTIGATION.md) for the API and community evidence.


## September 26, 2026 unpublished weather candidate

The candidate starts from the watch-validated September 25 revision `15f0fdf10e00b5548edf1724d9d54d8fb63fd5ba`. It adds UV risk colors, a native humidity/dew-point rotation, the distinct lavender thermometer-and-drop icon, and weather-condition colors with silver cloud overlays. The main icon atlas contains 27 glyphs within the same 256 × 128-pixel image. It has not been installed or validated on a physical watch and has not been pushed to GitHub.

Final-candidate development checks:

- Generic Connect IQ SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**, with the expected warning that the local `fr965` device profile is missing.
- `node tools/check_candidate.js`: **PASS** for the existing source-derived checks.
- Focused host checks using adapted production methods: **PASS** for all weather-condition and stale colors; silver overlays `g` on partly cloudy Sun/Moon and `k` on rain/snow/thunderstorm; matching overlay coordinates; unchanged temperature text; stable neighboring-field coordinates during humidity/dew-point switching; distinct moisture icons/colors; UV rounding, category bands, and paler numbers; and unchanged rain priority.
- Focused data/lifecycle checks: **PASS** for native dew-point cache/reset, zero and negative values in Celsius/Fahrenheit, missing data, two-second awake phases, wake reset, minute boundaries, clock rollback, and no extra weather reads.
- Icon resource checks: **PASS**. The original 24 main glyphs retain their pixels and metrics; only `d`, `g`, and `k` are appended. The main atlas remains 256 × 128 pixels; the small atlas and `fonts.xml` are unchanged.
- A preview composited from the actual icon atlas was visually reviewed. This checks the artwork and layer alignment; it is not a Garmin-rendered screenshot.

No local FR965 simulator/profile or Garmin VM is available. Host checks and generic compilation do not establish on-watch rendering, runtime performance, battery impact, or device behavior. No physical-watch validation is claimed for this candidate.

The final watch check should confirm visible UV category colors and a paler reading; blue humidity and lavender dew-point icons with their paler readings; two-second switching while awake without moving neighboring fields; correct Celsius/Fahrenheit and negative/zero dew-point display; humidity retained when dew point is unavailable; and unchanged sleep/wake behavior. Condition icons should have the documented accents and silver cloud layers without changing temperature text or condition selection. Old observations should halve every condition/moisture icon layer's own color and use the existing soft off-white values. UV retains its cached-value risk colors. The earlier watch acceptance below applies only to the September 25 build.

## September 25, 2026 release

The owner installed the history/readability build on a physical Forerunner 965 and reported that it works, including the stress history that was blank in the simulator. The runtime and resources published here are the same ones delivered for that check; no simulator diagnostic edits are included. This is a user acceptance observation, not a measured battery, memory, watchdog, or overnight recovery test. The previous published revision is `78f1a1ac774af6b008278f3e35150477a5e17a61` and remains the rollback reference.

- Generic SDK 9.2.0 release compilation: **BUILD SUCCESSFUL**.
- Generic native-test compilation: **BUILD SUCCESSFUL**, 29 test functions (25 existing plus four history-bucket tests). This is compilation, not execution of the tests in Garmin's VM.
- `node tools/check_candidate.js`: **PASS**. Host checks execute adapted production helpers, history collection/drawing, cache rules, and awake/update control flow. They cover invalid samples, measured stress zero, gaps, bucket/window boundaries, newest-first work limits, shared refresh/clock rollback, footer/read removal, existing color/goal behavior, and recovery sequences. They do not run in Garmin's VM.
- Approximate layout inspection with a regular Roboto Condensed surrogate passed. This checks geometry, not Garmin's actual native font metrics or rasterization. Optional high/low can be omitted by the weather row's fit rules.
- `Astro.mc`, `Lunar.mc`, `WakeState.mc`, `ChartColors.mc`, `DaySteps.mc`, recovery confirmation, the manifest, and OFF/LOW_POWER early returns are unchanged from the preceding color/recovery build. Font sizes, icon resources, layout, and history collection/drawing changed as documented.
- The local FR965 profile remains unavailable. Generic compilation has the documented missing-profile warning; it does not establish actual watch memory use, execution time, battery use, wake behavior, or rendering.

No generic `.prg` is supplied for installation. Build this source for **fr965** with the owner's existing signing key. See [release changes and watch checks](RELEASE_NOTES.md) for installation and rollback steps.

## Remaining targeted checks

The owner has accepted the current on-watch display and reported that stress history works. Longer-running checks still include recovery after waking the following morning, repeated sleep/wake cycles, unusually large field values, and actual battery/runtime measurements. Missing historical readings must remain gaps and measured stress zero must remain valid. Optional weather details can disappear to preserve primary readings. None of these broader checks should be inferred from compilation or the brief acceptance report.

## Simulator stress-history observation

The SDK 9.2.0 simulator showed a current stress number but no historical trace; the same build worked on the physical watch. The current number uses a native complication with recent-history fallback, while the chart uses timestamped `SensorHistory` observations. A [Garmin forum report of future-dated simulator history](https://forums.garmin.com/developer/connect-iq/f/connect-iq-web-store/441912/emulator-sets-sensor-history-samples-time-into-future) offers a possible cause. No raw timestamps were captured from the owner's failing simulator session, so that exact cause remains unconfirmed. The accepted build has no simulator workaround or invented samples.

## Historical record: simplified GitHub baseline

The following describes the earlier simplified build, **not the current release's layout or test count**. In particular, its restored footer was subsequently removed by this history/readability release.

### Baseline scope

Moonrise/set and the next full/new date/time line are removed, including all worker modules, event/phase timing routines, cached-progress lifecycle hooks, and their obsolete tests. The current lunar position and phase calculation is retained. No event calculations run behind a hidden UI.

The footer baseline is restored to y=401 on the 454-pixel display; the weather baseline remains y=371. This restores the earlier 30-pixel spacing. Footer text stays at native 20/22/24-pixel sizes with the existing 20/26-pixel icon resources. No text font or icon size was reduced. The phase-date line formerly at y=412 is gone. Recovery again uses its regular label without accommodation for moonset text.

Bright small-text colors remain #E2DDD4 and #DCD8D0; sunrise retains orange/yellow layers, sunset blue/yellow. The outer ring and moving marker geometry are unchanged.

### Baseline checks

- Generic Connect IQ SDK 9.2.0 release compilation: BUILD SUCCESSFUL.
- Generic Monkey C test compilation: BUILD SUCCESSFUL (14 tests compile). The exact FR965 device profile is not installed here; the manifest's fr965 target and application ID are preserved. The remaining manifest warning reflects that local limitation.
- Source search confirms there are no lunar event workers, phase-date functions, event UI fields, event cache/checkpoint callbacks, or added timers.
- Native fonts, brighter label colors, colorful sunrise/set glyph layers, and wake-only display policy are preserved.
- Independent current-position audit and source-derived arithmetic checks passed for the captured USNO lunar reference, UTC/location handling, rim orientation, horizon state, and current phase. Details are in `docs/LUNAR_CALCULATIONS.md` and `tools/check_rim_positions.js`.
- Approximate geometry inspection uses a regular Roboto Condensed surrogate. This verifies spacing, not Garmin native rasterization.

### Baseline limits

The FR965 simulator/profile is unavailable here. Generic compilation validates source and resources but does not prove on-watch memory use, watchdog timing, firmware lifecycle behavior, or exact font rendering. The JavaScript position check executes translated source arithmetic; it is not a Garmin VM.
