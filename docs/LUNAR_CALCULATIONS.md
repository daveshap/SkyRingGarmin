# Sun and Moon rim positions

Only current sky position and current Moon phase are calculated. This revision contains no moonrise/set search, full/new event forecast, resumable worker, event cache, or phase-date line.

## Coordinates and dial mapping

`Astro.compute()` calculates the Sun's apparent solar time, declination, altitude, and hour angle using Astronomical Almanac approximations. `Lunar.position()` uses the Meeus chapter 47 periodic coordinates, then local sidereal time minus right ascension to obtain lunar hour angle. Longitude is east-positive; timestamps are UTC. The civil time-zone offset is used for displayed sun times only.

The Sun retains the hour-angle mapping: x = centre + radius × sin(hour angle), y = centre − radius × cos(hour angle). Zero is at the top; negative angles occupy the left side before upper transit, positive angles the right side after it. The ring's color bands and sunrise/sunset ticks use this solar scale.

The Moon uses its current apparent altitude `a` and north-clockwise azimuth `A`:

- `west = -cos(a) × sin(A)`
- `up = sin(a)`
- `moonRing = atan2(west, up)`

The drawing maps `moonRing` with the same sine/cosine rim functions. This projects the Moon's local sky direction onto an east/up/west plane and extends it to the rim: east left, west right, above-horizon center up, below-horizon center down. It omits the north/south component. The dial angle therefore is not a numerical altitude or compass bearing; a Moon directly north or south can appear at the top without being overhead.

At the exact north/south horizon the projection has no direction. When `west² + up² < 10⁻²⁰`, the helper uses −90° for negative hour angle and +90° otherwise. This avoids an undefined projection. Nearby paths can still change angle rapidly, especially near grazing or circumpolar geometry; the rim is a two-dimensional summary, not a full sky map. Ordinary full-day reference cases are covered by the host checks.

`Lunar.position()` computes parallax-adjusted altitude and conventional refraction. The projection uses this apparent **center** altitude. Marker brightness uses a standard **upper-limb** horizon criterion that includes lunar distance, semidiameter, and refraction. The first visible limb can therefore brighten the Moon slightly before its center moves above the horizontal diameter. A body below the horizon remains visible but dim. Terrain, nearby obstructions, observer elevation, and actual weather refraction are not modeled.

The phase disc uses illuminated fraction and waxing/waning from the current lunar and solar coordinates. Hemisphere orientation is conventional, not an exact view of the Moon's apparent tilt.

## Cost and refresh

The view computes one current lunar coordinate solution on wake and on its normal once-per-minute data refresh. It no longer samples future times or searches for events. OFF and LOW_POWER return before astronomical work. The removed event fields have no loading or resume state.

Double-precision day counts preserve sidereal precision. The current TT−UTC offset used by the lunar ephemeris is 69.184 seconds and would need adjustment if a future leap second changes it. UTC approximates UT1 within its usual sub-second difference.

## September 30 placement regression

At 36.075° N, 79.10° W (Hillsborough, NC), September 30, 2026, 10:00 EDT / 14:00 UTC, the source returned approximately **+16.57° apparent lunar altitude**, consistent with the captured USNO calculation after applying lunar parallax and atmospheric refraction. Its hour angle was approximately **+85.8°**. Drawing that hour angle put the marker nearly at the side/horizon, despite the positive altitude. The new projection gives approximately **+72.6°** on the rim, visibly above the right-hand horizon. Neither the coordinates nor the phase calculation needed replacement.

This comparison uses a stated location and instant; it is not a direct capture of the coordinates used on the owner's watch. Garmin weather's observation location takes priority over activity location and the saved position. Those coordinates can be old or displaced from the wearer, and that independent limitation remains. The once-per-minute calculation changes lunar altitude by only about 0.18° per minute around this reference, too little to account for the reported placement error.

## Earlier captured independent reference

Public Hillsborough, NC city-center reference, 36.075° N, 79.10° W, September 24, 2026, 20:00 EDT / September 25, 00:00 UTC:

| Quantity | Captured reference | Calculation |
|---|---:|---:|
| Lunar hour angle | −57.380713° | −57.378330° |
| Lunar azimuth | 115.903174° | 115.905441° |
| Apparent lunar centre altitude | approximately +20.67° | +20.671680° |
| Illuminated fraction | approximately 96.71% | approximately 96.71% |

USNO's raw celestial-navigation altitude is geocentric; parallax and refraction must be applied before comparing it with apparent altitude. This reference is tied to the stated location and instant, not an untimestamped screenshot.

The optional source-derived check in `tools/check_rim_positions.js` verifies position and projection arithmetic, the September 30 regression, east/west horizon placement, transit/degenerate cases, and full-day motion. It does not emulate Garmin's runtime or prove device performance.

References: Meeus, *Astronomical Algorithms*, second edition, chapter 47; https://aa.usno.navy.mil/faq/alt_az ; https://aa.usno.navy.mil/faq/RST_defs ; https://aa.usno.navy.mil/data/celnav ; https://pymeeus.readthedocs.io/en/latest/bodies/Moon.html
