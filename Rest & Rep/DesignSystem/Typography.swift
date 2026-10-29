import SwiftUI

enum Typography {
    /// SF Pro Rounded with monospaced digits, so the countdown never jitters.
    static func digits(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded).monospacedDigit()
    }

    static let phaseLabel = Font.system(.title, design: .rounded, weight: .heavy)
    static let context = Font.system(.title2, design: .rounded, weight: .semibold)
    static let chip = Font.system(.title3, design: .rounded, weight: .semibold).monospacedDigit()
    static let control = Font.system(.title3, design: .rounded, weight: .semibold)
}
