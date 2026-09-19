---
name: check
description: Prove the current spec against the app running on a real simulator, emulator, or device, per platform, or use check guide for a read-only manual test guide. Use for /check, verify the feature, does it work on Android, or acceptance before complete.
disable-model-invocation: true
---

# check - prove it on a device

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`. Select the mode below before any activity call:
`check guide` never writes activity state.

Where this sits in the workflow:

    /implement  ->  [check]  ->  /complete
    (built a       (run it on      (only once the
     step or        real targets,   done-whens are
     the feature)   prove each      proven on every
                    done-when)      target platform)

`/implement` builds and does a quick inline check. `/check` is the deeper gate
for when a done-when needs the **real app on a real target**: a tap that opens a
sheet, a permission prompt, a deep link, state surviving rotation.

The point is evidence. A green build proves the code compiles; `/check` proves
the thing the spec promised actually happens, on every platform the project
ships. It changes no source and commits nothing.

## Modes

- `/check` or `/check <thing>`: run the app and verify. This document.
- `/check guide`: generate a read-only manual test guide, where to go, what to
  tap, what to expect, per platform. Performs no verification, records no
  acceptance, writes no activity state. Use it for claims needing hardware you do
  not have.

## Step 1 - build the checklist

Read `blueprint/config.json` first. A missing file means built-in defaults apply.
If the file exists but is invalid, stop and point the user to `/doctor`.
Configuration never grants permission to start a build, boot a device, or take
any other action the project instructions or user have not authorized. The
quality-gate config controls automatic invocation only; an explicit `/check`
always runs.

Read `blueprint/context/platform.md` for this project's evidence ladder and
platform matrix, and `blueprint/context/current-feature.md` for the spec.

Pull the observable done-when criteria from the build steps and any acceptance
notes. Turn them into concrete claims, each a specific observable behavior, not
"it works". If the user named one thing, scope to that.

**Then cross them with the target platforms.** For Flutter and React Native that
is iOS and Android. For native iOS or Android it is the device and OS-version
range the project supports. The checklist is a grid, not a list.

If there is no current feature spec, ask what to verify rather than guessing.

## Step 2 - pick the tier per claim

For each claim, choose the **cheapest tier in `platform.md` that can honestly
prove it**, then run that tier. Builds here cost minutes, so verifying
everything at the top tier makes the workflow unusable, and verifying everything
at the bottom tier proves nothing.

Escalate when the claim demands it. Anything touching native code, plugins,
permissions, notifications, deep links, background behavior, process death, or
startup needs a full rebuild or higher, because hot reload does not re-run
native initialization and will show stale behavior.

With `verification.uiEvidence: "required"`, every UI claim needs direct device
evidence: a screenshot plus the relevant log check. If that path is unavailable,
mark the claim unverifiable rather than passing it from build output. With
`when-available`, use the strongest available evidence and report the gap.

## Step 3 - get it running

Use `/device` rather than reinventing target handling. Prefer a warm target.
Reuse a running app over a fresh install where the change allows it.

If a platform is unavailable (no macOS so no iOS simulator, no emulator
installed, no physical device for a hardware claim), record it as unverifiable
for that platform **now**, and continue with the platforms you do have. Do not
silently narrow the matrix.

## Step 4 - exercise each claim

Drive the app for real on each target: tap, type, scroll, submit, rotate,
background and foreground it. Do not assert from the code what the running app
would do.

- Capture a **screenshot** for every visual claim, named for the claim and target.
- **Watch the log the entire time.** Exceptions, overflow stripes, skipped
  frames, main-thread violations, constraint conflicts, yellow or red boxes, and
  caught-and-ignored errors all mean **not a pass**, even when the screen looks
  correct.
- For state claims, verify across configuration change and process death, not
  just the happy path. On Android this means rotation and
  `adb shell am kill <package>`; these find the bug class users hit most.

## Step 5 - report

One line per claim per platform, with the tier that produced it:

    Done-when                         iOS              Android
    Cart badge updates on add         pass (t2)        pass (t2)
    Back gesture returns to list      skip: n/a        fail (t3): exits app
    State survives process death      pass (t3)        fail (t3): cart cleared
    Biometric unlock                  skip: no device  skip: no device

Then the bottom line: are all done-whens proven **on every target platform**, or
not yet.

- All proven on all platforms -> update only the `**Status:**` line in
  `blueprint/context/current-feature.md` to `verified`, then say it is ready for
  `/complete`.
- Anything failed -> update only that status line to `verification failed`, then
  hand back to `/implement` naming what to fix and on which platform. Do not fix
  it here.
- Anything unverifiable, **including a platform you could not reach** -> update
  only that status line to `verification incomplete`, then say why. Never report
  it as a pass.

The status-line update is generated workflow state, not a product-source edit.
Do not change the spec, checkboxes, findings, or product files from `/check`.

## Rules

- **One platform is not both.** For a cross-platform project, a done-when proven
  on iOS and blank on Android is not proven. Reporting it as a pass is the most
  likely false result this skill can produce. Partial is the honest verdict.
- **Name the tier.** A pass without a tier hides how much it is worth.
- **Observe product behavior, do not repair it.** `/check` changes only the
  status line. Fixing is `/implement`'s job.
- **Evidence or it did not happen.** Every pass is backed by something observed:
  a screenshot, a log, an output. No assumed passes from reading code.
- **Debug is not release.** A performance, size, or shipping-behavior claim needs
  a release build on real hardware. Saying otherwise reports a number you know to
  be wrong.
- **Honest over green.** "Could not verify" and "failed" are valid, useful
  results. Faking a pass defeats the entire gate.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
