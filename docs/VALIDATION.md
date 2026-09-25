# Validation — simplified sky display

## Scope

Moonrise/set and the next full/new date/time line are removed, including all worker modules, event/phase timing routines, cached-progress lifecycle hooks, and their obsolete tests. The current lunar position and phase calculation is retained. No event calculations run behind a hidden UI.

The footer baseline is restored to y=401 on the 454-pixel display; the weather baseline remains y=371. This restores the earlier 30-pixel spacing. Footer text stays at native 20/22/24-pixel sizes with the existing 20/26-pixel icon resources. No text font or icon size was reduced. The phase-date line formerly at y=412 is gone. Recovery again uses its regular label without accommodation for moonset text.

Bright small-text colors remain #E2DDD4 and #DCD8D0; sunrise retains orange/yellow layers, sunset blue/yellow. The outer ring and moving marker geometry are unchanged.

## Checks

- Generic Connect IQ SDK 9.2.0 release compilation: BUILD SUCCESSFUL.
- Generic Monkey C test compilation: BUILD SUCCESSFUL (14 tests compile). The exact FR965 device profile is not installed here; the manifest's fr965 target and application ID are preserved. The remaining manifest warning reflects that local limitation.
- Source search confirms there are no lunar event workers, phase-date functions, event UI fields, event cache/checkpoint callbacks, or added timers.
- Native fonts, brighter label colors, colorful sunrise/set glyph layers, and wake-only display policy are preserved.
- Independent current-position audit and source-derived arithmetic checks passed for the captured USNO lunar reference, UTC/location handling, rim orientation, horizon state, and current phase. Details are in `docs/LUNAR_CALCULATIONS.md` and `tools/check_rim_positions.js`.
- Approximate geometry inspection uses a regular Roboto Condensed surrogate. This verifies spacing, not Garmin native rasterization.

## Limits

The FR965 simulator/profile is unavailable here. Generic compilation validates source and resources but does not prove on-watch memory use, watchdog timing, firmware lifecycle behavior, or exact font rendering. The JavaScript position check executes translated source arithmetic; it is not a Garmin VM.

## Brief device check

Wake the fresh build, allow it to sleep, and wake it again. The full face should return on wake and remain black during sleep. Confirm that there are no moonrise/set placeholders or full/new line, and that the WX/battery/elevation footer has more separation from weather. The Moon disc should still show the current phase. When comparing a marker with a reference, use the same UTC instant and coordinates; rim angle represents meridian-relative motion, while brightness indicates horizon state.
