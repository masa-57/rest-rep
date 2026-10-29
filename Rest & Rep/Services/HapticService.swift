import UIKit

final class HapticService {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func play(for event: TimerEvent) {
        guard AppSettings.hapticsEnabled else { return }
        switch event {
        case .tick: light.impactOccurred()
        case .phaseStarted(.work): heavy.impactOccurred()
        case .phaseStarted: medium.impactOccurred()
        case .finished: notification.notificationOccurred(.success)
        }
    }
}
