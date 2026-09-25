# Validation — history and readability release

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

