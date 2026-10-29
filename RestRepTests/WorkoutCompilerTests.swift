import Testing
@testable import RestRep

struct WorkoutCompilerTests {
    @Test func countdownIsOneRestPhase() {
        let phases = WorkoutCompiler.phases(for: .countdown(90))
        #expect(phases.map(\.kind) == [.rest])
        #expect(phases.first?.duration == 90)
        #expect(phases.first?.round == nil)
    }

    @Test func zeroCountdownHasNoPhases() {
        #expect(WorkoutCompiler.phases(for: .countdown(0)).isEmpty)
    }

    @Test func tabataStartsWithGetReadyAndHasNoFinalRest() {
        let phases = WorkoutCompiler.phases(for: Presets.workouts[0].config)
        #expect(phases.first?.kind == .getReady)
        #expect(phases.first?.duration == WorkoutCompiler.getReadyDuration)
        #expect(phases.filter { $0.kind == .work }.count == 8)
        #expect(phases.filter { $0.kind == .rest }.count == 7)
        #expect(phases.last?.kind == .work)
        // 10s get ready + 8 × 20s work + 7 × 10s rest.
        #expect(Presets.workouts[0].config.totalDuration == 240)
    }

    @Test func roundsAreNumberedInOrder() {
        let phases = WorkoutCompiler.phases(for: .intervals(work: 40, rest: 20, rounds: 3))
        #expect(phases.map(\.kind) == [.getReady, .work, .rest, .work, .rest, .work])
        #expect(phases.map(\.round) == [nil, 1, 1, 2, 2, 3])
    }

    @Test func zeroRestIsSkipped() {
        let phases = WorkoutCompiler.phases(for: .intervals(work: 60, rest: 0, rounds: 10))
        #expect(phases.count == 11)
        #expect(phases.dropFirst().allSatisfy { $0.kind == .work })
    }

    @Test func emptyIntervalsHaveNoPhases() {
        #expect(WorkoutCompiler.phases(for: .intervals(work: 0, rest: 10, rounds: 8)).isEmpty)
        #expect(WorkoutCompiler.phases(for: .intervals(work: 20, rest: 10, rounds: 0)).isEmpty)
    }
}
