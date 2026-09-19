# Coding Standards

> Your conventions. Edit these once to match your project. The defaults assume
> Swift with SwiftUI; change or trim anything that does not fit. A UIKit project
> should replace the SwiftUI section rather than carry both.
>
> Run `/onboard` after installing the Blueprint. It tunes this file to the real
> project, along with `AGENTS.md`, `platform.md`, and `.gitignore`.

## Swift

- Prefer `let` over `var`. Prefer `struct` over `class` unless reference
  semantics or Objective-C interop is genuinely required.
- No force unwrapping (`!`) and no `try!` in shipped code. Use `guard let`,
  `if let`, or a typed error. A force unwrap is a crash with extra steps.
- No implicitly unwrapped optionals outside `@IBOutlet`.
- Use `some` and `any` deliberately; do not reach for type erasure by reflex.
- Mark types `final` unless they are designed for subclassing.
- Errors are typed enums conforming to `Error`, not strings.
- Access control is explicit at module boundaries: `internal` by default,
  `private` for implementation detail, `public` only when another module needs it.

## SwiftUI

- Views are small and composable. A `body` longer than a screen is a refactor.
- Choose the right property wrapper deliberately: `@State` for view-owned value
  state, `@Binding` for delegated state, `@Observable` or `@StateObject` for
  owned reference models, `@ObservedObject` only for injected ones. Using
  `@ObservedObject` where `@StateObject` belongs recreates the model on every
  parent rebuild, and it is the most common SwiftUI bug in review.
- No business logic, I/O, or expensive work in `body`. It is recomputed often.
- Extract subviews rather than writing `@ViewBuilder` helper functions, so each
  gets its own identity and update boundary.
- Give explicit `id`s in `ForEach` over anything that reorders or mutates.
- Use `.task` rather than `.onAppear` for async work: it is cancelled on
  disappear automatically.

## Concurrency

- Use structured concurrency (`async`/`await`, `TaskGroup`). Do not introduce a
  completion-handler API in new code.
- UI updates belong on `@MainActor`. Annotate the type or the method rather than
  hopping manually.
- Prefer actors over locks for shared mutable state.
- Every `Task` that outlives a view must be cancellable and cancelled.
- Build with strict concurrency checking on. Data race warnings are defects.

## Architecture and file organization

- Group by feature, not by type: `Features/Cart/` holding its views, model, and
  tests, rather than a global `Views/` and `Models/`.
- Shared code in `Core/` or `Shared/`.
- One primary type per file, named for the type.
- Keep `AppDelegate` and `SceneDelegate` thin.
- Networking goes through one client type, not `URLSession` calls scattered
  across views.

## Naming

- Types: `PascalCase`. Members: `camelCase`.
- Follow the Swift API Design Guidelines: read call sites as sentences, omit
  needless words, name booleans as assertions (`isEnabled`, `hasChanges`).
- No Hungarian notation, no `m_` prefixes, no type names in property names.

## Resources and assets

- Strings go through a localization catalog, never hardcoded in a view, even in a
  single-locale app. Retrofitting localization is far more expensive than doing
  it inline.
- Colors and images come from asset catalogs so dark mode and scale variants work.
- Support Dynamic Type. Fixed font sizes break accessibility and are a rejection
  risk under accessibility review.

## Accessibility

Not optional and not a later feature. Every interactive element needs a label.
VoiceOver must be able to reach and describe every control, and the layout must
survive the largest Dynamic Type setting. Verify with the Accessibility
Inspector, not by reading the code.

## Testing

Swift ships a test runner, so testing is on by default for this stack.

**The opt-in switch is one signal: a `test` command in the Commands section of
`AGENTS.md`.** For iOS that command is present from install, so tests are a gate
for logic-bearing steps.

- **Unit tests** (Swift Testing or XCTest) for pure logic: parsing, formatting,
  validation, view-model state transitions. Fast, no simulator UI.
- **View-model tests** are the highest-value tests in this stack, because they
  cover behavior without paying simulator cost. Keep logic out of views so this
  stays possible.
- **Snapshot tests** only where exact visual output is the requirement. They are
  brittle across OS versions and devices; pin the simulator if you use them.
- **UI tests** (XCUITest) for flows across screens. They are slow and flaky by
  nature, so keep them few and reserve them for critical paths. They are a
  `/check` tier, not a per-step gate.
- **The gate:** a step adding logic must ship a passing test in the same diff.
  The test command must be green before the step is approved and before
  `/complete` merges.
- An empty suite should fail, not pass.

## Code Quality

- No commented-out code unless specified
- No unused imports, variables, or dead `@IBOutlet`s
- Keep functions short; extract rather than nest
- Fix compiler warnings. A warning left in place trains everyone to ignore them.

## Comments

Write code that explains itself; comment only what the code cannot say.
Over-commenting is a common AI tell, so resist it.

- Comment the **why**, not the **what**. Delete any comment that restates code.
- No banner blocks, `// MARK:` spam, or step-by-step narration. A few `// MARK:`
  dividers in a large file are useful; one every five lines is noise.
- A comment earns its place for a non-obvious decision, an OS-version workaround,
  a radar or issue link, or a reason a value is what it is. iOS version quirks
  genuinely deserve comments.
- Keep doc comments minimal: one line on a public type or function.

## Writing

- No em dashes (U+2014) in generated content: docs, comments, commit messages,
  READMEs, specs. They read as AI-generated.
- Use a hyphen for `term - description` separators; rephrase prose with commas,
  parentheses, or a colon. Avoid en dashes and the ellipsis character too.
