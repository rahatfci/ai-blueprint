---
name: device
description: List, boot, and drive simulators, emulators, and physical devices, install builds, and capture screenshot and log evidence. Use for /device, run on simulator, boot emulator, install the app, take a screenshot, or capture logs.
disable-model-invocation: true
---

# device - run the app somewhere you can see it

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`.

Where this sits in the workflow:

    /implement  ->  [device]  ->  /check
    (built a       (get it on     (prove the
     step)          a screen)      done-whens)

The web workflow starts a dev server and opens a URL. Mobile has no equivalent,
so this skill is that missing capability: it finds a target, gets the app onto
it, and captures what happened. `/check` and `/implement` call it rather than
each reinventing device handling.

It runs builds and installs onto local targets. It never signs a release,
uploads to a store, or touches a remote service.

## Input

Optional scope:

- no argument: pick the best available target, install the current build, report
- `list`: read-only inventory of available targets, nothing installed
- `ios` / `android`: restrict to one platform
- `<device name or id>`: use that specific target
- `screenshot`: capture from whatever is already running
- `logs`: stream or dump the log for the running app

## Step 1 - read the project

Read `blueprint/context/platform.md` for this project's evidence ladder and
`AGENTS.md` for the real commands. Do not guess a build command from the stack
name; the project may differ from the default.

## Step 2 - inventory targets

List what actually exists before assuming anything:

| Stack | Inventory command |
| --- | --- |
| Flutter | `flutter devices` |
| iOS | `xcrun simctl list devices available` |
| Android | `adb devices -l`, `emulator -list-avds` |
| React Native | both `xcrun simctl list devices available` and `adb devices -l` |

Report what is available, what is already running, and what is missing.

**If no target exists**, say so plainly and stop. Do not infer behavior from the
code as a substitute. "No device available" is the correct, useful answer.

**If the host cannot support a platform**, say so. iOS needs macOS. On Linux or
Windows there is no iOS simulator and no `xcodebuild`, and reporting that is not
a failure of this skill.

## Step 3 - choose a target

In order of preference:

1. A target already booted and warm. Cold boot costs 30-90 seconds and there is
   rarely a reason to pay it twice in one session.
2. A target matching the project's minimum supported version, when the claim
   being checked is version-sensitive.
3. The default modern simulator or emulator.

State which target you chose and why in one line. When a physical device is
connected, prefer it for anything the simulator fakes: camera, biometrics, push,
Bluetooth, performance.

## Step 4 - build and install

Use the project's real commands. Choose the cheapest path that will actually
show the change:

- **Nothing native changed and the app is already running** - hot reload or Fast
  Refresh. Seconds.
- **Dart, Swift, Kotlin, or JS logic changed but no native config** - hot restart
  or a fast incremental build.
- **Native code, plugins, dependencies, permissions, or app config changed** -
  full rebuild and reinstall. Hot reload will not pick these up, and a result
  observed through a stale reload is a false pass.

Report which path you used, because it determines what the evidence is worth.

If the build fails, report the actual error and stop. Do not retry blindly, and
do not clean-and-rebuild as a reflex: a clean build on this stack can cost ten
minutes and usually is not the fix.

## Step 5 - capture evidence

Screenshots:

| Target | Command |
| --- | --- |
| iOS simulator | `xcrun simctl io booted screenshot out.png` |
| Android | `adb exec-out screencap -p > out.png` |
| Flutter | `flutter screenshot` |

Video, for interaction claims a still cannot show:

- iOS: `xcrun simctl io booted recordVideo out.mp4`
- Android: `adb shell screenrecord /sdcard/out.mp4` then `adb pull`

Logs, which matter as much as the screenshot:

- Android: `adb logcat --pid=$(adb shell pidof -s <package>)`
- iOS: the Xcode console, or `xcrun simctl spawn booted log stream`
- Flutter: the `flutter run` console
- React Native: the Metro log **and** the native log, because native errors
  never reach the JS console

Name every file for the claim and target: `cart-badge-android-api35.png`.

## Step 6 - report

State plainly:

- which target, OS version, and build configuration
- which build path was used (reload, restart, full rebuild)
- what was observed, with file names for screenshots and logs
- **anything in the log**: exceptions, overflow warnings, skipped frames, main
  thread violations, constraint conflicts, yellow or red boxes

A screen that looks correct while the log shows an error is **not a pass**.
Report the log finding even when the screenshot looks fine, and especially then.

## Rules

- **Observe, do not repair.** This skill runs and captures. Fixing is
  `/implement`'s job. It changes no product source and commits nothing.
- **Local targets only.** Never sign a release build, upload to TestFlight or a
  Play track, or contact a store API. That is `/release`, and it needs separate
  explicit approval.
- **Never fabricate a target.** If nothing is available, say so.
- **Never report evidence you did not capture.** A described screenshot that was
  not taken is a fabrication, not a summary.
- **Honest over green.** "Could not verify on Android, no emulator" is a useful
  result that tells the reviewer exactly where to look.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
