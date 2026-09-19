# Platform: Android

What counts as proof that a feature works, and what it costs to get it.

Read this before `/check`, before claiming a done-when is met, and before
reporting any step complete. The web workflow's answer ("start a dev server,
open a URL, screenshot the DOM") does not exist here. This file replaces it.

## The evidence ladder

There is no dev server. Evidence means building, installing onto an emulator or
device, and driving the UI. That is expensive, so pick the **cheapest tier that
can honestly prove the claim** and say which tier you used.

| Tier | Method | Cost | Proves |
| --- | --- | --- | --- |
| 0 | `assembleDebug`, lint | seconds to minutes | It builds. Proves nothing about behavior. |
| 1 | JVM unit tests | seconds | Logic and view-model state transitions. |
| 2 | Compose preview or warm emulator | seconds | Layout and simple interaction. |
| 3 | `installDebug` on emulator | 1-5 min | Real navigation, state, most behavior. |
| 4 | Instrumented or Compose UI test | 5-15 min | Cross-screen flows, repeatable. |
| 5 | Physical device, release build | 10+ min | Performance, permissions, hardware, R8, store rules. |

Rules for using the ladder:

- **Never report a tier you did not run.** "Should work" is not a tier.
- **State the tier in the report.** `[pass] (tier 3) Cart badge updates on add`
  tells a reviewer exactly how much the pass is worth.
- **Tier 0 alone never proves a done-when.** A green build is a precondition, not
  evidence. This is the single most likely false pass in this stack.
- **Compose previews are tier 2 and lie about some things.** They do not exercise
  real navigation, real data, lifecycle, or process death. Good evidence for
  layout, bad evidence for behavior.
- **Escalate for**: permissions, background work, notifications, deep links,
  process death and restore, configuration change, storage access, foreground
  services. These are exactly the areas where reading the code is least
  predictive of what the OS actually does.
- **Debug builds do not prove release behavior.** R8 and resource shrinking run
  only in release, and they break reflection-dependent code, serialization, and
  keep-rule-sensitive libraries. A feature that works in debug and crashes in
  release is a normal Android outcome, not an exotic one. Any claim about
  shipping behavior, size, or performance needs tier 5.

## The fragmentation matrix

One APK runs across an enormous range of API levels, OEM skins, screen sizes, and
memory budgets. The divergences that bite in practice:

| Divergence | Where it bites |
| --- | --- |
| API level | Behavior changes at 33, 34, 35: permissions, notifications, background |
| OEM skins | Samsung, Xiaomi, and others alter background limits and permissions |
| Screen size and density | Small phones, foldables, tablets, display size setting |
| Font scale and display size | Largest settings break fixed layouts |
| Predictive back | Behavior differs by API level and opt-in flag |
| Dark mode and configuration change | Activity recreation, state restore |
| Low memory | Process death, which is routine, not an edge case |

**The matrix.** Every `/check` report states which API level and device the
evidence came from:

    Done-when                       Pixel / API 35      API 26 min
    Cart badge updates on add       pass (t3)           skip: not run
    Notification appears            pass (t3)           fail (t3): no channel
    State survives rotation         pass (t3)           pass (t3)

- Verifying on the newest emulator only, then claiming the feature works, is the
  most common false pass here. If `minSdk` is well below the emulator you used,
  say so and mark the low end unverified.
- **Process death is not an edge case.** For any feature holding state across
  screens, verify with "Don't keep activities" enabled or
  `adb shell am kill <package>`. This is the cheapest way to find the bug class
  users hit most and developers test least.

## Targets

- List targets with `adb devices -l` and `emulator -list-avds` before assuming
  one exists.
- Prefer a warm, already-running emulator. Cold boot costs 30-90 seconds.
- Emulators are available on macOS, Linux, and Windows, so Android verification
  has no host restriction the way iOS does. Hardware acceleration matters: an
  emulator without it is slow enough to change what is worth verifying.
- Physical devices are required for: camera, biometrics, real performance, OEM
  background behavior, cellular, and Bluetooth.

## Capturing evidence

- Screenshots: `adb exec-out screencap -p > out.png`
- Video: `adb shell screenrecord /sdcard/out.mp4` then `adb pull`
- Name evidence for the claim and target: `cart-badge-api35.png`
- **Watch logcat while driving the UI.** Filter to your package:
  `adb logcat --pid=$(adb shell pidof -s com.example.app)`. A screen that looks
  right while logcat shows a caught-and-ignored exception, an ANR warning, a
  `StrictMode` violation, or a skipped-frames message is **not a pass**. This is
  the mobile equivalent of a clean page with console errors.
- "Skipped N frames! The application may be doing too much work on its main
  thread" is a performance defect, not a log curiosity.

## Signing and release

- Never print, log, or commit keystores, passwords, or service account JSON.
  Reference them by name.
- `versionCode` must increase for every upload. A collision is rejected at
  upload and wastes a review cycle.
- A release-build claim requires an actual release build. Debug signing proves
  nothing about the shipped artifact.

## Honest failure modes

Report these plainly rather than working around them:

- **No emulator or device available.** Say so, mark claims unverifiable.
- **Only the newest API level available.** Name it and mark the minimum unverified.
- **Claim needs a physical device or a specific OEM.** Mark it and hand it to
  `/check guide`.
- **Build too slow to justify for this step.** Say which tier you used and what
  it leaves unproven.

"Could not verify" is a useful result. A fabricated pass is worse than no
evidence, because it removes the reviewer's reason to look.
