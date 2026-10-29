import Foundation

enum TimeFormat {
    /// "4:00", or "1:02:30" past an hour.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }

    /// Remaining time rounded up, so a phase shows its full length at the start and "0:01" in its
    /// last second. The small epsilon absorbs floating-point noise from date arithmetic.
    static func countdown(_ remaining: TimeInterval) -> String {
        clock(max(0, (remaining - 0.001).rounded(.up)))
    }

    /// Compact label: "60s", "90s", "2m", "2:30".
    static func short(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        if total < 120 { return "\(total)s" }
        if total % 60 == 0 { return "\(total / 60)m" }
        return clock(seconds)
    }

    /// "1 minute, 30 seconds", for VoiceOver.
    static func spoken(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: max(0, seconds.rounded(.up))) ?? ""
    }
}

extension TimerConfig {
    /// One-line description for cards, e.g. "20s work · 10s rest · 8 rounds".
    var summary: String {
        switch type {
        case .countdown:
            return String(localized: "Countdown · \(TimeFormat.clock(duration))")
        case .intervals:
            let work = TimeFormat.short(work)
            return rest > 0
                ? String(localized: "\(work) work · \(TimeFormat.short(rest)) rest · \(rounds) rounds")
                : String(localized: "\(work) work · \(rounds) rounds")
        }
    }
}
