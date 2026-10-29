import SwiftUI

/// Slight press-down feedback for chips and cards.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// Large quick-rest chip. One tap starts the timer.
struct ChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.chip)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: Spacing.minTapHeight)
                .foregroundStyle(Palette.rest)
                .background(
                    Palette.rest.opacity(0.18),
                    in: RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                )
        }
        .buttonStyle(.pressable)
    }
}

/// Large card for a workout. One tap starts it, or opens Setup for custom timers.
struct WorkoutCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var trailingImage = "play.fill"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.18), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: trailingImage)
                    .foregroundStyle(tint)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, minHeight: Spacing.minTapHeight + 16, alignment: .leading)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous))
        }
        .buttonStyle(.pressable)
        .foregroundStyle(.primary)
        .accessibilityElement(children: .combine)
    }
}

/// Thin ring showing how much of the current phase is left.
struct ProgressRing: View {
    /// Fraction of the phase that has elapsed, 0...1.
    let progress: Double
    let colour: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(colour.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, 1 - progress))
                .stroke(colour, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

/// Minutes and seconds wheels bound to a duration in seconds.
struct DurationPicker: View {
    let title: LocalizedStringKey
    @Binding var seconds: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text(TimeFormat.clock(seconds))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                wheel("Minutes", selection: minutes, unit: "min")
                wheel("Seconds", selection: secs, unit: "sec")
            }
            .frame(height: 130)
        }
    }

    private func wheel(_ label: LocalizedStringKey, selection: Binding<Int>, unit: LocalizedStringKey) -> some View {
        Picker(label, selection: selection) {
            ForEach(0..<60, id: \.self) { value in
                Text("\(value) \(Text(unit))").tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityLabel(Text("\(Text(title)) \(Text(label))"))
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { Int(seconds) / 60 },
            set: { seconds = TimeInterval($0 * 60 + Int(seconds) % 60) }
        )
    }

    private var secs: Binding<Int> {
        Binding(
            get: { Int(seconds) % 60 },
            set: { seconds = TimeInterval((Int(seconds) / 60) * 60 + $0) }
        )
    }
}
