import SwiftUI
import UIKit

/// Connects the engine to alerts, notifications and the screen.
///
/// A short loop asks the engine which alerts fell due since the last check and plays them.
/// Time is always read from the clock, so the loop's cadence doesn't affect accuracy. While the
/// app is in the background the loop only resyncs, because notifications alert the user there.
@Observable
final class WorkoutSession {
    let engine = TimerEngine()
    private(set) var config: TimerConfig?

    @ObservationIgnored private let audio = AudioService()
    @ObservationIgnored private let haptics = HapticService()
    @ObservationIgnored private let notifications = NotificationService()
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var isInForeground = true

    // MARK: - Controls

    func start(_ config: TimerConfig) {
        self.config = config
        engine.start(config)
        haptics.prepare()
        startLoop()
        Task {
            await notifications.requestAuthorizationIfNeeded()
            scheduleNotifications()
        }
        updateIdleTimer()
    }

    func pause() {
        engine.pause()
        stopLoop()
        notifications.cancelAll()
        updateIdleTimer()
    }

    func resume() {
        engine.resume()
        startLoop()
        scheduleNotifications()
        updateIdleTimer()
    }

    func restart() {
        guard let config else { return }
        start(config)
    }

    func end() {
        stopLoop()
        engine.stop()
        notifications.cancelAll()
        config = nil
        updateIdleTimer()
    }

    // MARK: - App lifecycle

    func sceneDidChange(to phase: ScenePhase) {
        isInForeground = phase == .active
        guard phase == .active else { return }
        // Work out where we are from the clock (rule T5). Missed alerts were already
        // delivered as notifications, so don't replay them.
        engine.resync(to: .now)
        if engine.status == .running {
            startLoop()
            scheduleNotifications()
        }
        updateIdleTimer()
    }

    // MARK: - Private

    private func startLoop() {
        loop?.cancel()
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.step() else { return }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    private func stopLoop() {
        loop?.cancel()
        loop = nil
    }

    /// Returns whether the workout is still running.
    private func step(now: Date = .now) -> Bool {
        if isInForeground {
            for event in engine.advance(to: now) {
                audio.play(for: event)
                haptics.play(for: event)
            }
        } else {
            engine.resync(to: now)
        }
        guard engine.status == .running else {
            updateIdleTimer()
            return false
        }
        return true
    }

    private func scheduleNotifications() {
        guard engine.status == .running else { return }
        notifications.schedule(engine.upcomingTransitions(), totalRounds: engine.totalRounds)
    }

    private func updateIdleTimer() {
        let active = engine.status == .running || engine.status == .paused
        UIApplication.shared.isIdleTimerDisabled = active && AppSettings.keepAwake
    }
}
