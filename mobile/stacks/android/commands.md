<!-- blueprint:onboarding-required -->
For a standard Gradle project. Confirm the module name and variants during
`/onboard`; `app` is the convention but not a guarantee.

- Tasks: `./gradlew tasks`
- Devices: `adb devices -l`
- Emulators: `emulator -list-avds`
- Build debug: `./gradlew :app:assembleDebug`
- Install debug: `./gradlew :app:installDebug`
- Unit tests: `./gradlew :app:testDebugUnitTest`
- Instrumented tests: `./gradlew :app:connectedDebugAndroidTest` (needs a device)
- Lint: `./gradlew :app:lintDebug`
- Format: `./gradlew ktlintFormat` or `./gradlew spotlessApply` (if configured)
- Release bundle: `./gradlew :app:bundleRelease`
- Verify: `./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug`

Keep `connectedDebugAndroidTest` out of `Verify`. It needs a running device and
takes minutes, so it belongs in `/check`, not the per-step gate.

Use `./gradlew --offline` when dependencies are already cached and the network
is slow or unavailable.
