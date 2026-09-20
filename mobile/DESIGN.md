# Mobile Blueprint: design and distribution

The reasoning behind a mobile-focused Blueprint, and why the install path changes.

## 1. What is actually web-specific

The Blueprint payload is plain markdown plus one small Node script. Nothing in
the workflow engine is web-bound. The web assumptions live in exactly seven
places:

| File | Web assumption |
| --- | --- |
| `blueprint/context/coding-standards.md` | Next.js, React, Tailwind, Prisma, Zod, Clerk |
| `AGENTS.md` Commands block | `npm run dev` at `http://localhost:3000` |
| `check/reference/verify.md` | Evidence means "drive a browser to a route" |
| `tests/reference/unit.md` | Vitest as the default runner |
| `tests/reference/browser.md` | Playwright harness |
| `release/SKILL.md` | Render and Vercel |
| `prototype/SKILL.md` | Throwaway static HTML and CSS mockups |

Roughly eighteen other skills (`feature`, `implement`, `complete`, `audit`,
`status`, `doctor`, `rollback`, and the rest) are already stack-neutral. They
reference "the project's real commands" rather than naming npm.

**Consequence:** a mobile version is not a fork. It is a second value on an axis
the project does not have yet.

## 2. The missing axis

Today the installer varies one thing: which AI tool adapter to write
(`codex`, `claude`, `copilot`, `opencode`). The stack is fixed at Next.js.

Mobile adds a second axis:

    adapter  x  stack
    -------     -----
    codex       flutter
    claude      ios
    copilot     android
    opencode    react-native

A **stack pack** is the set of files that answer four questions for one platform:

1. What are this project's real commands? (`commands.md`)
2. What are this project's conventions? (`coding-standards.md`)
3. What counts as proof a feature works? (`platform.md`)
4. How does this project ship? (`release.md`)

The installer copies the neutral base, then overlays the selected pack. Adding
Kotlin Multiplatform or .NET MAUI later means adding one directory, not forking
the workflow.

## 3. Why `npx` is the wrong front door for mobile

`npx create-ai-blueprint` is a reasonable default for the web version because its
users already have Node installed. That is not true for mobile:

| Developer | Has Node? | Reaction to `npx` |
| --- | --- | --- |
| React Native / Expo | Yes | Natural, already their idiom |
| Flutter | Sometimes | Foreign. Their idiom is `dart pub global activate` |
| iOS / Swift | Often not | Alien. Their idiom is Homebrew or SPM |
| Android / Kotlin | Often not | Alien. Their idiom is Gradle or SDKMAN |

Requiring Node to install a pile of markdown files is a real adoption tax on
three of the four target audiences, and it reads as a category error: a native
iOS developer being told to install a JavaScript runtime to get a coding
workflow will reasonably assume the tool is not for them.

## 4. Recommended distribution: one bundle, several front doors

Publish the pack **once** as a versioned, signed tarball. Then ship thin
front doors so each community installs it the way it already installs things.
Every front door resolves to the same content, so there is one source of truth
and one version number.

    versioned tarball (the only artifact that matters)
        |
        +-- install.sh          curl | sh          all platforms, zero runtime
        +-- Homebrew formula    brew install       macOS, where every iOS dev is
        +-- pub package         dart pub global    Flutter
        +-- npm package         npx                React Native, unchanged
        +-- git clone           degit / sparse     air-gapped and locked-down orgs

### Primary: a POSIX shell installer

```bash
curl -fsSL https://mobile-blueprint.dev/install.sh | sh
```

Nothing is hosted at that domain yet. The installer and the bundle packager are
built and tested; publishing a release is the remaining step. Until then,
installing from a checkout produces a byte-identical result.

This is the default recommendation because:

- **Zero runtime dependency.** `sh`, `curl`, and `tar` exist on every macOS
  machine, every Linux CI runner, and WSL. Every iOS developer is on macOS by
  definition, so coverage is total.
- **It matches mobile idiom.** `fvm`, `rustup`, `sdkman`, and Homebrew itself all
  install this way. Nobody blinks.
- **It works in CI.** No `npm install` step, no `node_modules`, no lockfile
  churn in a Gradle or Xcode project.
- **It is auditable.** One readable file. Teams that will not pipe curl to a
  shell can download, read, and run it, and the docs should say so explicitly
  rather than pretending the concern is unreasonable.

`install.sh` in this directory is a working implementation.

### Secondary: Homebrew

