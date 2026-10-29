import UserNotifications

/// Schedules one local notification per remaining phase change, so alerts still fire while the
/// phone is locked (rule T6). Notifications aren't shown while the app is in the foreground;
/// the engine plays alerts itself then.
final class NotificationService {
    /// iOS keeps at most 64 pending requests per app. Long workouts are topped up whenever the
    /// app returns to the foreground.
    static let maxPending = 60

    private let center = UNUserNotificationCenter.current()
    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() async {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(_ transitions: [PhaseTransition], totalRounds: Int?, now: Date = .now) {
        cancelAll()
        for (index, transition) in transitions.prefix(Self.maxPending).enumerated() {
            let content = UNMutableNotificationContent()
            let sound: AudioService.Sound
            if let next = transition.next {
                content.title = next.kind.title.capitalized
                if let round = next.round, let totalRounds {
                    content.body = String(localized: "Round \(round) of \(totalRounds)")
                }
                sound = AudioService.sound(for: .phaseStarted(next.kind))
            } else {
                content.title = String(localized: "Done")
                content.body = String(localized: "Workout complete")
                sound = .finish
            }
            if AppSettings.soundEnabled {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(sound.fileName))
            }

            let interval = max(transition.date.timeIntervalSince(now), 0.1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            center.add(UNNotificationRequest(identifier: "phase.\(index)", content: content, trigger: trigger))
        }
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
