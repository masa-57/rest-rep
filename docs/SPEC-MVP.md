# Rest & Rep: MVP Specification

Version 1.0 (MVP) | Platform: iPhone | Future scope: a later `SPEC.md`

---

## 1. Purpose

A clean, simple iPhone timer for the gym. The MVP does a few things very well and is built on an engine that later versions can extend without a rewrite.

### MVP goals

| # | Goal |
|---|---|
| G1 | Start a timer in one or two taps from launch |
| G2 | Readable at a glance from across the room |
| G3 | Alerts still fire when the phone is locked |
| G4 | No learning curve: one obvious action per screen |

### Out of scope for the MVP

AMRAP, Stopwatch, Custom/mixed workouts, multiple sets, cool-down, voice cues, Live Activity, Apple Watch, history, presets management (rename, reorder, duplicate). All are covered in `SPEC.md` for later versions.

---

## 2. Workout types

Only **two timer types** in the engine. The familiar formats are just presets of these two, which keeps the UI simple and the code small.

| Type | What it does | Settings |
|---|---|---|
| **Countdown** | One countdown, e.g. rest between sets | Duration |
| **Intervals** | Repeating work and rest | Work time, Rest time, Rounds |

### Built-in presets

| Preset | Type | Values |
|---|---|---|
| Rest 60s / 90s / 2m / 3m | Countdown | Quick chips on Home |
| Tabata | Intervals | 20s work, 10s rest, 8 rounds |
| EMOM 10 | Intervals | 60s work, 0s rest, 10 rounds |
| 40 / 20 | Intervals | 40s work, 20s rest, 8 rounds |

Every Intervals workout starts with a fixed **10-second get-ready** phase. Rest set to 0 is skipped.

---

## 3. Screens

Three screens, plus a small settings sheet.

```
Home ──► Setup (sheet) ──► Timer
  └──── tap preset or rest chip ──► Timer
```

### 3.1 Home

| Element | Behaviour |
|---|---|
| Quick rest | Row of large chips: 60s, 90s, 2m, 3m. One tap starts immediately |
| Workouts | Three large cards: Tabata, EMOM 10, 40 / 20. Tap to start immediately |
| Custom timer | Two buttons: **New countdown** and **New intervals**, each opening Setup |
| Last used | The most recent custom timer appears as a fourth card, so it can be repeated in one tap |
| Settings | Gear icon, top right |

### 3.2 Setup (bottom sheet)

| Element | Behaviour |
|---|---|
| Countdown | One time picker (minutes and seconds) |
| Intervals | Work time picker, Rest time picker, Rounds stepper (1 to 50) |
| Summary | One line: "Total 4:00" |
| Action | Full-width **Start** button |

No saving, naming or editing in the MVP. The last-used setup is remembered automatically.

### 3.3 Timer

| Element | Behaviour |
|---|---|
| Background | Full-screen phase colour: green for Work, blue for Rest, amber for Get ready |
| Countdown | Very large monospaced digits, centred |
| Phase label | WORK, REST or GET READY above the digits |
| Progress | Thin ring around the digits |
| Context | "Round 3 of 8" below the digits (Intervals only) |
| Controls | Large Pause/Resume button; smaller End button (with confirmation) |
| Screen | Stays awake while running |
| Finish | Digits replaced by "Done", completion sound and haptic, then a **Done** button back to Home and a **Repeat** button |

### 3.4 Settings (sheet)

| Setting | Default |
|---|---|
| Sound | On |
| Haptics | On |
| Keep screen awake | On |

---

## 4. Visual design

| Principle | Detail |
|---|---|
| One primary action per screen | Start, or Pause/Resume |
| Big targets | Timer controls at least 72pt; chips and cards at least 60pt tall |
| Calm and native | System font, SF Symbols, rounded corners (20pt cards), generous spacing |
| Numerals | SF Pro Rounded with monospaced digits, so the countdown never jitters |
| Theme | Dark by default, supports light mode |
| Colour plus text | Phase is always shown as a label as well as a colour |
| Motion | 0.4s colour cross-fade on phase change; none if Reduce Motion is on |
| Accessibility | VoiceOver labels on all controls; Dynamic Type for all labels |

---

## 5. Alerts

| Event | Sound | Haptic |
|---|---|---|
| Last 3 seconds of a phase | Short tick each second | Light tap |
| Work starts | High tone | Heavy |
| Rest starts | Low tone | Medium |
| Finished | Three-note sound | Success pattern |