```bash
brew install mobile-blueprint
mobile-blueprint init
```

Worth doing early. It is the highest-trust install channel on macOS, it gives
free upgrades via `brew upgrade`, and a formula is about thirty lines. For iOS
developers this is the install path they will look for first.

### Keep npx for React Native

RN and Expo developers already live in Node. Removing `npx` for them would be a
downgrade. The npm package should be a thin wrapper that downloads and unpacks
the same tarball.

### Do not require a global install at all

The single most important property: **the workflow must be installable by
copying files.** A developer who clones the repo and runs
`./install.sh --from ./mobile` gets an identical result to the curl path. This
keeps the tool usable inside corporate networks that block script piping, and it
keeps the project honest about what it actually is.

## 5. What genuinely changes for mobile

Swapping Vercel for TestFlight is the trivial part. Five things are structurally
different, and they are where the real work is.

### 5.1 There is no dev server and no URL

The web loop's core verification move is "start a server, open a URL, screenshot
the DOM." Mobile has no equivalent. Evidence means: build, install onto a
simulator or emulator or physical device, drive the UI, capture a screenshot.

That is a real capability, not a rephrasing, so it gets its own skill: `device`.
It boots and selects targets, installs builds, drives the UI, and captures
screenshots so `check`, `implement`, and `autopilot` have one evidence path to
call.

### 5.2 Build times are minutes, not seconds

The web loop can afford "build and screenshot after every step." A clean iOS
archive or a cold Gradle build can take five to fifteen minutes. Repeating that
per step makes the workflow unusable.

The mobile packs therefore define a **tiered evidence policy**: the cheapest
credible evidence per step, escalating only when the claim demands it.

    tier 0  static analysis        seconds     analyze, lint, typecheck
    tier 1  unit and widget tests  seconds     logic and rendering
    tier 2  hot reload on a warm   seconds     visual and interaction claims
            simulator or emulator
    tier 3  full rebuild and       minutes     integration, plugins, native code
            install
    tier 4  release build on a     many min    signing, size, store rules,
            physical device                    performance, permissions

`check` picks the lowest tier that can honestly prove the claim, and says which
tier it used. This preserves the "evidence or it did not happen" rule while
keeping the loop fast.

### 5.3 A feature is not done on one platform

For Flutter and React Native, a single codebase produces two apps. A done-when
proven on an iOS simulator is not proven on Android, and the divergences are
routine: safe areas, back gesture, permissions, keyboard behavior, fonts, date
and number formatting, deep links.

The mobile `feature` spec therefore carries a **platform matrix**, and `check`
reports per platform. Verifying one and claiming both is the most likely way for
an agent to produce a false pass here.

### 5.4 Releases are irreversible and gated by other people

A bad Vercel deploy is rolled back in thirty seconds. A bad App Store release
is permanent: you cannot unpublish a build users already downloaded, you cannot
reuse a build number, and a fix takes a new build through a review queue that
may take a day.

So mobile `release` is a stricter gate than web `release`:

- Version and build number monotonicity is checked, because collisions are
  rejected at upload and silently waste a review cycle.
- Signing identity, provisioning profile, and keystore are verified as present
  and matching, never printed, never committed.
- Staged rollout is the default recommendation for Play, and phased release for
  App Store.
- The skill stops before upload. Always. Uploading to TestFlight or a Play track
  is an outward-facing, hard-to-reverse action and needs an explicit yes in the
  current chat, separately from the readiness work.

### 5.5 Prototyping is native, not HTML

The web `prototype` skill produces throwaway HTML and CSS and carries a theme
into `globals.css`. That does not port. The mobile equivalent builds throwaway
screens in the real UI framework (SwiftUI previews, Compose previews, a Flutter
widgetbook, or an RN screen behind a debug route) because the layout primitives
are the thing being decided and HTML will lie about them.

The durable output is a design token file in the platform's own format, not CSS
variables.

## 6. What does not change

Worth stating plainly, because it is most of the product: `feature`,
`implement`, `complete`, `audit`, `status`, `doctor`, `rollback`, `explore`,
`brief`, `debug`, `fix`, `discovery`, `overview`, `continuous`, and `autopilot`
need no mobile variant. The spec-driven loop, the review gates, the findings
ledger, and the history archive are platform-neutral by construction.

That is the argument for a stack pack rather than a fork: about eighty percent
of the value carries over untouched, and a fork would immediately start drifting
from upstream fixes to the other eighty percent.
