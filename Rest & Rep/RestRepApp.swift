import SwiftUI

@main
struct RestRepApp: App {
    @State private var session = WorkoutSession()
    @AppStorage(AppSettings.appearanceKey) private var appearance = Appearance.dark
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppSettings.registerDefaults()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(session)
                .preferredColorScheme(appearance.colorScheme)
                .tint(Palette.work)
        }
        .onChange(of: scenePhase) { _, phase in
            session.sceneDidChange(to: phase)
        }
    }
}