Audio session: `.playback` with `.mixWithOthers` and `.duckOthers`, so the user's music keeps playing and dips during alerts.

---

## 6. Engine (designed to extend)

This is the part that must be built properly in the MVP, because every future mode reuses it.

### Core idea

Every timer type is converted into a **flat list of phases** before it starts. The engine only knows how to play phases. Adding a new mode later means adding a new converter, not changing the engine or the Timer screen.

```
TimerConfig ──► WorkoutCompiler ──► [Phase] ──► TimerEngine ──► Timer screen
```

### Timing rules

| # | Rule |
|---|---|
| T1 | On start, calculate the absolute end time of every phase |
| T2 | Remaining time is always `phaseEnd - now`; never count down by ticking |
| T3 | Pause stores the pause moment; resume shifts all remaining end times by the paused duration |
| T4 | The UI refreshes via `TimelineView` and reads from the engine; it holds no timer state |
| T5 | On returning to the app, the engine works out the current phase from the clock |
| T6 | On start (and resume), schedule one local notification per remaining phase change, so alerts fire when locked |

### Data model

```swift
enum TimerType: String, Codable { case countdown, intervals }
// Future: stopwatch, amrap, custom

enum PhaseKind: String, Codable { case getReady, work, rest }
// Future: setRest, coolDown, countUp

struct Phase: Codable, Identifiable {
    let id: UUID
    let kind: PhaseKind
    let duration: TimeInterval
    let round: Int?
}

struct TimerConfig: Codable, Equatable {
    var type: TimerType
    var duration: TimeInterval   // countdown
    var work: TimeInterval       // intervals
    var rest: TimeInterval       // intervals
    var rounds: Int              // intervals
}

enum WorkoutCompiler {
    static func phases(for config: TimerConfig) -> [Phase]
}
```

Persistence: the last-used `TimerConfig` and settings are stored in `UserDefaults` (`@AppStorage`). No database in the MVP.

### Extension points for later versions

| Future feature (from `SPEC.md`) | How it plugs in |
|---|---|
| Stopwatch, AMRAP | New `TimerType` and `PhaseKind.countUp`; new compiler case |
| Sets and set rest, cool-down | New fields on `TimerConfig`; new compiler logic |
| Saved presets | Move to SwiftData `Preset` model wrapping `TimerConfig` |
| Custom / mixed workouts | `TimerConfig` gains `blocks: [TimerConfig]`; compiler concatenates phases |
| Live Activity | New service that reads the same phase schedule |
| Voice cues | New service triggered by the same phase-change events |

---

## 7. Project structure

```
Rest & Rep/
├── RestRepApp.swift
├── Models/        TimerModels, Presets, TimeFormat
├── Engine/        WorkoutCompiler, TimerEngine
├── Services/      AppSettings, AudioService, HapticService, NotificationService, WorkoutSession
├── Views/         HomeView, SetupSheet, TimerView, SettingsSheet, Components/
├── DesignSystem/  Colours, Typography, Spacing
└── Resources/Sounds/
RestRepTests/      WorkoutCompilerTests, TimerEngineTests
Config/            Signing.xcconfig (+ git-ignored Signing.local.xcconfig)
```

Constraints: Swift 6, SwiftUI, iOS 17+, iPhone only, portrait only, Apple frameworks only, MIT licence.

---

## 8. Build plan

| Stage | Scope | Done when |
|---|---|---|
| 1 | Skeleton, design tokens, static Home screen | App runs on your iPhone |
| 2 | `WorkoutCompiler` and `TimerEngine` with unit tests | Tests pass for countdown, intervals, pause, resume |
| 3 | Timer screen wired to presets and rest chips | A full Tabata runs in the foreground |
| 4 | Sounds and haptics | Alerts fire on every phase change with music playing |
| 5 | Notifications for locked phone | Lock the phone for a whole Tabata; all alerts arrive |
| 6 | Setup sheet, last-used card, Settings, polish | Custom countdown and intervals work end to end |

---

## 9. Acceptance criteria

| # | Criterion |
|---|---|
| A1 | Any preset or rest chip starts with one tap from Home |
| A2 | A 30-minute interval workout finishes within 1 second of expected time |
| A3 | With the phone locked for a full Tabata, all phase changes produce an alert |
| A4 | Background music keeps playing and ducks briefly on alerts |
| A5 | Countdown digits never shift position |
| A6 | Adding a new `TimerType` requires no changes to `TimerView` or `TimerEngine` |
