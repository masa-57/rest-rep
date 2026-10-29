import SwiftUI

/// App colours. Phase colours are always paired with a text label (never colour alone).
enum Palette {
    static let work = Color(red: 0.13, green: 0.68, blue: 0.36)
    static let rest = Color(red: 0.16, green: 0.44, blue: 0.90)
    static let getReady = Color(red: 0.97, green: 0.66, blue: 0.13)
    static let done = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let card = Color(uiColor: .secondarySystemBackground)
}

extension PhaseKind {
    /// Full-screen background on the Timer screen.
    var colour: Color {
        switch self {
        case .getReady: Palette.getReady
        case .work: Palette.work
        case .rest: Palette.rest
        }
    }

    /// Text and controls drawn on top of `colour`, chosen for contrast.
    var onColour: Color {
        switch self {
        case .getReady: .black
        case .work, .rest: .white
        }
    }

    var title: String {
        switch self {
        case .getReady: String(localized: "GET READY")
        case .work: String(localized: "WORK")
        case .rest: String(localized: "REST")
        }
    }
}
