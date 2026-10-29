import Foundation

/// The kinds of timer the engine understands.
/// Future: stopwatch, amrap, custom
enum TimerType: String, Codable, Sendable {
    case countdown
    case intervals
}

/// The kind of a single phase in a compiled workout.
/// Future: setRest, coolDown, countUp
enum PhaseKind: String, Codable, Sendable {
    case getReady
    case work
    case rest
}

/// One step in the flat list of phases the engine plays.
struct Phase: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: PhaseKind
    let duration: TimeInterval
    let round: Int?

    init(id: UUID = UUID(), kind: PhaseKind, duration: TimeInterval, round: Int? = nil) {
        self.id = id
        self.kind = kind
        self.duration = duration
        self.round = round
    }
}

/// User-facing description of a timer. Converted to phases by `WorkoutCompiler`.
struct TimerConfig: Codable, Equatable, Hashable, Sendable {
    var type: TimerType
    var duration: TimeInterval   // countdown
    var work: TimeInterval       // intervals
    var rest: TimeInterval       // intervals
    var rounds: Int              // intervals

    static func countdown(_ duration: TimeInterval) -> TimerConfig {
        TimerConfig(type: .countdown, duration: duration, work: 0, rest: 0, rounds: 1)
    }

    static func intervals(work: TimeInterval, rest: TimeInterval, rounds: Int) -> TimerConfig {
        TimerConfig(type: .intervals, duration: 0, work: work, rest: rest, rounds: rounds)
    }

    /// Total length of the workout, including the get-ready phase.
    var totalDuration: TimeInterval {
        WorkoutCompiler.phases(for: self).reduce(0) { $0 + $1.duration }
    }
}
