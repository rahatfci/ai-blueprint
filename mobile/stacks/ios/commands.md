<!-- blueprint:onboarding-required -->
For a standard Xcode project. Replace `App` with the real scheme name and
confirm every command during `/onboard`. Use `-workspace App.xcworkspace` when
the project uses CocoaPods or a workspace, and `-project App.xcodeproj` when it
does not.

- Schemes: `xcodebuild -list`
- Simulators: `xcrun simctl list devices available`
- Build: `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Tests: `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' test`
- UI tests: same command with the UI test plan or `-only-testing:AppUITests`
- Lint: `swiftlint` (if configured)
- Format: `swift-format format -i -r Sources` (if configured)
- Archive: `xcodebuild -scheme App -configuration Release archive -archivePath build/App.xcarchive`
- Verify: `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build test`

Pipe through `xcbeautify` or `xcpretty` when available; raw `xcodebuild` output
is long enough to bury the failure. Keep the raw log available for diagnosis.

Swift Package Manager projects without an Xcode project use `swift build` and
`swift test` instead.
