# Recovery display investigation — September 27 historical record

**Superseded September 28:** recovery now uses native whole hours only. The two-source candidate and optional logging described below are historical; they are absent from the current runtime. See [RAW_HOURS_UPDATE.md](RAW_HOURS_UPDATE.md).

Investigation date: **September 27, 2026** (America/New_York). The findings below describe the unpublished two-source candidate based on the September 26 weather update. Its proposed behavior and outstanding checks are historical. The owner subsequently confirmed the September 28 raw-hours/polish build; see [VALIDATION.md](VALIDATION.md) for current status.

The user reported two symptoms on a Forerunner 965: a blank recovery field while Garmin's own screen showed seven hours, and an occasional one-minute reading around waking or putting the watch on. These must be investigated separately.

## What the source audit established

**SkyRing itself deliberately suppressed every positive recovery reading during the first second after wake.** `RecoveryReadState.accept()` returned `null` for a positive native value until `wakeTime + 1`, and the display rendered that as `--`. This included valid readings such as 420 minutes. The earlier mitigation therefore created a reproducible blank on each wake. Removing that suppression fixes this confirmed path. It does not establish that every longer blank reported on the watch had the same cause.

There is **no local default of one minute** in the inspected recovery code. A valid recovery value of `1` is displayed as `1m`; zero becomes `0h` with the `READY` label; missing or malformed data becomes `--`. The prior one-second suppression delayed an incoming value without establishing whether Garmin had refreshed it. A repeated value of one cannot safely be discarded because one minute is also a legitimate remaining duration.

No confirmed Garmin report was found for this exact FR965 morning or on-wrist one-minute symptom. The source of that transient remains unresolved without paired raw readings from the watch. This candidate must not be described as having proved or fixed a Garmin default-one-minute bug.

## The two native data sources

| Interface | Documented value | Candidate use |
| --- | --- | --- |
| `Complications.COMPLICATION_TYPE_RECOVERY_TIME` (21) | Integer minutes remaining; the complication object's value may be unavailable | Primary source, fetched again on each recovery read |
| `ActivityMonitor.getInfo().timeToRecovery` | Integer hours or `null`; FR965 is explicitly supported | Positive-hour fallback when the primary reading is unavailable, invalid, or throws |

The candidate uses each interface's documented units. It does not infer units from the size of a number, parse localized labels, or trust the complication's `unit` metadata to choose a multiplier. Positive fallback hours remain a separate value and use an hours-only formatter; they are never converted into invented minute precision.

**A direct-API reading of zero hours is not sufficient to claim `READY` when the minute-resolution source is unavailable.** Garmin does not document the direct field's rounding precisely enough to equate zero whole hours with zero remaining minutes. A valid primary value of zero still publishes immediately. If neither source supplies an acceptable reading, the field shows `--`.

The direct fallback is an alternate source, not a promise of identical semantics or freshness. Garmin describes it as recovery from the last activity. Community reports disagree about its relationship to total current recovery, and an older tracked report documents a one-hour difference from the native screen.

## Changes and limits

- Publish valid primary readings immediately, including on the first awake frame.
- Continue fetching a fresh complication object on each read, as the previous build already did.
- Isolate complication setup operations so a failure setting up another metric does not prevent recovery setup. This is a robustness improvement, not a demonstrated cause of the user's seven-hour discrepancy.
- Try the guarded positive-hour fallback when primary data is unavailable or invalid. A missing primary reading no longer forces `--` if the alternate API has useful positive data.
- Preserve the existing bounded rechecks at approximately one and three seconds after wake, performed on normal awake frames. Missed deadlines do not accumulate catch-up reads.
- Keep normal refreshes and complication notifications. No extra timer, forced screen wake, always-on rendering, continuous retry loop, or synthetic overnight recovery countdown is added.

Recovery can be revised by Garmin after sleep, stress, relaxation, and activity. Subtracting elapsed time from an old reading cannot reproduce those revisions. Missing data is therefore not silently converted to `READY`, nor carried forward indefinitely as a current value.

## Optional diagnostics

Recovery logging is disabled by default. When enabled for investigation, it records raw source values and their types, complication unit metadata and UTC epoch time with wake context at existing recovery reads. It adds no independent polling schedule. At most six records are printed per wake and at most one per wall-clock second. See [RECOVERY_DEBUG.md](RECOVERY_DEBUG.md) for setup.

