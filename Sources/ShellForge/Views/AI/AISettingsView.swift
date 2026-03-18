import SwiftUI

struct AISettingsView: View {
    @Bindable var aiService: AIService
    @State private var apiKeyInput = ""
    @State private var showAPIKey = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: Binding(
                    get: { aiService.provider },
                    set: { aiService.provider = $0 }
                )) {
                    ForEach(AIService.Provider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            }

            Section("API Key") {
                HStack {
                    if showAPIKey {
                        TextField("API Key", text: $apiKeyInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("API Key", text: $apiKeyInput)
                    }
                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                Button("Save Key") {
                    aiService.apiKey = apiKeyInput
                    HapticManager.notification(.success)
                }
                .disabled(apiKeyInput.isEmpty)

                if aiService.hasAPIKey {
                    Label("Key saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Section("Model") {
                Picker("Model", selection: Binding(
                    get: { aiService.model },
                    set: { aiService.model = $0 }
                )) {
                    ForEach(aiService.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
            }
        }
        .navigationTitle("AI Assistant")
        .onAppear {
            apiKeyInput = aiService.apiKey
        }
    }
}
