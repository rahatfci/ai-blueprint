# Mobile Blueprint

A spec-driven AI coding workflow for mobile apps. Flutter, native iOS, native
Android, and React Native.

This is the mobile layer for [AI Blueprint](https://ai-blueprint.dev). It adds a
second axis to the workflow, the **stack pack**, so the same review gates,
feature specs, and history ledger work on a platform with no dev server, no URL,
and a build measured in minutes.

Not an app starter. Scaffold your app first, then overlay this.

## Install

```bash
curl -fsSL https://mobile-blueprint.dev/install.sh | sh
```

No Node required. `sh`, `curl`, and `tar` are enough, which means it works on
every macOS machine, every Linux CI runner, and WSL.

Prefer to read before running, which is reasonable:

```bash
curl -fsSL https://mobile-blueprint.dev/install.sh -o install.sh
less install.sh
sh install.sh
```

From a checkout, with no download at all:

```bash
git clone https://github.com/<owner>/ai-blueprint
./ai-blueprint/mobile/install.sh --target ./my-app
```

### Options

```
--stack <name>      flutter | ios | android | react-native
                    Detected from project files when omitted.
--adapter <list>    claude, codex, copilot, opencode. Detected or prompted.
--from <dir>        Install from a local bundle instead of downloading.
--target <dir>      Project to install into. Defaults to the current directory.
--dry-run           Print the plan and change nothing.
--force             Overwrite existing Blueprint files without asking.
--yes               Accept detected values without prompting.
```

Run `--dry-run` first if you want to see exactly what it will write.

## What gets installed

```
AGENTS.md                            cross-tool entry point, with your real commands
CLAUDE.md                            Claude Code entry point, imports AGENTS.md
blueprint/
  context/
    coding-standards.md              your stack's conventions
    platform.md                      what counts as proof on your stack
    project-overview.md              generated project context
    current-feature.md               the one thing being built right now
  project-plan.md                    you write this
  build-plan.md                      you write this
  history/                           shipped features, fixes, rollbacks
.claude/skills/  or  .agents/skills/ the workflow commands
```

The installer detects your stack from `pubspec.yaml`, `package.json`,
`*.xcodeproj`, or Gradle files. Cross-platform projects are matched before native
ones, so a Flutter app with `ios/` and `android/` directories is not mistaken for
a native Android project.

## The workflow

```
/feature  ->  /implement  ->  /check  ->  /audit current  ->  /complete
(spec)        (build it)      (prove     (review the        (log it,
                               it on      code)              merge it)
                               a device)
```

Approve the spec before implementing. `/check` proves behavior on a real target.
`/audit` reviews code and records findings. Blocking findings stop `/complete`.

### Mobile-specific commands

| Command | What it does |
| --- | --- |
| `/device` | List, boot, and drive simulators, emulators, and devices. Install builds, capture screenshots and logs. |
| `/check` | Prove each done-when on every target platform, at a named evidence tier. |
| `/check guide` | Read-only manual test instructions for claims needing hardware you do not have. |
| `/tests` | Set up unit, widget, and component testing. `/tests e2e` for device-level flows. |
| `/prototype` | Throwaway native screens to lock navigation and design tokens. |
| `/release` | Store readiness: versioning, signing, permissions, release build. Stops before upload. |
| `/ci` | One Verify command plus automatic checks, with macOS runner and caching handling. |

Everything else (`/feature`, `/implement`, `/complete`, `/audit`, `/status`,
`/doctor`, `/rollback`, `/explore`, `/debug`, `/fix`, `/overview`,
`/autopilot`, `/continuous`) is the standard Blueprint workflow, unchanged.

## What is different from the web version

### There is no dev server

Evidence means build, install on a target, drive the UI, screenshot. That is
expensive, so `blueprint/context/platform.md` defines an **evidence ladder** and
`/check` picks the cheapest tier that honestly proves each claim, then names the
tier it used.

    tier 0  static analysis                seconds
    tier 1  unit and widget tests          seconds
    tier 2  hot reload on a warm target    seconds
    tier 3  full rebuild and install       minutes
    tier 4  integration or e2e flow        many minutes
    tier 5  release build on real hardware longer

A pass is worth what its tier is worth, so the tier is always reported.

### One codebase is two apps

For Flutter and React Native, every feature spec carries a **platform matrix**
and `/check` reports per platform. A done-when proven on iOS and blank on
Android is reported as partial, never as a pass. That single rule prevents the
most likely false result on these stacks.

### Releases cannot be undone

You cannot unpublish a build users installed, cannot reuse a build number, and a
fix waits in a review queue. So `/release` checks versioning, signing, expiry
dates, permissions, and store requirements, runs a real release build, and then
**stops**. Uploading needs an explicit yes in the chat.

### Prototypes are native

Mocking a mobile screen in HTML answers none of the questions worth prototyping:
safe areas, scroll physics, keyboard behavior, touch targets, font scaling.
`/prototype` builds throwaway screens in the real toolkit and produces design
tokens in the platform's own format.

## Stack support

| Stack | Detected by | Test gate | Release target |
| --- | --- | --- | --- |
| Flutter | `pubspec.yaml` | `flutter test` | App Store, Play |
| iOS | `*.xcodeproj`, `Package.swift` | `xcodebuild test` | App Store, TestFlight |
| Android | Gradle files | `testDebugUnitTest` | Play, internal tracks |
| React Native | `package.json` | `npm test` | App Store, Play |

Adding another stack means adding one directory under `stacks/`, not forking the
workflow. See `DESIGN.md`.

## Building a release bundle

```bash
./mobile/scripts/build-bundle.sh dist/
```

Produces the versioned tarball plus a SHA-256 checksum. Every front door
(`install.sh`, Homebrew, pub, npm) resolves to that one artifact, so there is a
single source of truth and a single version number.

## Design notes

`DESIGN.md` covers why the install path is not `npx`, how the stack-pack axis
works, and what is structurally different about verifying mobile software.

## License

MIT, matching the upstream AI Blueprint project.