The useful evidence is a log around the discrepancy paired with the recovery value visible in Garmin's native screen and the watch firmware version. This can distinguish an unavailable complication, conflicting native sources, a genuine primary value of one, and a display error. Successful simulator compilation alone cannot establish which occurred on the physical watch.

## Sources and what they establish

### Current official documentation

1. [Garmin Complications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications.html): ID 21 reports minutes, the module supports FR965, `getComplication()` can throw when unavailable, and callbacks can indicate a changed **or unavailable** complication. These notifications do not guarantee valid data. The API supplies no sample timestamp for recovery.
2. [Garmin Complication object](https://developer.garmin.com/connect-iq/api-docs/Toybox/Complications/Complication.html): `value` and `unit` can be `null`. Validate data independently of successful object retrieval.
3. [Garmin ActivityMonitor.Info.timeToRecovery](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html#timeToRecovery-var): hours or `null`, available since API 3.3.0, with FR965 listed as supported. Check availability before access.
4. [Forerunner 965 manual, Recovery Time](https://www8.garmin.com/manuals-apac/webhelp/forerunner965/EN-SG/GUID-4535C8CD-357C-4673-8EBB-F1BCBE878158-2712.html): the watch revises recovery throughout the day using additional observations. The page also contains other training sections; see its Recovery Time section.

### Firsthand Garmin developer discussions

5. [Is the recovery complication really in seconds?](https://forums.garmin.com/developer/connect-iq/f/discussion/332899/is-the-complication_type_recovery_time-really-in-seconds/1616179) (2023): a developer observed a simulator value of `5` for a five-hour input, while another reported a real-device value of 338 minutes corresponding to five hours on the native display. This documents historical simulator/documentation disagreement. Current official documentation says minutes; the older seconds description has been corrected.
6. [[BUGGY] Complications](https://forums.garmin.com/developer/connect-iq/f/discussion/351590/buggy-complications) (2023): developers reported recovery **unit metadata** of `"1"`, `null`, and `"h"` across devices and simulator. This is not evidence that the numeric recovery value defaults to one minute.
7. [The Complications API is kind of a mess](https://forums.garmin.com/developer/connect-iq/f/discussion/328568/the-complications-api-is-kind-of-a-mess-right-now-help/1611456) (2023): an independent report of recovery unit/documentation inconsistency. It supports avoiding metadata-based unit guessing, not a universal wake-time workaround.
8. [Complication vs direct data access](https://forums.garmin.com/developer/connect-iq/f/discussion/373906/complication-vs-direct-data-access/1849892) (thread started 2024): developers discuss fresh object retrieval, direct-API fallback, and avoiding truncation of positive remaining minutes into a misleading zero-hour display. The earlier thread page contains an ActivityMonitor-first example, but that example does not prove it is always fresher.
9. [Bad values in timeToRecovery, CIQQA-1084](https://forums.garmin.com/developer/connect-iq/i/bug-reports/bad-values-in-timetorecovery) (2022): a Fenix 6 Pro report records direct-API/native-display differences of one hour; Garmin staff asked about rounding. The visible thread does not establish a fix. It does not reproduce the FR965 blank or one-minute symptom.
10. [Complications called every second in simulator](https://forums.garmin.com/developer/connect-iq/f/discussion/412802/complications-called-every-second-in-simulator-even-when-value-has-not-changed/1938051) (2025): one developer describes ActivityMonitor recovery as last-activity and the complication as total recovery. The thread provides no paired measurements or Garmin confirmation of that distinction. It is a reason to keep the remaining-minutes interface primary, not a proven specification for the fallback.
11. [Venu 2 Plus `has :timeToRecovery` crash report](https://forums.garmin.com/developer/connect-iq/f/discussion/398300/has-timetorecovery-is-true-for-the-venu2-plus-and-crashes-because-well-it-s-not-there) (2024): the reporter ultimately attributed the apparent availability-check failure to running an older build and could no longer reproduce it. The headline must not be treated as a confirmed `has` operator defect.

The investigation found useful documented API pitfalls and a reproducible SkyRing display error. It did not find a verified FR965 firmware workaround for the remaining one-minute symptom. GitHub searches did not produce a stronger applicable Connect IQ reproduction than these developer discussions.
