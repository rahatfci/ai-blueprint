# Check guide - manual test instructions

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

Guide mode is read-only. It generates instructions for a human to follow. It
runs no build, boots no device, verifies nothing, records no acceptance, and
writes no activity state.

    /implement  ->  [check guide]  ->  human tries it  ->  /check or /complete
    (built it)      (what to tap,      (on their own      (recorded
                     what to expect)    device)            acceptance)

Guide mode exists because mobile has claims an agent genuinely cannot verify:
biometrics, camera, push notifications on a real device, cellular behavior, OEM
background restrictions, a paid in-app purchase, or anything needing hardware
this machine does not have. Writing a precise manual guide is the honest answer
to those, and it is more useful than a fabricated pass.

## Input

Optional: a specific flow to write the guide for. With no argument, cover the
current feature's done-whens from `blueprint/context/current-feature.md`.

## Step 1 - read

Read `blueprint/context/current-feature.md` and `blueprint/context/platform.md`.
Pull out the observable done-whens, the target platforms, and any claim the
evidence ladder marks as needing hardware.

Do not dump the spec. Extract the screens, taps, inputs, and expected results.

## Step 2 - write the guide

Structure it so someone holding a phone can follow it without reading the spec.
Write one section per platform when the project ships more than one, because the
steps genuinely differ.

**Setup** - what they need before starting:

- Which build: debug, release, TestFlight, or internal track
- Which device or OS version matters for this claim, and why
- Preconditions: signed in as what, seeded with what data, permissions in what
  state, network on or off, battery saver on or off

**Steps** - numbered, one action each:

1. **Go** - which screen, and how to reach it from a cold launch
2. **Do** - the exact tap, swipe, input, or gesture
3. **Expect** - what should be on screen, precisely enough to be wrong

**Also check** - the mobile-specific states people forget:

- Rotate the device, if the screen supports it
- Background the app, wait, and return
- Kill the app and reopen it, confirming state that should survive did
- Deny the permission, not just grant it
- Largest system font size
- Dark mode
- Offline or poor network, when the feature touches the network

**Gaps** - state plainly what the guide cannot cover, what hardware it needs,
and which done-whens remain unproven until someone runs it.

## Step 3 - hand off

End by saying how to record the outcome: run `/check` for the claims that can be
automated, and report the manual results back so the feature's status reflects
what was actually observed.

## Rules

- **Read-only.** No build, no install, no device boot, no file change other than
  producing the guide text, no status update, no activity state.
- **Never imply verification happened.** Guide mode produces instructions, not
  evidence. Do not write it in a way that reads like a result.
- **Be specific.** "Check the cart works" is useless. "Tap Add on the second
  item, expect the badge to read 2 within a second" is a test.
- **Name the platform.** Steps that differ between iOS and Android are written
  separately, not merged into one ambiguous instruction.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with
numbered steps and short lines someone can follow on a second screen.
