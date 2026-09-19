<!-- blueprint:onboarding-required -->
For a standard Flutter project. Confirm these against the real project during
`/onboard` and correct anything that differs.

- Run: `flutter run` (add `-d <device-id>` to target one device)
- Devices: `flutter devices`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Unit and widget tests: `flutter test`
- Integration tests: `flutter test integration_test`
- Build Android debug: `flutter build apk --debug`
- Build iOS simulator: `flutter build ios --simulator --no-codesign`
- Build Android release: `flutter build appbundle --release`
- Build iOS release: `flutter build ipa --release`
- Verify: `flutter analyze && flutter test && flutter build apk --debug`

`Verify` is the umbrella automated gate. It combines only checks this project
actually has. Do not add integration or release builds to it; those are slow
gates that belong in `/check` and `/release`.
