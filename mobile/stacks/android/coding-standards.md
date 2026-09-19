# Coding Standards

> Your conventions. Edit these once to match your project. The defaults assume
> Kotlin with Jetpack Compose; change or trim anything that does not fit. A View
> and XML project should replace the Compose section rather than carry both.
>
> Run `/onboard` after installing the Blueprint. It tunes this file to the real
> project, along with `AGENTS.md`, `platform.md`, and `.gitignore`.

## Kotlin

- Prefer `val` over `var`. Prefer immutable collections.
- Use nullable types deliberately. No `!!` in shipped code: use `?.`, `?:`,
  `requireNotNull` with a message, or restructure. `!!` is a crash with extra
  steps.
- Data classes for models. Sealed classes or interfaces for closed sets of state,
  never string or int constants.
- Extension functions for utility behavior rather than static helper objects.
- Use `Result` or a typed sealed error for recoverable failures, not exceptions
  as control flow.
- Explicit visibility at module boundaries. `internal` is underused and usually
  correct for anything not part of a module's API.

## Jetpack Compose

- Composables are small and single-purpose. A composable longer than a screen is
  a refactor.
- **State hoisting:** composables take state and emit events. A composable that
  owns state its caller needs is the most common Compose design error.
- Never perform I/O, allocation-heavy work, or side effects directly in a
  composable body. It recomposes often and unpredictably. Use `LaunchedEffect`,
  `rememberCoroutineScope`, or move the work to the view model.
- `remember` for values that survive recomposition, `rememberSaveable` for values
  that must survive configuration change and process death. Confusing the two
  produces bugs that only appear on rotation or low-memory kills, which is to say
  bugs that only appear for users.
- Provide stable `key`s in `LazyColumn` and `LazyRow` items.
- Prefer immutable and stable parameter types so Compose can skip recomposition.
  An unstable `List` parameter silently defeats skipping.
- Keep `Modifier` chains ordered deliberately; order changes behavior.

## Architecture

- Unidirectional data flow: view model exposes state, UI emits events.
- View models expose `StateFlow` and survive configuration changes. Never hold a
  `Context`, `Activity`, `View`, or composable reference in one.
- Repository layer between view models and data sources.
- Use Hilt or the DI the project already uses. Do not introduce a second one.
- Group by feature: `feature/cart/` holding its UI, view model, and tests.

## Lifecycle and process death

Android will kill your process and restore it later. Design for it:

- Any state the user would be upset to lose goes in `SavedStateHandle` or
  persistent storage, not in a plain view-model field.
- Collect flows with `repeatOnLifecycle(Lifecycle.State.STARTED)` or
  `collectAsStateWithLifecycle`, so collection stops in the background.
- Configuration changes (rotation, dark mode, font size, locale, window resize)
  recreate activities by default. Verify behavior across them.
- Cancel coroutines with the right scope. `viewModelScope` and
  `lifecycleScope` exist so you never need a bare `GlobalScope`. `GlobalScope`
  in application code is a defect.

## Permissions and background work

- Request permissions at the point of use with a rationale, never at startup in a
  block.
- Handle permanent denial. "Don't ask again" is a state your UI must have an
  answer for.
- Background work goes through `WorkManager`, not a bare service or thread.
  Battery optimization and background restrictions will kill anything else.
- Respect scoped storage. Do not write to arbitrary external paths.

## File organization

- Features: `com.example.app.feature.<name>/`
- Shared: `com.example.app.core/`
- One primary class per file, named for the class
- Keep `Application` and `MainActivity` thin

## Naming

- Classes and composables: `PascalCase` (composables are `PascalCase` by
  convention despite being functions)
- Functions, properties, locals: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE` in a `companion object` or top level
- Resources: `snake_case`, prefixed by type (`ic_cart`, `bg_rounded`)

## Accessibility

Not optional and not a later feature. Every interactive element needs a content
description or a semantics label. TalkBack must reach and describe every control,
touch targets stay at or above 48dp, and layouts must survive the largest font
scale and display size. Verify with TalkBack and the Accessibility Scanner, not
by reading the code.

## Testing

Gradle ships test tasks, so testing is on by default for this stack.

**The opt-in switch is one signal: a `test` command in the Commands section of
`AGENTS.md`.** For Android that command is present from install, so tests are a
gate for logic-bearing steps.

- **Unit tests** (JUnit, `src/test/`) for pure logic and view models: parsing,
  formatting, validation, state transitions. Fast, no device, run on the JVM.
- **View-model tests** are the highest-value tests in this stack, because they
  cover behavior without paying device cost. Use `Turbine` or equivalent for
  flow assertions and a test dispatcher for coroutines.
- **Compose UI tests** (`createComposeRule`) for single-screen rendering and
  interaction. These run on a device but are far faster than full instrumented
  flows.
- **Instrumented tests** (`src/androidTest/`) for flows crossing screens or
  touching real platform behavior. Slow, need a device, and belong in `/check`
  rather than the per-step gate.
- **The gate:** a step adding logic must ship a passing unit test in the same
  diff. `testDebugUnitTest` must be green before the step is approved and before
  `/complete` merges.
- An empty suite should fail, not pass.

## Code Quality

- No commented-out code unless specified
- No unused imports, variables, or resources
- Keep functions short; extract rather than nest
- Treat lint warnings as defects. Baseline files hide debt, so add to one only
  deliberately and never silently.

## Comments

Write code that explains itself; comment only what the code cannot say.
Over-commenting is a common AI tell, so resist it.

- Comment the **why**, not the **what**. Delete any comment that restates code.
- No banner blocks, section dividers, or step-by-step narration.
- A comment earns its place for a non-obvious decision, an OEM or API-level
  workaround, or a link to an issue. Android fragmentation quirks genuinely
  deserve comments; Compose structure does not.
- Keep doc comments minimal: one line on a public type or function.

## Writing

- No em dashes (U+2014) in generated content: docs, comments, commit messages,
  READMEs, specs. They read as AI-generated.
- Use a hyphen for `term - description` separators; rephrase prose with commas,
  parentheses, or a colon. Avoid en dashes and the ellipsis character too.
