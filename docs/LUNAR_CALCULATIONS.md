# Sun and Moon rim positions

Only current sky position and current Moon phase are calculated. This revision contains no moonrise/set search, full/new event forecast, resumable worker, event cache, or phase-date line.

## Coordinates and dial mapping

`Astro.compute()` calculates the Sun's apparent solar time, declination, altitude, and hour angle using Astronomical Almanac approximations. `Lunar.position()` uses the Meeus chapter 47 periodic coordinates, then local sidereal time minus right ascension to obtain lunar hour angle. Longitude is east-positive; timestamps are UTC. The civil time-zone offset is used for displayed sun times only.

Both hour angles use the same rim mapping: x = centre + radius × sin(hour angle), y = centre − radius × cos(hour angle). Zero is at the top; negative angles occupy the left side before upper transit, positive angles the right side after it. The ring's color bands describe the Sun, not the lunar horizon.

`Lunar.position()` also computes parallax-adjusted altitude and conventional refraction. Marker brightness uses a standard upper-limb horizon criterion that includes lunar distance, semidiameter, and refraction. A body below the horizon remains visible but dim. Terrain, nearby obstructions, observer elevation, and actual weather refraction are not modeled.

The phase disc uses illuminated fraction and waxing/waning from the current lunar and solar coordinates. Hemisphere orientation is conventional, not an exact view of the Moon's apparent tilt.

## Cost and refresh

The view computes one current lunar coordinate solution on wake and on its normal once-per-minute data refresh. It no longer samples future times or searches for events. OFF and LOW_POWER return before astronomical work. The removed event fields have no loading or resume state.

Double-precision day counts preserve sidereal precision. The current TT−UTC offset used by the lunar ephemeris is 69.184 seconds and would need adjustment if a future leap second changes it. UTC approximates UT1 within its usual sub-second difference.

## Captured independent reference

Public Hillsborough, NC city-center reference, 36.075° N, 79.10° W, September 24, 2026, 20:00 EDT / September 25, 00:00 UTC:

| Quantity | Captured reference | Calculation |
|---|---:|---:|
| Lunar hour angle | −57.380713° | −57.378330° |
| Lunar azimuth | 115.903174° | 115.905441° |
| Apparent lunar centre altitude | approximately +20.67° | +20.671680° |
| Illuminated fraction | approximately 96.71% | approximately 96.71% |

USNO's raw celestial-navigation altitude is geocentric; parallax and refraction must be applied before comparing it with apparent altitude. This reference is tied to the stated location and instant, not an untimestamped screenshot.

The optional source-derived check in `tools/check_rim_positions.js` verifies position and mapping arithmetic. It does not emulate Garmin's runtime or prove device performance.

References: Meeus, *Astronomical Algorithms*, second edition, chapter 47; https://aa.usno.navy.mil/faq/alt_az ; https://aa.usno.navy.mil/faq/RST_defs ; https://aa.usno.navy.mil/data/celnav ; https://pymeeus.readthedocs.io/en/latest/bodies/Moon.html
