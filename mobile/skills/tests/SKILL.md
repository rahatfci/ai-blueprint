---
name: tests
description: Set up unit, widget, and component testing with /tests, or device-level UI and end-to-end testing with /tests e2e. Reuse or configure the stack-native runner, add one example test, document commands, and verify. Use check for one-time live verification.
disable-model-invocation: true
---

# tests - set up mobile testing

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`. Use `tests` as the command for either setup mode.

## Select the setup

- `/tests` or `/tests unit`: stack-native unit, widget, and component testing.
  Fast, no device, runs in the per-step gate.
- `/tests e2e`: device-level UI and end-to-end testing. Slow, needs a target,
  belongs in `/check` rather than the per-step gate.

An explicit natural-language request for end-to-end or UI-automation testing
selects e2e too. A runner name alone never does: `/tests Maestro` is a unit
request with a runner preference to clarify, not permission to install device
automation.

If the user requests both, ask which to set up first and complete one at a time.

## Unit, widget, and component setup

### Step 1 - inspect

Read `AGENTS.md` Commands, `blueprint/context/coding-standards.md`, the build
configuration, and any existing test directories and configuration. Detect the
real setup from files rather than assuming the stack default.

### Step 2 - choose the smallest setup

**Every mobile stack ships a test runner.** Unlike the web workflow, there is
usually nothing to install, so the job is normally to confirm, document, and
prove the runner rather than to add a dependency.

| Stack | Already present | Add only if needed |
| --- | --- | --- |
| Flutter | `flutter test`, `flutter_test`, widget tests | `mocktail` or `mockito` for fakes |
| iOS | XCTest, Swift Testing | `ViewInspector` for SwiftUI assertions |
| Android | JUnit, `testDebugUnitTest` | `Turbine` for flows, `MockK`, `createComposeRule` |
| React Native | Jest | `@testing-library/react-native` |

Prefer the existing runner. Do not add coverage tooling, snapshot frameworks,
mock-service layers, or a test architecture unless the user asks.

### Step 3 - make the changes

Apply the smallest practical diff:

1. Add missing test dependencies or configuration, if any.
2. Add or normalize the test command.
3. Add one small test for real project logic if a suitable function exists,
   otherwise a tiny helper and a test that proves the runner works.
4. Add **one widget or component test** as well, because on mobile the
   render-and-interact test is the workhorse, not an extra. A Flutter widget
   test, an Android Compose UI test, an iOS view-model test, or an RN
   `@testing-library/react-native` test.
5. Update the Commands section of `AGENTS.md` with the real commands.
6. Add the test command to `Verify` between typecheck and build, preserving
   existing checks. Do not create CI only because `/tests` was invoked.
7. Update `blueprint/context/coding-standards.md` only if the project needs a
   note different from the pack default.

Keep device-dependent tests out of the unit command. A unit suite that silently
requires a booted emulator is not a fast gate, and it will fail in CI for
reasons unrelated to the code.

### Step 4 - verify

Run the focused test command, then `Verify`. Report the real output. If the
runner needs a device and you do not have one, say so rather than reporting an
untested setup as working.

## End-to-end setup

### Step 1 - inspect

Check for an existing harness before adding one: `integration_test/` for Flutter,
`androidTest/` for Android, a UI test target for iOS, `.maestro/` or `e2e/` for
React Native.

### Step 2 - choose

| Stack | Prefer |
| --- | --- |
| Flutter | `integration_test` package, which ships with Flutter |
| iOS | XCUITest, which ships with Xcode |
| Android | Espresso and `connectedAndroidTest`, which ship with the SDK |
| React Native | **Maestro** for new setups. Detox only if already established. |

Maestro is the recommendation for React Native because its YAML flows cost far
less to maintain than a Detox suite, and e2e maintenance cost is the reason most
mobile e2e suites are abandoned.

### Step 3 - make the changes

1. Add the harness and one smoke flow: launch the app, reach the main screen,
   assert one visible thing. Not a broad suite.
2. Document the exact command in `AGENTS.md` as `E2E tests`.
3. For cross-platform stacks, confirm the flow runs on **both** platforms and
   document both commands. A harness proven on one platform is half a harness.

### Step 4 - verify and report

Run the smoke flow on a real target and report what happened, including which
target. If no device is available, say the harness is configured but unproven.
Do not report it as working.

## Rules

- **Do not add e2e to `Verify` or CI** without a separate request. It needs a
  device and takes minutes; putting it in the per-step gate makes the loop
  unusable.
- **Do not write a broad suite** for existing app code. This skill proves the
  path and turns on the gate; feature work adds focused tests later.
- **Do not install device automation** under a unit-test request.
- Neither mode creates CI just by being invoked. That is `/ci`.
- Do not commit, merge, push, publish, or begin product feature work.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
