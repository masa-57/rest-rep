import Foundation

/// A built-in, named workout shown on Home.
struct Preset: Identifiable, Sendable {
    let id: String
    let name: String
    let detail: String
    let config: TimerConfig
}

enum Presets {
    /// Quick rest chips on Home.
    static let restDurations: [TimeInterval] = [60, 90, 120, 180]

    /// Built-in interval workouts.
    static let workouts: [Preset] = [
        Preset(
            id: "tabata",
            name: "Tabata",
            detail: "20s work · 10s rest · 8 rounds",
            config: .intervals(work: 20, rest: 10, rounds: 8)
        ),
        Preset(
            id: "emom10",
            name: "EMOM 10",
            detail: "Every minute · 10 rounds",
            config: .intervals(work: 60, rest: 0, rounds: 10)
        ),
        Preset(
            id: "40-20",
            name: "40 / 20",
            detail: "40s work · 20s rest · 8 rounds",
            config: .intervals(work: 40, rest: 20, rounds: 8)
        )
    ]
}
