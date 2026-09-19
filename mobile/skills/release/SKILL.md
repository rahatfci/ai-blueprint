---
name: release
description: Prepare App Store, TestFlight, Google Play, and internal distribution readiness by checking versioning, signing, permissions, store metadata, and release builds without uploading. Use for /release, ship to TestFlight, Play Console setup, store submission, or build number checks.
disable-model-invocation: true
---

# release - store readiness, not a submit button

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`.

Where this sits in the workflow:

    /complete  ->  [release]  ->  upload with explicit approval
    (feature       (readiness,    (human confirms the
     finished)      config,        outward-facing,
                    dry run)       irreversible action)

`/release` gets a mobile app ready to ship. It inspects, recommends, creates
local config, and runs local checks. **It is not a submit button.**

## Why this gate is stricter than a web deploy

A bad web deploy is rolled back in thirty seconds. A mobile release is not:

- **You cannot unpublish a build users already installed.** Removing it from the
  store does not remove it from devices.
- **You cannot reuse a build number or `versionCode`.** A collision is rejected
  at upload, and discovering it after a review wait wastes days.
- **A fix requires a new build through review**, which may take a day or more.
  There is no hotfix path that skips the queue.
- **Staged rollouts are halted, not reversed.** Users already updated stay
  updated.
- **A rejection costs a review cycle**, and repeated rejections attract scrutiny
  on later submissions.

So every irreversible action stops for explicit human approval in the current
chat, separately from the readiness work.

## Input

Optional scope:

- no argument: inspect and report readiness for the platforms this project ships
- `ios` / `android`: one platform
- `check`: read-only readiness report, change nothing
- `config`: focus on local config files (Fastlane, signing config, app config)

If the user asks to upload, submit, promote a track, publish, or run a provider
command touching a remote, **pause and ask for explicit confirmation before
doing it**, restating exactly what will happen and that it cannot be undone.

## Step 1 - read the project

Read `AGENTS.md`, `blueprint/context/platform.md`,
`blueprint/context/project-overview.md`, `blueprint/context/current-feature.md`,
the build configuration, and git branch and working tree status.

Platform build configuration:

| Stack | Read |
| --- | --- |
| Flutter | `pubspec.yaml` version, `android/app/build.gradle`, `ios/Runner.xcodeproj`, `ios/Runner/Info.plist` |
| iOS | Xcode project settings, `Info.plist`, entitlements, `ExportOptions.plist`, `Fastfile` |
| Android | `app/build.gradle` versioning and signing, `AndroidManifest.xml`, `proguard-rules.pro`, `Fastfile` |
| React Native | `package.json`, `app.json` or `app.config.js`, plus both native projects above |

Identify: app identifier, current version and build number, signing setup,
minimum OS version, requested permissions, and target tracks.

## Step 2 - version and build number

This is the check most likely to save a wasted cycle, so do it first.

- **Version name** (`1.4.0`, `CFBundleShortVersionString`, `versionName`) is what
  users see. Confirm it matches what shipped in this cycle.
- **Build number** (`CFBundleVersion`, `versionCode`) **must strictly increase**
  for every upload, including rejected and expired ones. Check it against the
  last uploaded value, not against the last released one, because a rejected
  upload still consumes its number.
- For Flutter and React Native, confirm the version propagates to **both**
  native projects. A version bumped in `pubspec.yaml` but stale in a native
  project is a routine and confusing failure.
- Confirm the two platforms are not silently diverging.

Report the current values and the next valid values. Do not bump without approval.

## Step 3 - signing and secrets

Verify presence and correctness. **Never print, log, echo, or commit** any of
these, and never write one into a config file in the repo:

- iOS: signing certificate, provisioning profile, and their expiry dates; the
  entitlements the profile grants versus the ones the app declares; team id;
  App Store Connect API key referenced by name
- Android: keystore presence, alias, and expiry; the Play service account
  referenced by name; whether Play App Signing is in use
- Confirm secrets come from the environment, a secret manager, or a
  gitignored local file, never from tracked source
- Confirm `.gitignore` covers keystores, `.p12`, `.mobileprovision`, `.jks`, and
  service account JSON

**An expired certificate or profile is a blocker, not a warning.** Report it as
one, with the expiry date.

## Step 4 - store requirements

Check the requirements that cause most rejections:

**Both platforms**
- Privacy policy URL present and reachable
- Every requested permission has a clear user-facing purpose string, and every
  permission the app requests is actually used. An unused permission is a
  rejection risk and a privacy problem.
- Data safety and privacy declarations match what the app actually collects,
  including what third-party SDKs collect
- Icons and screenshots present for every required size
- Minimum OS version consistent with the declared support

**iOS**
- `Info.plist` usage descriptions for every sensitive API (camera, location,
  photos, microphone, contacts, tracking). A missing string is a crash on first
  use, not a warning.
- App Tracking Transparency prompt if any tracking occurs
- Encryption declaration
- Account deletion path if the app supports account creation

**Android**
- Target API level meets the current Play requirement, which changes annually
  and is enforced by rejection
- `AndroidManifest.xml` permissions justified, with a declaration form filled for
  sensitive ones
- App bundle, not APK, for Play distribution
- Data safety form matches actual behavior

## Step 5 - release build

Run a real release build locally and report what it produced:

- Flutter: `flutter build appbundle --release`, `flutter build ipa --release`
- iOS: `xcodebuild archive` with the release configuration
- Android: `./gradlew bundleRelease`
- React Native: the platform commands above

Then check what only a release build reveals:

- **It actually builds in release configuration.** R8, ProGuard, and Swift
  optimization break things debug builds never touch: reflection, serialization,
  keep-rule-sensitive libraries. A feature that works in debug and crashes in
  release is a normal outcome on these stacks, not an exotic one.
- **Artifact size**, compared against the previous release. A large jump is worth
  explaining before shipping.
- **It launches and completes a core flow on a physical device** in release
  configuration. This is the only tier that proves shipping behavior.

If the release build fails, that is the finding. Report it and stop.

## Step 6 - report

Give a readiness verdict per platform:

    iOS
    [ok]    Version 1.4.0, build 47 (last uploaded 46)
    [ok]    Signing valid until 2027-03-11
    [block] NSCameraUsageDescription missing, scanner crashes on first use
    [warn]  Bundle grew 12 MB since 1.3.0

    Android
    [ok]    versionName 1.4.0, versionCode 47
    [block] targetSdk 33, Play requires 35
    [ok]    Release bundle builds, 24 MB

State plainly whether the app is ready to upload. Then stop.

## Rules

- **Never upload, submit, promote, or publish without an explicit yes in the
  current chat.** Not implied by `/release`, not implied by "ship it" earlier in
  the conversation, not implied by a green report. Restate what will happen and
  that it cannot be undone, then wait.
- **Never print or commit a secret.** Certificates, keystores, passwords, API
  keys, and service accounts are referenced by name only.
- **Recommend staged rollout.** Play staged rollout and App Store phased release
  are the only real mitigation for an irreversible channel. Default to them.
- **A blocker is a blocker.** An expired profile, a missing usage description, or
  a target API below the store minimum stops the release. Do not downgrade one to
  a warning to produce a cleaner report.
- **Report honestly.** "Not ready, here is why" is the valuable output. A release
  gate that always says ready is not a gate.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
