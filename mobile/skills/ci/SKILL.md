---
name: ci
description: Set up or normalize one project Verify command and matching automatic checks for a mobile app, handling macOS runners, SDK caching, and signing boundaries, with an optional local pre-push hook. Use for /ci, GitHub Actions for mobile, pull-request checks, or build caching.
disable-model-invocation: true
---

# ci - automatic checks for a mobile project

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`.

Where this sits in the workflow:

    /onboard  ->  [ci]  ->  Verify locally  ->  CI runs Verify
    (commands)   (setup)    (same recipe)      (pull requests)

Keep the explanation simple:

- **Verify is the recipe.** It runs checks the project already has.
- **CI is the worker.** It runs the same recipe automatically.
- **A branch ruleset is the lock.** That optional remote setting can require
  green before merge.
- **A pre-push hook is the early warning.** Optional, local, and `git push
  --no-verify` skips it, so it is a convenience, not the lock.

## What is different about mobile CI

Mobile CI has three constraints web CI does not, and ignoring them produces a
pipeline that is either broken or expensive:

1. **iOS requires macOS runners.** They cost several times a Linux runner per
   minute on most providers. An iOS job that runs on every push to every branch
   is a real bill. Scope it deliberately.
2. **Builds are slow and cache-sensitive.** Gradle, CocoaPods, SPM, Dart, and
   node_modules caches are the difference between a three-minute job and a
   twenty-minute one. Cache keys must include the lockfile hash or the cache goes
   stale silently and you debug a phantom.
3. **Signing secrets do not belong in CI for a check pipeline.** A pull-request
   check should build unsigned or simulator-only. Signing belongs in a separate,
   protected release workflow with its own approval, so an untrusted pull request
   can never reach a signing key.

## Step 1 - inspect without changing files

Read `AGENTS.md` Commands and any documented `Verify`, the build configuration,
lockfiles, SDK version files (`.tool-versions`, `.nvmrc`, `.ruby-version`,
Gradle wrapper properties, `pubspec.lock`), existing `.github/workflows/`, and
the current branch, default branch, and remotes.

Do not assume GitHub Actions, `main`, or a particular provider from the template.
Do not run installs or edit files during inspection.

If a workflow already provides equivalent checks, explain what it runs. If it is
healthy and aligned with `Verify`, report that no setup is needed. If
normalization would change existing CI, show the proposed change and get explicit
approval before editing.

## Step 2 - define one Verify command

Build one command from checks that actually exist, in this order:

1. static analysis and lint
2. unit tests, when a real test command is configured
3. debug build

Defaults per stack, to confirm against the project:

| Stack | Verify |
| --- | --- |
| Flutter | `flutter analyze && flutter test && flutter build apk --debug` |
| iOS | `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build test` |
| Android | `./gradlew :app:lintDebug :app:testDebugUnitTest :app:assembleDebug` |
| React Native | `npx tsc --noEmit && npm run lint && npm test` |

**Keep device-dependent and release steps out of `Verify`.** Instrumented tests,
e2e flows, release builds, and archives are slow and need real targets or
secrets. They belong in `/check` and `/release`, or in a separate scheduled
workflow, never in the per-pull-request gate.

Record the exact command in the Commands section of `AGENTS.md`.

## Step 3 - propose the workflow

Propose a workflow that runs the same `Verify` on pull requests and pushes to the
default branch. Show it and get approval before writing.

Apply these defaults:

- **Runner:** Linux for Flutter analyze and test, Android, and React Native
  JS-side checks. macOS **only** for iOS compilation and simulator work.
- **Permissions:** `contents: read` only.
- **Caching:** key on the lockfile hash. Cache Gradle (`~/.gradle/caches`,
  `~/.gradle/wrapper`), CocoaPods (`ios/Pods`), SPM, pub (`~/.pub-cache`), and
  node_modules as the stack requires.
- **Concurrency:** cancel superseded runs on the same branch. Mobile jobs are
  slow enough that stacked runs waste real money.
- **Timeout:** set one. A hung emulator or simulator will otherwise burn the full
  job limit.
- **Split jobs per platform** for cross-platform stacks, so an Android failure is
  legible without reading an iOS log.
- **No signing secrets.** Build unsigned or simulator-only in this pipeline.

Do not add coverage gates, device farms, screenshot testing, store uploads, or
version matrices. Those are separate later choices.

## Step 4 - offer the pre-push hook

Offer, do not impose. Mobile `Verify` can take minutes, so a pre-push hook is
more intrusive here than on a web project. Say how long it takes locally before
asking, and mention `--no-verify` exists.

## Step 5 - report

State the `Verify` command, what CI will run and on which runners, roughly what
it will cost in minutes, what was deliberately left out, and what remains a
manual remote setting (branch protection, required checks, signing secrets for a
future release workflow).

## Rules

- **Never put signing secrets in a pull-request pipeline.** A fork pull request
  must never reach a keystore or certificate.
- **Never add store upload or release steps** to the check workflow. Releasing is
  `/release`, and it needs explicit human approval.
- Do not replace existing CI without showing the change and getting approval.
- Do not push, publish, or change remote settings. Branch protection is a remote
  setting the user applies.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
