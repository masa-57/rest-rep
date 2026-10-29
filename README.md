# Rest & Rep

A clean, simple iPhone timer for the gym. Start a rest timer or an interval workout in one tap,
read it from across the room, and get alerts even when the phone is locked.

## Features

- **Quick rest:** 60s, 90s, 2m and 3m chips that start immediately.
- **Built-in workouts:** Tabata (20/10 × 8), EMOM 10 and 40 / 20 (× 8).
- **Custom timers:** a countdown, or intervals with work time, rest time and 1–50 rounds.
  The last custom timer is kept on Home so you can repeat it in one tap.
- **Big, glanceable timer:** full-screen phase colour (green work, blue rest, amber get ready),
  very large digits that never jitter, a progress ring and "Round 3 of 8".
- **Alerts:** ticks in the last 3 seconds, distinct tones and haptics for work, rest and finish.
  Your music keeps playing and dips during alerts.
- **Works when locked:** every phase change is also scheduled as a local notification.
- **Settings:** sound, haptics, keep screen awake, and dark, light or system appearance.

## Requirements

- Xcode 26 or later (the project was created with Xcode 27)
- iOS 17 or later, iPhone only, portrait
- Swift 6, SwiftUI, Apple frameworks only (no third-party dependencies)

## Getting started

```bash
git clone https://github.com/<your-account>/rest-rep.git
cd rest-rep
open rest-rep.xcodeproj
```

Pick an iPhone simulator and press **⌘R**.

### Running on your own iPhone

Signing settings live in a git-ignored file, so the repository never contains anyone's Team ID.

1. Copy the example config:
   ```bash
   cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
   ```
2. Edit `Config/Signing.local.xcconfig` and set `DEVELOPMENT_TEAM` (Xcode → Settings → Accounts)
   and `BUNDLE_ID_PREFIX` (e.g. `com.yourname`).
3. Turn on **Developer Mode** on the iPhone, connect it, select it in Xcode and press **⌘R**.

Avoid picking a team in Xcode's Signing & Capabilities tab. That writes your Team ID into
`project.pbxproj`, which is committed.

## Running the tests

In Xcode press **⌘U**, or from the command line:

```bash
xcodebuild test -project rest-rep.xcodeproj -scheme "Rest & Rep" \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

The tests use Swift Testing and cover the workout compiler, engine timing, pause and resume,
alert ordering and time formatting.

## How it works

Every timer is turned into a flat list of phases before it starts, and the engine only knows how
to play phases:

```
TimerConfig ──► WorkoutCompiler ──► [Phase] ──► TimerEngine ──► TimerView
```

- On start the engine calculates the absolute end time of every phase. Remaining time is always
  `phaseEnd − now`, so it stays accurate through backgrounding, pausing and locking.
- The Timer screen holds no timer state. It reads a snapshot from the engine every frame through
  `TimelineView`.
- Adding a new timer type means adding a case to `WorkoutCompiler`, with no changes to the engine
  or the Timer screen.

See [docs/SPEC-MVP.md](docs/SPEC-MVP.md) for the full MVP specification.

## Project structure

```
Rest & Rep/
├── RestRepApp.swift      App entry point
├── Models/               TimerConfig, Phase, presets, time formatting
├── Engine/               WorkoutCompiler, TimerEngine
├── Services/             Audio, haptics, notifications, settings, WorkoutSession
├── Views/                Home, Setup, Timer, Settings, shared components
├── DesignSystem/         Colours, typography, spacing
└── Resources/Sounds/     Alert sounds
RestRepTests/             Unit tests
Config/                   Signing configuration
docs/                     Specification
scripts/                  Sound generator
```

## Sounds

The alert sounds in `Rest & Rep/Resources/Sounds/` are simple synthesised tones made by
[scripts/generate_sounds.py](scripts/generate_sounds.py), and are covered by the same licence.
Regenerate them with:

```bash
python3 scripts/generate_sounds.py "Rest & Rep/Resources/Sounds"
```

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Released under the [MIT License](LICENSE).
