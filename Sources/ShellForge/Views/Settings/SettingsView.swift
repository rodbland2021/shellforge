import SwiftUI

struct SettingsView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Appearance") {
                NavigationLink {
                    ThemePickerView()
                } label: {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text(Theme.theme(for: settings.themeID).name)
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper("Font Size: \(settings.fontSize)", value: Binding(
                    get: { settings.fontSize },
                    set: { settings.fontSize = $0 }
                ), in: 8...32)
            }

            Section("Feedback") {
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { settings.hapticEnabled },
                    set: { settings.hapticEnabled = $0 }
                ))

                Toggle("Terminal Bell", isOn: Binding(
                    get: { settings.bellEnabled },
                    set: { settings.bellEnabled = $0 }
                ))
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("0.1.0").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Terminal Engine")
                    Spacer()
                    Text("SwiftTerm").foregroundStyle(.secondary)
                }
                HStack {
                    Text("SSH Transport")
                    Spacer()
                    Text("swift-nio-ssh").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
