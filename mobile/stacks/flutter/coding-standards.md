# Coding Standards

> Your conventions. Edit these once to match your project. The defaults assume
> Flutter with sound null safety; change or trim anything that does not fit.
>
> Run `/onboard` after installing the Blueprint. It tunes this file to the real
> project, along with `AGENTS.md`, `platform.md`, and `.gitignore`.

## Dart

- Sound null safety on. Never use `!` to silence a nullable you have not checked.
- Prefer `final` for locals and fields. Use `const` wherever the value allows it.
- No `dynamic` unless decoding genuinely untyped data, and narrow it immediately.
- Model classes are immutable with `copyWith`, not mutable bags of fields.
- Prefer sealed classes or enums over string constants for closed sets of states.
- Follow `flutter analyze` with the project's lint set. A new lint warning is a
  build failure, not a style note.

## Widgets

- Prefer `StatelessWidget`. Reach for `StatefulWidget` only when the widget owns
  state that survives a rebuild.
- `const` constructors wherever possible. This is the single highest-value
  rebuild optimization in Flutter and it is free.
- Keep `build()` free of business logic, I/O, and allocation-heavy work. It runs
  often and unpredictably.
- Extract a widget rather than a `_buildSomething()` method returning a Widget.
  Extracted widgets get their own rebuild boundary; helper methods do not.
- Always `dispose()` controllers, focus nodes, animation controllers, and stream
  subscriptions. A missing dispose is a leak, and it is the most common review
  finding in Flutter code.
- Give `Key`s to widgets in lists that reorder, insert, or delete.

## State management

- Use whatever the project already uses. Do not introduce a second solution.
- If nothing is established, start with plain `setState` plus `InheritedWidget`
  or `ValueNotifier`, and only adopt Riverpod, Bloc, or Provider when a real
  requirement appears. Proportional engineering applies here more than anywhere:
  a state management library chosen on day one usually outlives its reasoning.
- Business logic lives outside widgets so it can be unit tested without a
  `WidgetTester`.

## File organization

- Features: `lib/features/<feature>/` holding `presentation/`, `domain/`, and
  `data/` only when the feature is large enough to need the split
- Shared widgets: `lib/shared/widgets/`
- Models: `lib/models/` or colocated in the feature
- Services and repositories: `lib/services/`
- Entry point: `lib/main.dart` stays thin

## Naming

- Files: `snake_case.dart`, matching the primary class where there is one
- Classes and types: `PascalCase`
- Members and locals: `camelCase`
- Private members: leading underscore
- Constants: `lowerCamelCase` (Dart convention, not `SCREAMING_SNAKE_CASE`)

## Platform channels and native code

- Wrap every `MethodChannel` call in a typed Dart method with explicit error
  handling. A `PlatformException` must never reach the widget tree raw.
- Every channel needs both an iOS and an Android implementation before the
  feature is done. A channel implemented on one side is a half-built feature,
  not a working one.
- Guard platform-only code with `Platform.isIOS` / `Platform.isAndroid`, or
  better, `defaultTargetPlatform`, so tests can override it.

## Async

- Never swallow errors in a `Future`. Handle them or let them propagate.
- Check `mounted` before calling `setState` after an `await`.
- Cancel `StreamSubscription`s in `dispose`.
- Prefer `FutureBuilder` and `StreamBuilder` over manual state juggling for
  simple one-shot loads.

## Testing

The blueprint installs no extra test runner. Flutter ships one. Testing is on by
default for this stack because `flutter test` exists in every project.

**The opt-in switch is one signal: a `test` command in the Commands section of
`AGENTS.md`.** For Flutter that command is present from install, so tests are a
gate for logic-bearing steps.

- **Unit tests** for pure logic: parsers, formatters, validators, mappers,
  repository logic with a faked data source. Fast, no `WidgetTester`.
- **Widget tests** for rendering and interaction on a single screen or component:
  what is on screen, what a tap does, what a failed load shows. These run
  headless in seconds and are the workhorse of this stack.
- **Golden tests** only for components whose exact visual output is the
  requirement. They are brittle across platforms and font versions, so keep them
  few and regenerate deliberately.
- **Integration tests** (`integration_test/`) for flows crossing screens,
  plugins, or real platform behavior. These need a device or simulator and take
  minutes, so they are a `/check` tier, not a per-step gate.
- **The gate:** a step that adds logic or a screen must ship a passing unit or
  widget test in the same reviewable diff. `flutter test` must be green before
  the step is approved and before `/complete` merges.
- Test files mirror source: `lib/features/cart/cart_total.dart` gets
  `test/features/cart/cart_total_test.dart`.
- An empty suite should fail, not pass.

## Performance

- Watch for jank in lists: use `ListView.builder`, not a `ListView` with a mapped
  children list, for anything unbounded.
- Do not rebuild whole subtrees to change one value. Push state down or use a
  targeted listenable.
- Decode and resize images to their display size. Full-resolution images in a
  list are the most common cause of memory pressure on low-end Android.
- Profile with `flutter run --profile` on a real device, never in debug mode.
  Debug builds are not representative and a performance claim from a debug build
  is not evidence.

## Code Quality

- No commented-out code unless specified
- No unused imports or variables
- Keep functions and `build()` methods short. Extract rather than nest.

## Comments

Write code that explains itself; comment only what the code cannot say.
Over-commenting is a common AI tell, so resist it.

- Comment the **why**, not the **what**. Delete any comment that restates code.
- No banner blocks, section dividers, or step-by-step narration.
- A comment earns its place when it captures a non-obvious decision, a gotcha or
  platform workaround, or a link to an issue. Platform quirks genuinely deserve
  comments; widget structure does not.
- Keep doc comments minimal: one line on an exported type or function.

## Writing

- No em dashes (U+2014) in generated content: docs, comments, commit messages,
  READMEs, specs. They read as AI-generated.
- Use a hyphen for `term - description` separators; rephrase prose with commas,
  parentheses, or a colon. Avoid en dashes and the ellipsis character too.
