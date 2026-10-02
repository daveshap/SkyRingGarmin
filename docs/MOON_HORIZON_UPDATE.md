# Moon horizon correction — delivered September 30, published October 2, 2026

## What was wrong

The Moon calculation already knew its apparent altitude, but the renderer placed the icon using lunar hour angle. At 10 a.m. EDT on September 30 in Hillsborough, the computed Moon was about 16.57° above the horizon while its hour angle was about 85.8°. That placed the icon nearly at 3 o'clock and contradicted the view outside. The captured USNO comparison agreed with the altitude; the display mapping caused the discrepancy.

## What changes

`Astro.moonRingAngle()` projects the current apparent altitude and azimuth onto the east/up/west plane. The new rim angle is about 72.6° for that reference, putting the Moon clearly above the right-hand horizon. `SkyRingView.drawRing()` uses this angle instead of raw lunar hour angle.

- Upper half: the Moon's apparent center is above the horizon.
- Lower half: the Moon's apparent center is below the horizon.
- Left/right: eastern/western part of the sky.
- The phase-shaped disc still follows the current illuminated fraction and waxing/waning state.

The Sun keeps its existing hour-angle path and solar color bands. The change uses values already calculated once per minute while awake and on wake. It adds no event search, timer, background work, or external service. Dashboard layout, native fonts, colorful sunrise/sunset icons, weather/recovery behavior, and wake-only operation are preserved.

## How to interpret it

The Moon projection omits north/south depth and expands the projected direction to the rim. It reliably distinguishes above from below in ordinary sky positions, but its dial angle is not a numerical altitude scale. A marker at the top need not mean directly overhead. At the exact north/south horizon the projection degenerates; the helper selects a defined side using hour angle, and nearby paths can move rapidly around the dial. See [the formula](LUNAR_CALCULATIONS.md).

Placement refers to the apparent center; brightness retains the existing upper-limb horizon test. The first limb may be visible slightly before the center crosses the horizon. Terrain, buildings, observer elevation, and actual atmospheric refraction are not modeled. Weather observation or saved coordinates may be older or less local than the wearer expects.

## Verification and installation

The September 30 candidate passed generic SDK compilation and source-derived checks, including full-day motion; 30 native test functions compiled. The October 2 restored publication passed both generic builds and all three host check tools again, including full-day motion at five locations across two seasonal dates. Native Garmin VM execution, FR965 runtime margin, and battery impact were not measured. The October 2 publication restores the recorded patch onto the published September 28 baseline after workspace maintenance removed the unpublished candidate; [VALIDATION.md](VALIDATION.md) distinguishes historical and current checks.

Build for `fr965` with the existing developer key and replace the installed application using the same filename. Extract into a clean folder when using a ZIP. Follow [BUILD_WINDOWS.md](BUILD_WINDOWS.md). The September 28 rollback revision is `e784b10c50597fd234c242d24eb8779307d5b6ca`.
