---
name: prototype
description: Build throwaway native screens to lock layout, navigation, and design tokens before feature implementation. Use for /prototype, screen mockups, look and feel, design tokens, or deciding navigation structure.
disable-model-invocation: true
---

# prototype - lock the look before you build

**Context reuse:** Reuse any required file already loaded in project instructions or the current session. Read it again only if absent, changed, or exact current bytes or line references are needed.

**First action:** Before project inspection, preflight, or any other tool call,
publish `running` to `blueprint/.state/run.json` using the dashboard activity
contract in `AGENTS.md`.

Where this sits in the workflow:

    plan  ->  /overview  ->  [prototype]  ->  /feature  ->  build
    (you      (project-      (lock the       (one spec    (real
     write)    overview.md)   look)           at a time)   code)

Prototyping is a pre-build step, not a feature. It is fast, visual, and
throwaway. Its one durable output is the design token set. Everything else gets
discarded.

## Build prototypes in the real UI framework

Do **not** mock mobile screens in HTML and CSS. It is faster to write and it
will lie to you about the only things worth prototyping: safe areas, navigation
transitions, scroll physics, keyboard behavior, touch target sizing, system font
scaling, and how a layout behaves on a small device. Those are the decisions
being made here, and the web renderer does not model any of them.

Build in the project's actual toolkit:

| Stack | Prototype in |
| --- | --- |
| Flutter | A throwaway route, or a widgetbook or storybook page |
| iOS | SwiftUI previews, or a debug-only screen behind a flag |
| Android | Compose previews, or a debug-only activity or route |
| React Native | A screen behind a debug route, or Storybook if present |

Keep prototypes out of the shipped build: a debug-only route, a preview, or a
directory excluded from release. Say which mechanism you used.

## Step 1 - read the plan

Read `blueprint/context/project-overview.md` and `blueprint/project-plan.md` for
the stated look, feel, and the screens the build plan implies. If the look has
not been described, ask before inventing one.

## Step 2 - decide what to prototype

Prototype the decisions that are expensive to change later:

- **Navigation structure.** Tabs, stack, drawer, or modal. This is the single
  most expensive thing to change after features are built on top of it, and it
  is the main reason to prototype at all.
- **The two or three screens that carry the product's identity.** Not every
  screen.
- **One dense screen and one sparse one**, because a design that only works on
  medium content is not a design.

Do not prototype every screen in the build plan. That is building the app
without the review gates.

## Step 3 - build the throwaway screens

Use placeholder data, hardcoded and obviously fake. No networking, no real state
management, no persistence. If a prototype needs a backend, it has stopped being
a prototype.

Check each prototype against the things only a device shows:

- Safe areas: notch, Dynamic Island, gesture bar, rounded corners
- Smallest supported device, not just the default simulator
- Largest system font size, which is where fixed-height layouts break
- Dark mode
- The keyboard open, on any screen with an input

Capture a screenshot of each, per platform where the project ships both.

## Step 4 - extract the design tokens

This is the durable output. Write the tokens in the platform's own format, not
as CSS variables:

| Stack | Token home |
| --- | --- |
| Flutter | A `ThemeData` and `ColorScheme` in `lib/theme/` |
| iOS | An asset catalog plus a `Theme` or constants type |
| Android | A Compose `Theme.kt` with color, type, and shape |
| React Native | A `theme.ts` exporting typed tokens |

Cover colors (light and dark), typography scale, spacing scale, corner radii, and
elevation. Derive them from what the prototype settled, not from a generic
palette.

Put tokens somewhere the real app will import them. That file survives; the
prototype screens do not.

## Step 5 - report

Show the screenshots, state which navigation structure was chosen and why, name
the token file, and say explicitly what is throwaway and what carries forward.

## Rules

- **Throwaway means throwaway.** Do not let a prototype screen quietly become the
  real implementation. Real screens are built through `/feature` and
  `/implement`, with the review gates.
- **Native, not HTML.** A web mockup of a mobile screen answers none of the
  questions that justify prototyping.
- **Tokens are the only durable output.** Everything else is deleted or left
  behind a debug flag.
- Do not commit, merge, push, or begin feature work from here.

## Formatting

Format the output to match the project's conventions in
`blueprint/context/ai-interaction.md`: concise, scannable markdown, with lists
for enumerations and tables for matrices rather than dense paragraphs.
