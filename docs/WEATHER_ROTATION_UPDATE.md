# Humidity/dew-point rotation — October 6, 2026

This candidate follows the restored dual-clock layout. The owner liked that layout but reported that the moisture slot still stopped alternating. The update is saved on `candidate/dual-clock`; `main` remains the working release until the candidate is validated. Installation is still a normal `fr965` build with the owner's existing signing key.

## What the investigation establishes

The September implementation tracked dwell inside the weather drawing method and relied on Garmin supplying an awake frame. Lifecycle callbacks could restart humidity. If repeated callbacks interrupted a dwell, the alternate reading could be postponed repeatedly; if no awake frame arrived, the drawing method could not advance or request one.

These are source-level weaknesses we can reproduce. We do not have a timestamped trace from the owner's failing watch, so we cannot claim they identify one exclusive on-watch cause. Garmin can also end the watch face's high-power window while the user expects motion to continue; a display timeout setting is not a guarantee that high-frequency watch-face updates remain available.

Earlier tests called the drawing/update methods with simulated awake frames, which established behavior when frames arrived. They did not establish independent scheduling when frames were absent. The new tests exercise the state machine and actual timer/lifecycle wiring separately from pure drawing.

## The refactor

`MoistureRotation` owns which cached reading is selected and when its two-second dwell began. It uses `System.getTimer()` monotonic milliseconds rather than civil clock seconds, so a time-zone or clock correction does not change the alternation cadence. A backward/wrapped timer value rebases the dwell. Delayed callbacks switch once, without replaying missed cycles.

The selection survives sleep and repeated lifecycle callbacks. Pausing stops its active dwell; resuming starts a full dwell from the preserved selection. If only humidity or only dew point is available, that reading stays visible and no rotation timer runs. If neither is available, the existing humidity placeholder remains. Native zero and negative dew point remain valid readings.

`drawEnv()` is now a renderer of cached state. It does not change the selected reading or timing. The wider form still determines the shared slot width, so temperature and UV/rain do not jump when the reading changes. Icons, colors, pale numbers, units, and cached Garmin weather sources are retained.

`SkyRingView` owns one repeating 2,000-ms timer. Ordinary awake frames advance the state; the timer only checks whether a change is due and requests a redraw if needed. The requested `onUpdate()` then performs the selection change, so timer/native callback ordering cannot double-toggle the state. Timer callbacks perform no sensor, weather, or astronomy reads. The existing minute/wake cache policy still controls weather reads; this is not a weather polling timer. A requested normal paint can still perform its usual live-HR read, so extra paints are not claimed to have zero sensor/API cost.

## Wake/sleep boundaries

Timer permission comes only from `onExitSleep()`, not from a HIGH_POWER observation alone. It also requires visibility, an eligible physical display mode where available, and both moisture values. `onHide()`, `onEnterSleep()`, OFF, and LOW_POWER stop it. The callback checks eligibility again before acting, covering a tick queued immediately before shutdown.

This timer gate is deliberately more conservative than the rendering gate. `onUpdate()` continues to trust the physical display mode when available, preserving the earlier fix for stale callback flags that could leave an awake watch black. It does not withhold the whole display merely because timer permission is absent.

Garmin documents high-power updates for about ten seconds after a gesture and prohibits timers in low-power watch-face mode. The candidate obeys those boundaries. It cannot promise continuous two-second animation after Garmin ends the allowed window, extend the hardware timeout, or keep the screen awake. Sleeping remains black; no always-on renderer is introduced.

## Costs and limits

The timer does small, bounded state work and requests a normal render only when due. The timer can request at most one redraw per two-second tick while eligible. When a native frame runs first, its completed selection change usually makes that timer request unnecessary; when the timer runs first, the request can coincide with a native frame and produce a redundant paint. The state still cannot double-toggle before its dwell expires. No claim of zero battery cost is made; watch battery impact and callback timing have not been measured.

Weather remains Garmin's cached observation. The new scheduler cannot make missing dew point appear, force a new weather observation, or correct an outdated weather station. Missing either moisture value intentionally stops alternation.

## Test on the FR965

1. Extract the candidate into a fresh folder, build for `fr965` with the existing key, and sideload using the existing filename.
2. With both readings available, wake the face and watch several switches between the blue humidity droplet/percentage and violet dew-point icon/temperature. Each should have at least a two-second dwell under normal callbacks.
3. Let it sleep, then wake it repeatedly. The selected reading should be preserved, then resume alternating during the permitted window. The display must remain black when sleeping and reliably return when awake.
4. If it still stalls during that window, record the elapsed seconds since wake, the currently displayed moisture reading, whether a gesture changes anything, the firmware version, and whether Garmin has both weather values. A short video is useful; a single screenshot cannot distinguish missing data from missing callbacks.

Compilation and host checks are listed in [VALIDATION.md](VALIDATION.md). They cannot establish Garmin VM behavior or replace this physical-watch check. The dual clocks, recovery, health histories, sky ring, and weather colors are outside the scope of this refactor.

## Garmin references

- [WatchFace lifecycle](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/WatchFace.html): high/low-power callbacks and update cadence.
- [Timer.Timer](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html): timer lifecycle and watch-face low-power restriction.
- [System.getTimer](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function): elapsed milliseconds since startup.
