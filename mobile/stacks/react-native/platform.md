# Platform: React Native

What counts as proof that a feature works, and what it costs to get it.

Read this before `/check`, before claiming a done-when is met, and before
reporting any step complete. React Native looks close enough to web that the web
workflow's habits feel like they should port. They mostly do not, and this file
replaces them.

## The evidence ladder

Metro is a bundler, not a dev server you can screenshot. Evidence means running
the app on a simulator, emulator, or device and driving the UI. Pick the
**cheapest tier that can honestly prove the claim** and say which tier you used.

| Tier | Method | Cost | Proves |
| --- | --- | --- | --- |
| 0 | `tsc --noEmit`, lint | seconds | It typechecks. Proves nothing about behavior. |
| 1 | Jest unit and component tests | seconds | Logic and single-component rendering. |
| 2 | Fast Refresh on a warm app | seconds | Visual and interaction claims, live. |
| 3 | Full rebuild and install | 2-10 min | Native modules, permissions, startup, deep links. |
| 4 | Maestro or Detox flow, both platforms | 5-20 min | Cross-screen flows, repeatable. |
| 5 | Release build on a physical device | 15+ min | Performance, bundle size, signing, store rules. |

Rules for using the ladder:

- **Never report a tier you did not run.** "Should work" is not a tier.
- **State the tier in the report.** `[pass] (tier 2) Cart badge updates on add`
  tells a reviewer exactly how much the pass is worth.
- **Tier 0 alone never proves a done-when.** A clean typecheck is a precondition,
  not evidence. This is the single most likely false pass in this stack, because
  TypeScript's coverage feels more complete than it is at the native boundary.
- **Fast Refresh has real limits.** It does not reinitialize module-level state,
  does not re-run app startup, and does **not** pick up native module changes at
  all. Any change touching `ios/`, `android/`, a new native dependency, or app
  config needs a full rebuild (tier 3). A pass observed through stale Fast
  Refresh is a false pass, and this is the most common way it happens here.
- **Adding a native dependency invalidates tier 2 entirely.** Rebuild both
  platforms. `pod install` for iOS. Expo managed projects may need `prebuild`.
- **Debug builds do not prove performance.** JS runs unoptimized, the dev bundle
  is large, and Hermes behaves differently. Any claim about smoothness, list
  scrolling, startup, or bundle size needs a release build (tier 5).

## One codebase, two apps

The whole value proposition of this stack is one codebase, which makes it the
easiest stack to produce a false pass in: verifying on the iOS simulator says
very little about Android. Routine divergences:

| Divergence | Where it bites |
| --- | --- |
| Safe areas | Notch and Dynamic Island vs Android gesture bar and cutouts |
| Back navigation | Android hardware and gesture back has no iOS equivalent |
| Shadows | `shadow*` is iOS only, `elevation` is Android only |
| Keyboard | Different avoidance behavior, `KeyboardAvoidingView` needs per-platform config |
| Fonts | Different default families and metrics, so text wraps differently |
| Permissions | Different prompts, timing, and denial states |
| Deep links | Universal Links vs App Links, configured separately |
| Scroll physics | Bounce vs overscroll glow |
| Text rendering | Vertical centering and line height differ |

**The platform matrix.** Every feature spec carries one. Every `/check` report
fills it in per platform:

    Done-when                         iOS        Android
    Cart badge updates on add         pass (t2)  pass (t2)
    Hardware back returns to list     skip       fail (t3): exits app
    Keyboard does not cover input     pass (t2)  fail (t2): covered
    Permission denial shows fallback  pass (t3)  pass (t3)

- A done-when proven on one platform and blank on the other is **not proven**.
  Report it as partial, never as a pass.
- `skip` is honest when a claim is genuinely platform-specific, such as hardware
  back on iOS. Say why.
- If only one platform is available (no macOS, so no iOS simulator), say so and
  mark the other unverifiable. Do not verify one and imply both.

## Expo versus bare

These behave differently enough that the report should say which one applies:

- **Expo Go** cannot load custom native modules. A feature using one requires a
  development build, and testing it in Expo Go will fail in a way that looks like
  a code bug but is not.
- **Managed workflow** config changes (`app.json`, plugins, permissions) need
  `expo prebuild` and a rebuild to take effect.
- **Bare workflow** requires `pod install` after any native dependency change.
- `npx expo-doctor` catches version mismatches cheaply. Run it before blaming
  application code for a strange native failure.

## Targets

- List targets with `xcrun simctl list devices available` and `adb devices -l`
  before assuming one exists.
- Prefer a warm, already-running simulator or emulator.
- iOS requires macOS. On Linux or Windows, iOS verification is unavailable, and
  that is a reported gap, not a silent omission.
- Physical devices are required for: camera, biometrics, push notifications,
  Bluetooth, real performance, and background behavior.

## Capturing evidence

- Screenshots: `xcrun simctl io booted screenshot out.png` (iOS),
  `adb exec-out screencap -p > out.png` (Android).
- Name evidence for the claim and platform: `cart-badge-android.png`.
- **Watch the Metro log and the native log while driving the UI.** A yellow box,
  a caught promise rejection, a `VirtualizedList` performance warning, or a red
  box on the other platform all mean **not a pass**, even if the screen looks
  right. This is the mobile equivalent of a clean page with console errors.
- Check logcat on Android and the Xcode console on iOS for native-side errors
  that never reach the JS log.

## Honest failure modes

Report these plainly rather than working around them:

- **No device or simulator available.** Say so, mark claims unverifiable.
- **iOS unavailable on this machine.** Mark the iOS column unverifiable.
- **Feature needs a development build, only Expo Go available.** Say so.
- **Rebuild too slow to justify for this step.** Say which tier you used and what
  it leaves unproven.

"Could not verify" is a useful result. A fabricated pass is worse than no
evidence, because it removes the reviewer's reason to look.
