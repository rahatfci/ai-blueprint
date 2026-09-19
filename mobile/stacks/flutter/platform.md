# Platform: Flutter

What counts as proof that a feature works, and what it costs to get it.

Read this before `/check`, before claiming a done-when is met, and before
reporting any step complete. The web workflow's answer ("start a dev server,
open a URL, screenshot the DOM") does not exist here. This file replaces it.

## The evidence ladder

There is no dev server. Evidence means building, installing onto a target, and
driving the UI. That is expensive, so pick the **cheapest tier that can honestly
prove the claim** and say which tier you used.

| Tier | Method | Cost | Proves |
| --- | --- | --- | --- |
| 0 | `flutter analyze` | seconds | It compiles and passes lints. Proves nothing about behavior. |
| 1 | `flutter test` | seconds | Logic and single-screen rendering and interaction. |
| 2 | Hot reload on a warm device | seconds | Visual and interaction claims, live. |
| 3 | Full rebuild and install | 1-5 min | Plugin changes, native code, startup, deep links, permissions. |
| 4 | `flutter test integration_test` on both platforms | 5-15 min | Cross-screen flows and real platform behavior. |
| 5 | Release build on a physical device | 10+ min | Performance, size, signing, store rules, real hardware. |

Rules for using the ladder:

- **Never report a tier you did not run.** "Should work" is not a tier.
- **State the tier in the report.** `[pass] (tier 2) Cart badge updates on add`
  tells a reviewer exactly how much the pass is worth.
- **Tier 0 alone never proves a done-when.** A green analyze is a precondition,
  not evidence. This is the single most likely false pass in this stack.
- **Escalate when the claim demands it.** Anything touching a plugin, a platform
  channel, permissions, the keyboard, deep links, background behavior, or
  startup requires tier 3 or above, because hot reload does not re-run native
  initialization and will show you stale behavior.
- **Hot reload has real limits.** It does not re-run `main()`, does not
  reinitialize static state or `initState` for already-mounted widgets, and does
  not pick up native or plugin changes. When a change touches any of those,
  hot restart (tier 2.5) or rebuild (tier 3). A pass observed through a stale
  hot reload is a false pass.
- **Debug builds do not prove performance.** Any claim about smoothness, frame
  rate, startup time, or memory needs `--profile` or `--release` on real
  hardware (tier 5). Debug mode is materially slower and saying otherwise is
  reporting a number you know to be wrong.

## One codebase, two apps

A Flutter feature is not done when it works on one platform. The same Dart code
produces two apps that diverge routinely:

| Divergence | Where it bites |
| --- | --- |
| Safe areas and notches | Any full-bleed layout, bottom bars |
| Back navigation | Android system back and predictive back, iOS edge swipe |
| Permissions | Different prompts, timing, and denial states |
| Keyboard | Different inset behavior, `resizeToAvoidBottomInset` |
| Fonts and text metrics | Same string, different width, overflow on one side |
| Dates, numbers, locale | Different default formats |
| Deep links | App Links vs Universal Links, separate configuration |
| Scroll physics | Bounce vs glow, affects any scroll-dependent UI |

**The platform matrix.** Every feature spec carries one. Every `/check` report
fills it in per platform:

    Done-when                         iOS        Android
    Cart badge updates on add         pass (t2)  pass (t2)
    Back gesture returns to list      pass (t2)  fail (t3): closes app
    Permission denial shows fallback  skip       pass (t3)

- A done-when proven on one platform and blank on the other is **not proven**.
  Report it as partial, never as a pass.
- `skip` is a valid, honest result when a claim is genuinely platform-specific.
  Say why.
- If only one platform is available (no macOS machine, so no iOS simulator), say
  that plainly in the report and mark the other platform unverifiable. Do not
  quietly verify one and imply both.

## Targets

- List targets with `flutter devices` before assuming one exists.
- Prefer a warm, already-running simulator or emulator over booting a new one.
  Booting costs 30-60 seconds and there is rarely a reason to pay it twice.
- iOS simulators require macOS. On Linux or Windows, iOS verification is
  unavailable, and that is a reported gap, not a silent omission.
- Physical devices are required for: camera, biometrics, push notifications,
  Bluetooth, real performance, and anything the simulator fakes. The simulator
  will happily return a plausible-looking fake for several of these, which makes
  it a source of false passes rather than a shortcut.

## Capturing evidence

- Screenshots: `flutter screenshot` for the connected device, or the platform
  tools (`xcrun simctl io booted screenshot`, `adb exec-out screencap -p`).
- Name screenshots for the claim and platform: `cart-badge-android.png`.
- Watch the run log for exceptions while driving the UI. A screen that looks
  right while the log shows a rendering overflow or an unhandled exception is
  **not a pass**. This is the mobile equivalent of a clean page with console
  errors, and it is just as disqualifying.
- Yellow-and-black overflow stripes mean fail, even if the rest of the screen is
  correct.

## Honest failure modes

Report these plainly rather than working around them:

- **No device available.** Say so, mark claims unverifiable, do not infer from code.
- **iOS unavailable on this machine.** Mark the iOS column unverifiable.
- **Build takes too long to be worth it for this step.** Say which tier you used
  instead and what that leaves unproven.
- **The claim needs hardware you do not have.** Mark it and hand it to manual
  verification through `/check guide`.

"Could not verify" is a useful result. A fabricated pass is worse than no
evidence, because it removes the reviewer's reason to look.
