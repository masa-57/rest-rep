import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.soundKey) private var sound = true
    @AppStorage(AppSettings.hapticsKey) private var haptics = true
    @AppStorage(AppSettings.keepAwakeKey) private var keepAwake = true
    @AppStorage(AppSettings.appearanceKey) private var appearance = Appearance.dark

    var body: some View {
        NavigationStack {
            Form {
                Section("Alerts") {
                    Toggle("Sound", isOn: $sound)
                    Toggle("Haptics", isOn: $haptics)
                }
                Section("Display") {
                    Toggle("Keep screen awake", isOn: $keepAwake)
                    Picker("Appearance", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    SettingsSheet()
}
