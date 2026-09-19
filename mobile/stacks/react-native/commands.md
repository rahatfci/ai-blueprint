<!-- blueprint:onboarding-required -->
For a standard React Native project. Confirm the package manager and whether the
project is Expo or bare during `/onboard`; the commands differ meaningfully.

- Metro bundler: `npm start`
- Run iOS: `npm run ios` (or `npx expo run:ios`)
- Run Android: `npm run android` (or `npx expo run:android`)
- Devices: `xcrun simctl list devices available` and `adb devices -l`
- Typecheck: `npx tsc --noEmit`
- Lint: `npm run lint`
- Unit tests: `npm test`
- E2E tests: `maestro test .maestro/` or `detox test` (if configured)
- Build iOS release: `npx expo run:ios --configuration Release`, or Xcode archive
- Build Android release: `cd android && ./gradlew bundleRelease`
- Verify: `npx tsc --noEmit && npm run lint && npm test`

Expo projects add `npx expo-doctor` as a useful preflight and
`npx expo prebuild` when native config changes.

Keep E2E out of `Verify`. It needs a device and takes minutes, so it belongs in
`/check`, not the per-step gate.
