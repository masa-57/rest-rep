# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in this repository.

## Project

Rest & Rep is an iPhone gym timer: SwiftUI, Swift 6, iOS 17+, iPhone only, portrait only,
Apple frameworks only. The product spec is [docs/SPEC-MVP.md](docs/SPEC-MVP.md). Read it before
adding features, and keep anything listed under "Out of scope" out unless asked.

## Build and test

`xcode-select` may point at the Command Line Tools, so prefix commands with `DEVELOPER_DIR`:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project rest-rep.xcodeproj -scheme "Rest & Rep" \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -project rest-rep.xcodeproj -scheme "Rest & Rep" \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Run the tests after any change to `Models/` or `Engine/`.

## Architecture rules

- **Phases are the only contract.** `WorkoutCompiler` turns a `TimerConfig` into `[Phase]`;
  `TimerEngine` plays phases. A new timer type is a new `TimerType` case plus a compiler case.
  It must not require changes to `TimerEngine` or `TimerView` (acceptance criterion A6).
- **Never count down by ticking.** The engine stores absolute phase end dates. Remaining time is
  `phaseEnd − now`; pause and resume shift the end dates.
- **The engine is deterministic.** Every method takes an explicit `Date`, so tests never sleep.
  Keep it that way.
- **Views hold no timer state.** `TimerView` reads `engine.snapshot(at:)` inside a `TimelineView`.
- **`WorkoutSession`** wires the engine to `AudioService`, `HapticService` and
  `NotificationService`, and handles scene-phase changes. In the background it only resyncs,
  because notifications deliver the alerts there.
- Settings and the last-used custom timer live in `UserDefaults` via the keys in `AppSettings`.

## Conventions

- Targets default to `@MainActor` isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
- Use the design tokens in `DesignSystem/` (`Palette`, `Typography`, `Spacing`) instead of
  literal colours, fonts and sizes.
- Phase is always shown as a text label as well as a colour. Controls need VoiceOver labels.
  Respect Reduce Motion.
- British spelling in type names (`Colours`, `colour`) matches the existing code.
- Tests use Swift Testing (`import Testing`, `@Test`, `#expect`). The app module is `RestRep`.

## Project file

- Source folders are file-system synchronized groups. New files under `Rest & Rep/` or
  `RestRepTests/` are picked up automatically, so don't add them to `project.pbxproj`.
- Signing comes from `Config/Signing.xcconfig`, which includes the git-ignored
  `Config/Signing.local.xcconfig`. Never commit a `DEVELOPMENT_TEAM` value or a personal bundle
  ID in `project.pbxproj`.
