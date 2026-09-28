# Recovery diagnostics retired

The September 28 release reads only Garmin's raw whole hours. The earlier complication comparison, `DEBUG` switch, logger, and minute recovery state have been removed. No logging setup is required for this build. A native zero displays `0h` with the `READY` caption.

See [RAW_HOURS_UPDATE.md](RAW_HOURS_UPDATE.md) for current behavior. The September 27 ZIP retains its historical diagnostic source if those earlier API readings ever need investigation.
