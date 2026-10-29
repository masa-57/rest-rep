import Foundation
import Testing
@testable import RestRep

struct TimerEngineTests {
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test func countdownRemainingComesFromTheClock() {
        let engine = TimerEngine()
        engine.start(.countdown(60), at: t0)

        let snapshot = engine.snapshot(at: t0 + 15)
        #expect(snapshot.phase?.kind == .rest)
        #expect(snapshot.remaining == 45)
        #expect(abs(snapshot.progress - 0.25) < 1e-9)
        #expect(!snapshot.isFinished)
    }

    @Test func intervalsReportTheCurrentPhaseAndRound() {
        let engine = TimerEngine()
        engine.start(.intervals(work: 20, rest: 10, rounds: 8), at: t0)
        #expect(engine.totalRounds == 8)

        #expect(engine.snapshot(at: t0 + 5).phase?.kind == .getReady)

        let work = engine.snapshot(at: t0 + 12)
        #expect(work.phase?.kind == .work)
        #expect(work.phase?.round == 1)
        #expect(work.remaining == 18)

        let rest = engine.snapshot(at: t0 + 35)
        #expect(rest.phase?.kind == .rest)
        #expect(rest.phase?.round == 1)

        #expect(engine.snapshot(at: t0 + 40).phase?.round == 2)
    }

    @Test func pauseFreezesAndResumeShiftsEndTimes() {
        let engine = TimerEngine()
        engine.start(.countdown(60), at: t0)

        engine.pause(at: t0 + 10)
        #expect(engine.status == .paused)
        #expect(engine.snapshot(at: t0 + 100).remaining == 50)
        #expect(engine.upcomingTransitions(after: t0 + 100).isEmpty)

        engine.resume(at: t0 + 100)
        #expect(engine.status == .running)
        #expect(engine.snapshot(at: t0 + 110).remaining == 40)
        #expect(engine.phaseEnds.last == t0 + 150)
    }

    @Test func advanceEmitsTicksPhaseChangesAndFinishInOrder() {
        let engine = TimerEngine()
        engine.start(.intervals(work: 5, rest: 0, rounds: 1), at: t0)

        // Get ready runs 0...10, work 10...15.
        #expect(engine.advance(to: t0 + 6).isEmpty)
        #expect(engine.advance(to: t0 + 10) == [.tick, .tick, .tick, .phaseStarted(.work)])
        #expect(engine.status == .running)
        #expect(engine.advance(to: t0 + 20) == [.tick, .tick, .tick, .finished])
        #expect(engine.status == .finished)
        #expect(engine.snapshot(at: t0 + 20).isFinished)
        #expect(engine.advance(to: t0 + 30).isEmpty)
    }

    @Test func eventsAreNotRepeatedAcrossCalls() {
        let engine = TimerEngine()
        engine.start(.countdown(10), at: t0)
        var events: [TimerEvent] = []
        for step in stride(from: 0.05, through: 11, by: 0.05) {
            events += engine.advance(to: t0 + step)
        }
        #expect(events == [.tick, .tick, .tick, .finished])
    }

    @Test func resyncCatchesUpWithoutAlerts() {
        let engine = TimerEngine()
        engine.start(.intervals(work: 20, rest: 10, rounds: 8), at: t0)

        engine.resync(to: t0 + 100)
        #expect(engine.advance(to: t0 + 100.5).isEmpty)
        #expect(engine.snapshot(at: t0 + 100.5).phase?.round == 4)

        engine.resync(to: t0 + 1_000)
        #expect(engine.status == .finished)
    }

    @Test func pausingShiftsPendingAlerts() {
        let engine = TimerEngine()
        engine.start(.countdown(10), at: t0)
        _ = engine.advance(to: t0 + 5)
        engine.pause(at: t0 + 5)
        #expect(engine.advance(to: t0 + 50).isEmpty)
        engine.resume(at: t0 + 50)
        // Nothing fell due during the pause, and the end has moved to t0 + 55.
        #expect(engine.advance(to: t0 + 51).isEmpty)
        #expect(engine.advance(to: t0 + 55) == [.tick, .tick, .tick, .finished])
    }

    @Test func upcomingTransitionsCoverEveryRemainingPhaseChange() {
        let engine = TimerEngine()
        engine.start(.intervals(work: 20, rest: 10, rounds: 8), at: t0)

        let all = engine.upcomingTransitions(after: t0)
        #expect(all.count == 16)
        #expect(all.first?.date == t0 + 10)
        #expect(all.first?.next?.kind == .work)
        #expect(all.last?.date == t0 + 240)
        #expect(all.last?.next == nil)

        #expect(engine.upcomingTransitions(after: t0 + 100).count == 9)
    }

    /// A2: a 30-minute interval workout ends exactly when expected.
    @Test func longWorkoutFinishesOnTime() {
        let engine = TimerEngine()
        let config = TimerConfig.intervals(work: 45, rest: 15, rounds: 30)
        engine.start(config, at: t0)
        let expectedEnd = t0 + config.totalDuration
        #expect(config.totalDuration == 10 + 30 * 45 + 29 * 15)

        #expect(!engine.snapshot(at: expectedEnd - 0.01).isFinished)
        #expect(engine.snapshot(at: expectedEnd).isFinished)
        #expect(engine.advance(to: expectedEnd).last == .finished)
    }

    @Test func stopResetsEverything() {
        let engine = TimerEngine()
        engine.start(.countdown(60), at: t0)
        engine.stop()
        #expect(engine.status == .idle)
        #expect(engine.phases.isEmpty)
        #expect(engine.snapshot(at: t0).phase == nil)
        #expect(!engine.snapshot(at: t0).isFinished)
    }
}

struct TimeFormatTests {
    @Test func countdownRoundsUp() {
        #expect(TimeFormat.countdown(10) == "0:10")
        #expect(TimeFormat.countdown(10.000_000_1) == "0:10")
        #expect(TimeFormat.countdown(9.2) == "0:10")
        #expect(TimeFormat.countdown(0.3) == "0:01")
        #expect(TimeFormat.countdown(0) == "0:00")
        #expect(TimeFormat.countdown(3_725) == "1:02:05")
    }

    @Test func shortLabelsMatchHomeChips() {
        #expect(Presets.restDurations.map(TimeFormat.short) == ["60s", "90s", "2m", "3m"])
        #expect(TimeFormat.short(150) == "2:30")
    }
}
