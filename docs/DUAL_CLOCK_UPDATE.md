# Side-by-side clocks — restored October 2 candidate

**October 6 follow-up:** the owner liked this layout. The same candidate branch now includes the [humidity/dew-point rotation refactor](WEATHER_ROTATION_UPDATE.md), which needs watch validation. The no-new-timer statement below describes the header-only restoration; the later rotation change adds a guarded awake timer without changing the header.

Restored October 6, 2026 from published working commit `0c16b2b` and the exact runtime patch recorded in the development conversation. The old temporary ZIP was unavailable; this archive and documentation are newly assembled, not byte-identical recovery of that ZIP. The candidate is now saved on GitHub's `candidate/dual-clock` branch. It still needs watch validation.

## Reading the header

- **LOCAL**, left: device clock in warm white. Follows your 12/24-hour preference; am/pm sits in the caption when needed.
- **SOLAR**, right: apparent solar time in amber, with a lemon-yellow Sun icon. Solar noon is 12:00; this reading always uses 24-hour notation.
- Both clocks use native 64-pixel text on the same baseline. If either measured value exceeds its allowance, both use 48 pixels.
- Peak solar altitude and date stay above. Current solar altitude and the next sunrise/sunset countdown stay below.

The civil time is Garmin's device clock, not a direct NIST query. Solar time retains the existing longitude/equation-of-time calculation. Missing location retains the marked estimate and `location needed`. No new sensor, timer, astronomy calculation, or always-on drawing was added.

## Install

1. Keep your working program as a rollback copy.
2. Extract the ZIP into a fresh folder and open the folder containing `manifest.xml` and `monkey.jungle` in VS Code.
3. Use **Monkey C: Build for Device**, target **Forerunner 965 / fr965**, and your existing signing key.
4. Copy the resulting `SkyRing.prg` to `GARMIN/APPS`, using the same sideload filename as your current installation.
5. Check both clocks, am/pm, date/angle spacing, and normal sleep/wake behavior.

This is a source package, not an installable `.prg`. The October 2 candidate passed generic SDK compilation and source-derived layout checks; those historical checks are separate from the restored-source checks in [VALIDATION.md](VALIDATION.md). Device-specific compilation and watch testing remain necessary.
