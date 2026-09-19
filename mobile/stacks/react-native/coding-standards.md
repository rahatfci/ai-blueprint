# Coding Standards

> Your conventions. Edit these once to match your project. The defaults assume
> React Native with TypeScript; change or trim anything that does not fit.
>
> Run `/onboard` after installing the Blueprint. It tunes this file to the real
> project, along with `AGENTS.md`, `platform.md`, and `.gitignore`.

## TypeScript

- Strict mode enabled
- No `any` types: use proper typing or `unknown` and narrow
- Define interfaces for props, API responses, and navigation params
- Type the navigation stack. Untyped `navigation.navigate` calls are the most
  common runtime error source in this stack.
- Use type inference where obvious, explicit types where helpful

## React and components

- Function components only. Hooks for state and effects.
- One job per component. Extract reusable logic into custom hooks.
- Memoize deliberately: `useMemo` and `useCallback` earn their place when passing
  values to memoized children or expensive computations, not everywhere.
- Every `useEffect` needs a correct dependency array and a cleanup function when
  it subscribes to anything.
- Keep lists virtualized: `FlatList` or `FlashList`, never `.map()` over an
  unbounded array inside a `ScrollView`. This is the top cause of RN performance
  complaints.
- Provide stable `keyExtractor` and, for `FlatList`, `getItemLayout` when item
  height is known.

## React Native specifics

- **Not every web idiom ports.** There is no DOM, no CSS cascade, no `z-index`
  the way you expect, and `%` units behave differently. Flexbox defaults differ
  from the web: `flexDirection` is `column`, not `row`.
- `Platform.select` and `Platform.OS` for divergence, and `.ios.tsx` /
  `.android.tsx` files when the divergence is a whole component.
- `SafeAreaView` or safe area insets on every screen. Notches and gesture bars
  are not optional to handle.
- Use `Pressable` over the older touchable components in new code.
- Shadows need both `shadow*` (iOS) and `elevation` (Android) to appear on both.
- Text must be inside a `<Text>`. Style inheritance does not work like CSS.

## Native modules and dependencies

- Adding a dependency with native code is a structural change, not a normal
  install. It requires a rebuild, may need pod install, can break the Expo
  managed workflow, and can conflict with another module's native version.
- Prefer a JS-only solution when one exists and is adequate.
- Check New Architecture (Fabric and TurboModules) compatibility before adding a
  native dependency. An unmaintained module is a future migration blocker.
- After adding native code: `cd ios && pod install`, then a full rebuild. Metro
  reload is not enough and will show you stale behavior.

## State and data

- Local state first. Reach for a global store only when state is genuinely shared
  across distant screens.
- Use whatever the project already uses. Do not introduce a second store.
- Server state belongs in a data-fetching library (React Query or equivalent),
  not hand-rolled in `useEffect`.
- Validate API responses at the boundary. A type assertion is not validation.

## File organization

- Features: `src/features/<feature>/` with its screens, components, and hooks
- Shared components: `src/components/`
- Navigation: `src/navigation/`
- Hooks: `src/hooks/`
- API and services: `src/services/`
- Types: colocated, or `src/types/` when shared

## Naming

- Components: `PascalCase` (`CartBadge.tsx`)
- Hooks: `useCamelCase`
- Functions and variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Types and interfaces: `PascalCase`, no `I` prefix

## Accessibility

Not optional and not a later feature. Every interactive element needs
`accessibilityLabel` and an appropriate `accessibilityRole`. VoiceOver and
TalkBack must both reach and describe every control, and layouts must survive the
largest system font scale. Verify on both platforms, because the two screen
readers behave differently.

## Testing

Jest ships with React Native, so testing is on by default for this stack.

**The opt-in switch is one signal: a `test` command in the Commands section of
`AGENTS.md`.** For React Native that command is present from install, so tests
are a gate for logic-bearing steps.

- **Unit tests** for pure logic: parsers, formatters, validators, reducers,
  hooks with `@testing-library/react-hooks`. Fast, no device.
- **Component tests** with `@testing-library/react-native` for rendering and
  interaction on one component or screen. These run in Jest without a device and
  are the workhorse of this stack.
- **E2E tests** with Maestro or Detox for flows across screens. Slow, need a
  device, and belong in `/check` rather than the per-step gate. Prefer Maestro
  for new setups: the YAML flows are far cheaper to maintain than Detox suites.
- **The gate:** a step adding logic must ship a passing unit or component test in
  the same diff. `npm test` must be green before the step is approved and before
  `/complete` merges.
- Mock native modules at the module boundary, not by reaching into internals.
- An empty suite should fail, not pass.
- Test files live next to source: `CartBadge.test.tsx`.

## Code Quality

- No commented-out code unless specified
- No unused imports or variables
- Keep functions and components short; extract rather than nest
- Fix TypeScript errors rather than suppressing them. A `@ts-expect-error`
  needs a comment saying why and what would remove it.

## Comments

Write code that explains itself; comment only what the code cannot say.
Over-commenting is a common AI tell, so resist it.

- Comment the **why**, not the **what**. Delete any comment that restates code.
- No banner blocks, section dividers, or step-by-step narration.
- A comment earns its place for a non-obvious decision, a platform workaround, or
  a link to an issue. RN platform divergences genuinely deserve comments;
  component structure does not.
- Keep doc comments minimal: one line on an exported type or function.

## Writing

- No em dashes (U+2014) in generated content: docs, comments, commit messages,
  READMEs, specs. They read as AI-generated.
- Use a hyphen for `term - description` separators; rephrase prose with commas,
  parentheses, or a colon. Avoid en dashes and the ellipsis character too.
