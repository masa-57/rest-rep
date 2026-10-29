import SwiftUI

/// Full-screen timer. Holds no timer state: every frame reads a snapshot from the engine
/// (rule T4), and it only knows about phases, never timer types.
struct TimerView: View {
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmingEnd = false

    var body: some View {
        let engine = session.engine
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: engine.status != .running)) { context in
            let snapshot = engine.snapshot(at: context.date)
            let style = Style(snapshot)

            ZStack {
                style.background.ignoresSafeArea()

                VStack(spacing: Spacing.l) {
                    Spacer(minLength: 0)
                    Text(style.label)
                        .font(Typography.phaseLabel)
                        .tracking(2)
                        .accessibilityAddTraits(.isHeader)
                    dial(snapshot, style: style)
                    Text(roundText(snapshot, totalRounds: engine.totalRounds))
                        .font(Typography.context)
                        .monospacedDigit()
                    Spacer(minLength: 0)
                    controls(snapshot, style: style)
                }
                .padding(Spacing.l)
                .foregroundStyle(style.foreground)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: style.id)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .confirmationDialog("End workout?", isPresented: $confirmingEnd, titleVisibility: .visible) {
            Button("End workout", role: .destructive, action: close)
            Button("Keep going", role: .cancel) {}
        }
    }

    // MARK: - Parts

    private func dial(_ snapshot: TimerSnapshot, style: Style) -> some View {
        ZStack {
            ProgressRing(progress: snapshot.isFinished ? 0 : snapshot.progress, colour: style.foreground)
            Group {
                if snapshot.isFinished {
                    Text("Done")
                        .font(Typography.digits(size: 96))
                } else {
                    Text(TimeFormat.countdown(snapshot.remaining))
                        .font(Typography.digits(size: 120))
                        .contentTransition(.identity)
                        .opacity(session.engine.status == .paused ? 0.5 : 1)
                        .accessibilityLabel(
                            Text("\(TimeFormat.spoken(snapshot.remaining)) remaining")
                        )
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.3)
            .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: 360)
        .aspectRatio(1, contentMode: .fit)
    }

    private func roundText(_ snapshot: TimerSnapshot, totalRounds: Int?) -> String {
        if snapshot.isFinished { return String(localized: "Workout complete") }
        guard let totalRounds, let phase = snapshot.phase else { return " " }
        if let round = phase.round {
            return String(localized: "Round \(round) of \(totalRounds)")
        }
        return String(localized: "\(totalRounds) rounds")
    }

    @ViewBuilder
    private func controls(_ snapshot: TimerSnapshot, style: Style) -> some View {
        if snapshot.isFinished {
            HStack(spacing: Spacing.m) {
                Button(action: session.restart) {
                    Label("Repeat", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: Spacing.minControl)
                        .background(style.foreground.opacity(0.2), in: Capsule())
                }
                Button(action: close) {
                    Label("Done", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: Spacing.minControl)
                        .foregroundStyle(style.background)
                        .background(style.foreground, in: Capsule())
                }
            }
            .font(Typography.control)
            .buttonStyle(.pressable)
        } else {
            let isPaused = session.engine.status == .paused
            HStack(spacing: Spacing.xl) {
                Button {
                    confirmingEnd = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold))
                        .frame(width: Spacing.minControl, height: Spacing.minControl)
                        .background(style.foreground.opacity(0.2), in: Circle())
                }
                .accessibilityLabel("End workout")

                Button {
                    isPaused ? session.resume() : session.pause()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .frame(width: 112, height: 112)
                        .foregroundStyle(style.background)
                        .background(style.foreground, in: Circle())
                }
                .accessibilityLabel(isPaused ? "Resume" : "Pause")

                // Balances the End button so Pause/Resume stays centred.
                Color.clear.frame(width: Spacing.minControl, height: Spacing.minControl)
                    .accessibilityHidden(true)
            }
            .buttonStyle(.pressable)
        }
    }

    private func close() {
        session.end()
        dismiss()
    }
}

/// Colours and label for whatever the timer is showing.
private struct Style {
    let id: String
    let label: String
    let background: Color
    let foreground: Color

    init(_ snapshot: TimerSnapshot) {
        if snapshot.isFinished {
            id = "finished"
            label = String(localized: "FINISHED")
            background = Palette.done
            foreground = .white
        } else if let kind = snapshot.phase?.kind {
            id = kind.rawValue
            label = kind.title
            background = kind.colour
            foreground = kind.onColour
        } else {
            id = "idle"
            label = " "
            background = Palette.done
            foreground = .white
        }
    }
}

#Preview {
    let session = WorkoutSession()
    session.start(Presets.workouts[0].config)
    return TimerView().environment(session)
}
