# Platform: iOS

What counts as proof that a feature works, and what it costs to get it.

Read this before `/check`, before claiming a done-when is met, and before
reporting any step complete. The web workflow's answer ("start a dev server,
open a URL, screenshot the DOM") does not exist here. This file replaces it.

## The evidence ladder

There is no dev server. Evidence means building, installing onto a simulator or
device, and driving the UI. That is expensive, so pick the **cheapest tier that
can honestly prove the claim** and say which tier you used.

| Tier | Method | Cost | Proves |
| --- | --- | --- | --- |
| 0 | Compile, SwiftLint, warnings | seconds to minutes | It builds. Proves nothing about behavior. |
| 1 | Unit and view-model tests | seconds | Logic and state transitions. |
| 2 | SwiftUI preview or warm simulator | seconds | Layout and simple interaction. |
| 3 | Full build and install on simulator | 1-5 min | Real navigation, state, most behavior. |
| 4 | XCUITest flow | 5-15 min | Cross-screen flows, repeatable. |
| 5 | Physical device, release config | 10+ min | Performance, permissions, hardware, signing, store rules. |

Rules for using the ladder:

- **Never report a tier you did not run.** "Should work" is not a tier.
- **State the tier in the report.** `[pass] (tier 3) Cart badge updates on add`
  tells a reviewer exactly how much the pass is worth.
- **Tier 0 alone never proves a done-when.** A clean build is a precondition, not
  evidence. This is the single most likely false pass in this stack, because
  Swift's compiler is strong enough to make a green build feel conclusive.
- **SwiftUI previews are tier 2 and lie about some things.** They do not exercise
  real navigation stacks, real data, app lifecycle, or anything behind
  `@Environment` you did not inject. A preview is good evidence for layout and
  bad evidence for behavior.
- **Escalate for**: permissions, push notifications, background modes, deep
  links, keychain, biometrics, in-app purchase, camera, location. The simulator
  fakes several of these convincingly, which makes it a source of false passes
  rather than a shortcut. Face ID "works" in the simulator via a menu command,
  which is not the same as working.
- **Debug builds do not prove performance.** Any claim about smoothness, launch
  time, or memory needs a Release build on real hardware (tier 5) and Instruments
  for anything numeric.

## Device and OS matrix

One binary runs across a range of devices and OS versions, and the divergences
are routine:

| Divergence | Where it bites |
| --- | --- |
| Screen size and safe areas | Notch, Dynamic Island, home indicator, iPad |
| Deployment target | An API available on the newest OS but not your minimum |
| Dynamic Type | Largest accessibility sizes break fixed layouts |
| Dark mode | Hardcoded colors, missing asset variants |
| Orientation and multitasking | iPad split view, rotation |
| Locale | Right-to-left layout, date and number formats |

**The matrix.** Every `/check` report states which device and OS version the
evidence came from:

    Done-when                      iPhone 16 / iOS 18   iPhone SE / iOS 17
    Cart badge updates on add      pass (t3)            pass (t3)
    Layout holds at largest text   fail (t2): clipped   fail (t2): clipped
    Checkout completes             pass (t4)            skip: not run

- Verifying on the newest simulator only, then claiming the feature works, is the
  most common false pass here. If the project's deployment target is older than
  the simulator you used, say so.
- Smallest supported device plus largest Dynamic Type is the layout stress case
  worth checking whenever a screen changes.

## Targets

- List available simulators with `xcrun simctl list devices available` before
  assuming one exists.
- Prefer a warm, already-booted simulator. Booting costs 30-60 seconds.
- **iOS development requires macOS.** On Linux or Windows there is no simulator
  and no `xcodebuild`. That is a reported blocker, not something to work around.
- Physical devices are required for: camera, biometrics, push notifications,
  Bluetooth, real performance, cellular behavior, and background execution.

## Capturing evidence

- Screenshots: `xcrun simctl io booted screenshot out.png`, or Xcode's debug
  screenshot for a device.
- Video for interaction claims: `xcrun simctl io booted recordVideo out.mp4`.
- Name evidence for the claim and target: `cart-badge-iphone16.png`.
- Watch the console while driving the UI. Constraint conflicts, main-thread
  violations, `Publishing changes from within view updates` warnings, and
  unhandled exceptions all mean **not a pass**, even if the screen looks right.
  This is the mobile equivalent of a clean page with console errors.
- Purple runtime issues in Xcode are failures, not suggestions.

## Signing and capabilities

Verification that touches entitlements is different from ordinary UI work:

- Push notifications, App Groups, iCloud, HealthKit, and in-app purchase all
  need a matching provisioning profile. A simulator build can succeed and the
  feature still be broken on device.
- Never print, log, or commit certificates, private keys, provisioning profiles,
  or App Store Connect API keys. Reference them by name.
- A capability claim proven only in the simulator is marked partial.

## Honest failure modes

Report these plainly rather than working around them:

- **Not on macOS.** No iOS verification is possible. Say so and stop.
- **No simulator for the deployment target.** Name what you used instead.
- **Claim needs a physical device.** Mark it and hand it to `/check guide`.
- **Build too slow to justify for this step.** Say which tier you used and what
  it leaves unproven.

"Could not verify" is a useful result. A fabricated pass is worse than no
evidence, because it removes the reviewer's reason to look.
