# Build, test, and install on Windows

SkyRing targets **Forerunner 965 (`fr965`)** only. Open the repository root containing `manifest.xml` and `monkey.jungle`; do not create a new Monkey C project around these files. The manifest requires Connect IQ API 4.2.0. That is the watch's minimum API level, not a requirement to install an old 4.2 SDK.

The current source has been checked with Connect IQ SDK **9.2.0**. Generic compilation and host-side calculation checks were available during development; the FR965 profile and its simulator were not available in that environment. The owner subsequently built and installed this revision on a physical FR965 and confirmed it works, including stress history. A successful generic compile alone does not establish device compatibility, runtime memory use, or watchdog timing. Use the device-specific steps below for your own build.

## 1. Install the tools

1. Install [Visual Studio Code](https://code.visualstudio.com/), then the [Monkey C extension published by Garmin](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c). Monkey C's compiler and simulator come with Garmin's SDK; there is no separate Monkey C language runtime to install on Windows.
2. Download the Windows [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/). Sign in, download the SDK, and set it as the current SDK. In the **Devices** tab, also download **Forerunner 965**. SDK installation alone does not guarantee that its device profile is installed.
3. Install 64-bit Java. Garmin's **SDK 9.2.0 bundled Getting Started documentation specifies Java 11 or higher**. A Java 17 JDK includes the runtime and is a practical choice; the source compilation checks used OpenJDK 17. Follow the requirement supplied with your SDK if you later change SDK versions. Java 8 advice in older tutorials predates this requirement.
4. Open a new terminal and run `java -version`. If VS Code cannot find the right installation, set **Monkey C: Java Path** (`monkeyC.javaPath`) in VS Code's **User Settings** to the Java installation root, not `bin/java.exe`.
5. In VS Code, press **Ctrl+Shift+P** and run **Monkey C: Verify Installation**.

No Python, Node.js, external API account, or font generator is required for a normal build. The icon resources are already included.

## 2. Set up your developer key

Reuse your existing developer key when updating your own installation. Set **Monkey C: Developer Key Path** in VS Code's **User Settings** to that file. If you do not have one, run **Monkey C: Generate a Developer Key** from the command palette and save it outside this repository, for example in a private `Documents\GarminKeys` folder.

Keep a private backup. Garmin uses this RSA signing key to identify builds; the same key is required to update an app published in the Connect IQ Store. Do not commit the key, include it in ZIPs, or upload it with a bug report. Machine-specific key paths belong in your user settings.

## 3. Open the project and run the simulator

1. Clone the repository, or extract its ZIP into a new folder. When upgrading from the older lunar-event ZIPs, use a clean folder: copying over an old project can leave removed `.mc` worker files behind.
2. Select **File → Open Folder** and choose the folder containing `manifest.xml`. If VS Code shows Restricted Mode, review the project and trust this folder to enable the development extension.
3. Open `source/SkyRingView.mc` in the editor.
4. Use **Run → Run Without Debugging** (**Ctrl+F5**) and select **Forerunner 965**. Use **F5** when you want debugging.
5. Exercise both awake and sleeping states. The face intentionally goes black in low power and must redraw when awake. Check several wake/sleep cycles, including navigating away from the face and back.

Simulator values can be missing or synthetic. Supply location and weather simulation data when checking the ring or weather fields; a face with no usable location deliberately suppresses location-dependent sky markers. Do not treat an empty simulated recovery, weather, or stress-history reading as proof that the field fails on the watch. The owner saw a blank stress chart while current stress was present in the SDK 9.2.0 simulator, then confirmed history worked on the physical watch. The current build deliberately contains no simulator-specific history workaround. See [validation and remaining checks](VALIDATION.md).

## 4. Build the file for the watch

Run **Monkey C: Build for Device** from the command palette. Choose **Forerunner 965 (`fr965`)**, use your developer key, and choose Release if prompted. Save the result as `SkyRing.prg` in a local output folder.

Use this device build for installation. Do not sideload a generic compile, a unit-test build, or an `.iq` store-export package. Check the build output for **BUILD SUCCESSFUL** and confirm that the target is `fr965`.

The equivalent PowerShell commands below are optional. Run them from the project root, replace both example paths with your real paths, and keep the quotes when paths contain spaces:

```powershell
$ciqBin = 'C:\path\to\connectiq-sdk\bin'
$skyRingKey = 'C:\Users\YOUR_NAME\Documents\GarminKeys\developer_key.der'
New-Item -ItemType Directory -Force .\bin | Out-Null
& "$ciqBin\monkeyc.bat" -f .\monkey.jungle -d fr965 -o .\bin\SkyRing.prg -y $skyRingKey -r -O 2p -w
```

Here `-d fr965` selects the device, `-r` builds release code, and `-w` enables warnings. Build output and signing keys are not repository content.

## 5. Copy it to the watch

1. Connect the watch to Windows with a data-capable USB cable.
2. In File Explorer, open the watch's storage and locate **`GARMIN\APPS`**. Depending on how Windows exposes the watch, it may appear under a device's internal storage rather than as a drive letter.
3. Copy the device-built **`SkyRing.prg`** into `GARMIN\APPS`. Use the same filename as your previous SkyRing sideload and replace that file. Keep the existing application ID in `manifest.xml` when updating this project.
4. Wait for the transfer to finish, safely disconnect where Windows offers that option, and unplug the watch.
5. On the watch, hold **UP/MENU → Watch Face**, select SkyRing, and apply it. If another face is active, the new file will not automatically make SkyRing the selected face.

Do not delete unrelated apps or watch data. To remove this sideload later, select another face first and remove its specific program through the watch's available app controls or by deleting that program file over USB.

Brightness, gesture behavior, and display timeout remain Garmin watch settings. SkyRing does not override them or provide an always-on display.

## 6. Optional development checks

### Source-derived sky-position check

With Node.js installed, run this from the repository root:

```powershell
node .\tools\check_rim_positions.js
```

This checks the current position calculations and rim mapping against reference cases. It is a host-side check, not execution inside Garmin's Monkey C VM, and does not measure watch CPU or battery use.

### Source-derived history and refresh checks

```powershell
node .\tools\check_candidate.js
```

Despite its original filename, this checks the current source: history buckets and sample filtering, chart drawing, shared cache timing, colors, daily goals, recovery confirmation, footer removal, and awake-only guards. These are host checks, not Garmin VM execution or battery measurements.

### Native Monkey C unit tests

`monkey-tests.jungle` adds `tests` to the source path. `monkey.jungle` is the normal app build. The 29 test functions cover rolling daily steps and goals, history buckets, chart colors, wake-state decisions, recovery formatting/confirmation, and lunar position/horizon cases. Development checks compiled these tests; they were not executed in the unavailable local FR965 simulator.

For the VS Code route, set **Monkey C: Jungle Files** to `monkey-tests.jungle` locally, then run **Monkey C: Run Tests** or use the extension's Test Explorer with the FR965 selected. Restore `monkey.jungle` before building the installable release.

For the PowerShell route, reuse the variables from the build example:

```powershell
& "$ciqBin\monkeyc.bat" -f .\monkey-tests.jungle -d fr965 -o .\bin\SkyRing-tests.prg -y $skyRingKey -t -w
& "$ciqBin\connectiq.bat"
```

Wait for the simulator to open, then run:

```powershell
& "$ciqBin\monkeydo.bat" .\bin\SkyRing-tests.prg fr965 /t
```

**Windows argument detail:** Garmin's SDK 9.2.0 `monkeydo.bat` accepts **`/t`**, while the compiler accepts **`-t`**. The Linux/macOS `monkeydo` wrapper uses `-t`. The simulator must already be running. Read the test results, rather than counting test compilation alone as a pass.

### Icon artwork

Only if changing the icon atlas, install Python with Pillow and Inkscape and run `py tools/gen_icons.py`. This regenerates icons, not text fonts. Normal face text uses the watch's native fonts.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `fr965` is missing or reported as an invalid device ID | Download the Forerunner 965 device definition in SDK Manager, confirm the active SDK, and rerun Verify Installation. A compile performed without that profile is not a validated watch build. |
| Java is missing or the wrong version starts | Check `java -version`, the system PATH, and `monkeyC.javaPath`. Restart VS Code after changing Java installation settings. |
| Monkey C commands do not appear | Confirm Garmin's extension is installed and enabled, the project folder is trusted, and a `.mc` source file is open. |
| Launcher icon size warning | An older RowWatch build warned that a 40×40 icon would be scaled to 65×65. That warning was nonfatal; it did not prevent installation. The current SkyRing launcher icon is already 65×65. If the old warning returns, check that you opened the current project. |
| Old lunar placeholders, obsolete workers, or strange text survive an upgrade | Extract/clone into a clean folder, run **Monkey C: Clean Project**, and rebuild. The current source has no moonrise/set or full/new-moon event workers and no custom bitmap text font. |
| Current stress shows but simulated history is blank | Current stress and history use separate sources. See the recorded [simulator finding](VALIDATION.md#simulator-stress-history-observation); this release worked on the owner's watch. After changing simulated history, restart the face or allow its five-minute history cache to expire. Do not fill missing history with invented samples. |
| `IQ!`, a watchdog error, or failure to wake | Switch to a working face, record the error and stack trace, and include the source revision, SDK version, target, and whether it occurred in the simulator or on hardware. Do not assume successful compilation rules out runtime bugs. |
| Watch does not appear in Explorer | Try a known data-capable cable and another USB port; confirm the watch has entered its USB connection mode. |

The face persists its last usable location; step history is read from Garmin and held in memory. Bug reports ordinarily need the error text and reproduction steps, not exported watch data. Keep developer keys and private diagnostic data out of public issues.

## Official references

- [Connect IQ SDK and SDK Manager](https://developer.garmin.com/connect-iq/sdk/)
- [Garmin: Getting Started](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/)
- [Garmin's Monkey C extension](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)
- [Garmin: VS Code extension commands](https://developer.garmin.com/connect-iq/reference-guides/visual-studio-code-extension/)
- [Garmin: command-line tools and signing keys](https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/)
- [Garmin: unit testing](https://developer.garmin.com/connect-iq/core-topics/unit-testing/)

If an online documentation page shows only navigation, use **Monkey C: View Documentation** for the complete documentation shipped with your SDK. The Java requirement and Windows `/t` detail above were also checked directly in SDK 9.2.0's bundled documentation and Windows launcher scripts.
