import Foundation

/// Converts a `TimerConfig` into the flat list of phases the engine plays.
/// Adding a new timer type means adding a case here, not changing the engine.
enum WorkoutCompiler {
    static let getReadyDuration: TimeInterval = 10

    static func phases(for config: TimerConfig) -> [Phase] {
        switch config.type {
        case .countdown:
            // A countdown is typically rest between sets, so it plays as a single rest phase.
            guard config.duration > 0 else { return [] }
            return [Phase(kind: .rest, duration: config.duration)]

        case .intervals:
            let rounds = max(config.rounds, 0)
            guard rounds > 0, config.work > 0 else { return [] }

            var phases = [Phase(kind: .getReady, duration: getReadyDuration)]
            for round in 1...rounds {
                phases.append(Phase(kind: .work, duration: config.work, round: round))
                // Rest of 0 is skipped, and there's no rest after the final round.
                if config.rest > 0, round < rounds {
                    phases.append(Phase(kind: .rest, duration: config.rest, round: round))
                }
            }
            return phases
        }
    }
}
