import SwiftUI

/// A workout being shown on the Timer screen.
struct ActiveWorkout: Identifiable {
    let id = UUID()
    let config: TimerConfig
}

extension TimerType: Identifiable {
    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(WorkoutSession.self) private var session
    @AppStorage(AppSettings.lastCustomKey) private var lastCustomData: Data?

    @State private var activeWorkout: ActiveWorkout?
    @State private var setupType: TimerType?
    @State private var pendingConfig: TimerConfig?
    @State private var showingSettings = false

    private var lastCustom: TimerConfig? { TimerConfig(data: lastCustomData) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    quickRest
                    workouts
                    customTimer
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Rest & Rep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .sheet(item: $setupType, onDismiss: startPending) { type in
            SetupSheet(type: type, lastUsed: lastCustom) { config in
                lastCustomData = config.encoded
                pendingConfig = config
                setupType = nil
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .fullScreenCover(item: $activeWorkout, onDismiss: session.end) { _ in
            TimerView()
        }
    }

    // MARK: - Sections

    private var quickRest: some View {
        section("Quick rest") {
            HStack(spacing: Spacing.s) {
                ForEach(Presets.restDurations, id: \.self) { seconds in
                    ChipButton(title: TimeFormat.short(seconds)) {
                        start(.countdown(seconds))
                    }
                    .accessibilityLabel("Rest \(TimeFormat.spoken(seconds))")
                    .accessibilityHint("Starts immediately")
                }
            }
        }
    }

    private var workouts: some View {
        section("Workouts") {
            VStack(spacing: Spacing.s) {
                ForEach(Presets.workouts) { preset in
                    WorkoutCard(
                        title: preset.name,
                        subtitle: preset.detail,
                        systemImage: "flame.fill",
                        tint: Palette.work
                    ) {
                        start(preset.config)
                    }
                    .accessibilityHint("Starts immediately")
                }
                if let lastCustom {
                    WorkoutCard(
                        title: String(localized: "Last used"),
                        subtitle: lastCustom.summary,
                        systemImage: "clock.arrow.circlepath",
                        tint: Palette.getReady
                    ) {
                        start(lastCustom)
                    }
                    .accessibilityHint("Starts immediately")
                }
            }
        }
    }

    private var customTimer: some View {
        section("Custom timer") {
            VStack(spacing: Spacing.s) {
                WorkoutCard(
                    title: String(localized: "New countdown"),
                    subtitle: String(localized: "Pick a duration"),
                    systemImage: "timer",
                    tint: Palette.rest,
                    trailingImage: "chevron.right"
                ) {
                    setupType = .countdown
                }
                WorkoutCard(
                    title: String(localized: "New intervals"),
                    subtitle: String(localized: "Work, rest and rounds"),
                    systemImage: "repeat",
                    tint: Palette.rest,
                    trailingImage: "chevron.right"
                ) {
                    setupType = .intervals
                }
            }
        }
    }

    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: - Actions

    private func start(_ config: TimerConfig) {
        session.start(config)
        activeWorkout = ActiveWorkout(config: config)
    }

    private func startPending() {
        guard let config = pendingConfig else { return }
        pendingConfig = nil
        start(config)
    }
}

#Preview {
    HomeView()
        .environment(WorkoutSession())
        .preferredColorScheme(.dark)
}
