# Contributing to Rest & Rep

Thanks for helping out. The app aims to do a few things very well, so please open an issue to
discuss larger features before writing code.

## Setup

1. Fork and clone the repository, then open `rest-rep.xcodeproj` in Xcode.
2. To run on a device, set up `Config/Signing.local.xcconfig` as described in the
   [README](README.md#running-on-your-own-iphone).

## Pull requests

- Keep changes focused; one feature or fix per pull request.
- Follow the architecture rules in [CLAUDE.md](CLAUDE.md). In short: new timer types go through
  `WorkoutCompiler`, and the engine and Timer screen stay type-agnostic.
- Add or update tests for engine and compiler changes, and make sure `⌘U` passes.
- Don't commit your Team ID, bundle ID or anything under `xcuserdata/`.
- Check new UI with VoiceOver, Dynamic Type, light and dark mode, and Reduce Motion.

## Reporting bugs

Include your iPhone model, iOS version, steps to reproduce, and what you expected to happen.
