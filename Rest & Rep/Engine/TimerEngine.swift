import Foundation
import Observation

/// Something the user should be alerted about while a workout plays.
enum TimerEvent: Equatable, Sendable {
    /// One of the last three seconds of a phase.
    case tick
    /// A new phase began.
    case phaseStarted(PhaseKind)
    /// The final phase ended.
    case finished
}

/// A point in the future where the workout moves to a new phase (or ends).
struct PhaseTransition: Equatable, Sendable {
    let date: Date
    /// The phase that starts at `date`, or `nil` if the workout finishes.
    let next: Phase?
}

/// Read-only view of the engine at a moment in time.
struct TimerSnapshot: Equatable, Sendable {
    let phase: Phase?
    let remaining: TimeInterval
    /// Fraction of the current phase that has elapsed, 0...1.
    let progress: Double
    let isFinished: Bool
}

/// Plays a flat list of phases against the wall clock.
///
/// The engine never counts down by ticking. On start it computes the absolute end time of
/// every phase; everything else (current phase, remaining time, alerts) is derived from
/// `phaseEnds` and the time passed in. That keeps it accurate across backgrounding and
/// makes it fully deterministic to test.
@Observable
final class TimerEngine {
    enum Status: Equatable, Sendable {
        case idle, running, paused, finished
    }

    private(set) var status: Status = .idle
    private(set) var phases: [Phase] = []
    /// Absolute end time of every phase (rule T1).
    private(set) var phaseEnds: [Date] = []
    private(set) var pausedAt: Date?

    /// The last moment alerts were computed up to. Not observed by the UI.
    @ObservationIgnored private var lastAdvance: Date = .distantPast

    /// Highest round number in the workout, or `nil` if it has no rounds (e.g. a countdown).
    var totalRounds: Int? {
        phases.compactMap(\.round).max()
    }

    // MARK: - Controls

    func start(_ config: TimerConfig, at now: Date = .now) {
        start(phases: WorkoutCompiler.phases(for: config), at: now)
    }

    func start(phases: [Phase], at now: Date = .now) {
        self.phases = phases
        var end = now
        phaseEnds = phases.map { phase in
            end += phase.duration
            return end
        }
        pausedAt = nil
        lastAdvance = now
        status = phases.isEmpty ? .finished : .running
    }

    /// Stores the pause moment (rule T3).
    func pause(at now: Date = .now) {
        guard status == .running else { return }
        pausedAt = now
        status = .paused
    }

    /// Shifts all end times by the paused duration (rule T3).
    func resume(at now: Date = .now) {
        guard status == .paused, let pausedAt else { return }
        let pausedFor = max(0, now.timeIntervalSince(pausedAt))
        phaseEnds = phaseEnds.map { $0.addingTimeInterval(pausedFor) }
        lastAdvance = lastAdvance.addingTimeInterval(pausedFor)
        self.pausedAt = nil
        status = .running
    }

    func stop() {
        status = .idle
        phases = []
        phaseEnds = []
        pausedAt = nil
        lastAdvance = .distantPast
    }

    // MARK: - Reading state

    /// Current phase and remaining time, worked out from the clock (rules T2 and T5).
    func snapshot(at now: Date = .now) -> TimerSnapshot {
        let time = pausedAt ?? now
        guard status != .idle,
              let index = phaseEnds.firstIndex(where: { $0 > time }) else {
            return TimerSnapshot(phase: nil, remaining: 0, progress: 1, isFinished: status != .idle)
        }
        let phase = phases[index]
        let remaining = phaseEnds[index].timeIntervalSince(time)
        let progress = phase.duration > 0 ? 1 - remaining / phase.duration : 1
        return TimerSnapshot(
            phase: phase,
            remaining: remaining,
            progress: min(max(progress, 0), 1),
            isFinished: false
        )
    }

    /// Every phase change still to come. Used to schedule notifications (rule T6).
    func upcomingTransitions(after now: Date = .now) -> [PhaseTransition] {
        guard status == .running else { return [] }
        return phaseEnds.indices.compactMap { index in
            let date = phaseEnds[index]
            guard date > now else { return nil }
            let next = index + 1 < phases.count ? phases[index + 1] : nil
            return PhaseTransition(date: date, next: next)
        }
    }

    // MARK: - Advancing

    /// Returns the alerts that fall between the previous call and `now`, in order,
    /// and marks the workout finished once the last phase has ended.
    func advance(to now: Date = .now) -> [TimerEvent] {
        guard status == .running else { return [] }
        let events = events(in: lastAdvance, now)
        lastAdvance = max(lastAdvance, now)
        updateFinished(at: now)
        return events
    }

    /// Catches up to `now` without producing alerts, e.g. after returning from the background
    /// where notifications already alerted the user (rule T5).
    func resync(to now: Date = .now) {
        guard status == .running else { return }
        lastAdvance = max(lastAdvance, now)
        updateFinished(at: now)
    }

    private func updateFinished(at now: Date) {
        if let last = phaseEnds.last, now >= last {
            status = .finished
        }
    }

    /// Alerts with a time in the half-open window `(from, to]`.
    private func events(in from: Date, _ to: Date) -> [TimerEvent] {
        guard to > from else { return [] }
        var timed: [(Date, TimerEvent)] = []

        for index in phases.indices {
            let end = phaseEnds[index]
            let start = end.addingTimeInterval(-phases[index].duration)

            // Last three seconds of the phase.
            for secondsLeft in [3.0, 2.0, 1.0] {
                let time = end.addingTimeInterval(-secondsLeft)
                if time > start, time > from, time <= to {
                    timed.append((time, .tick))
                }
            }

            // End of the phase: either the next phase starts or the workout is done.
            if end > from, end <= to {
                let event: TimerEvent = index + 1 < phases.count
                    ? .phaseStarted(phases[index + 1].kind)
                    : .finished
                timed.append((end, event))
            }
        }

        return timed.sorted { $0.0 < $1.0 }.map(\.1)
    }
}
