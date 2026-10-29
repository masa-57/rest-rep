import SwiftUI

struct SetupSheet: View {
    let type: TimerType
    let onStart: (TimerConfig) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var duration: TimeInterval
    @State private var work: TimeInterval
    @State private var rest: TimeInterval
    @State private var rounds: Int

    /// Starts from the last-used custom timer when it's the same type.
    init(type: TimerType, lastUsed: TimerConfig?, onStart: @escaping (TimerConfig) -> Void) {
        self.type = type
        self.onStart = onStart
        let base = lastUsed?.type == type ? lastUsed : nil
        _duration = State(initialValue: base?.duration ?? 90)
        _work = State(initialValue: base?.work ?? 30)
        _rest = State(initialValue: base?.rest ?? 15)
        _rounds = State(initialValue: base?.rounds ?? 8)
    }

    private var config: TimerConfig {
        switch type {
        case .countdown: .countdown(duration)
        case .intervals: .intervals(work: work, rest: rest, rounds: rounds)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    switch type {
                    case .countdown:
                        DurationPicker(title: "Duration", seconds: $duration)
                    case .intervals:
                        DurationPicker(title: "Work", seconds: $work)
                        DurationPicker(title: "Rest", seconds: $rest)
                        Stepper(value: $rounds, in: 1...50) {
                            HStack {
                                Text("Rounds").font(.headline)
                                Spacer()
                                Text("\(rounds)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(minHeight: Spacing.minTapHeight)
                    }
                }
                .padding(Spacing.m)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Spacing.s) {
                    Text("Total \(TimeFormat.clock(config.totalDuration))")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button {
                        onStart(config)
                    } label: {
                        Text("Start")
                            .font(Typography.control)
                            .frame(maxWidth: .infinity, minHeight: Spacing.minTapHeight)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: Spacing.cornerRadius))
                    .disabled(config.totalDuration <= 0)
                }
                .padding(Spacing.m)
                .background(.bar)
            }
            .navigationTitle(type == .countdown ? "New countdown" : "New intervals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents(type == .countdown ? [.medium, .large] : [.large])
    }
}

#Preview {
    Text("Home")
        .sheet(isPresented: .constant(true)) {
            SetupSheet(type: .intervals, lastUsed: nil) { _ in }
        }
}
