import SwiftUI
import SwiftData

struct HostEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let host: Host?

    @State private var alias = ""
    @State private var hostname = ""
    @State private var port = 22
    @State private var username = ""
    @State private var authMethod: Host.AuthMethod = .password
    @State private var password = ""
    @State private var startupCommand = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("Name", text: $alias)
                    TextField("Hostname", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("22", value: $port, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Authentication") {
                    Picker("Method", selection: $authMethod) {
                        Text("Password").tag(Host.AuthMethod.password)
                        Text("SSH Key").tag(Host.AuthMethod.publicKey)
                    }
                    if authMethod == .password {
                        SecureField("Password", text: $password)
                    }
                }

                Section("Options") {
                    TextField("Startup command (optional)", text: $startupCommand)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !startupCommand.isEmpty {
                        Text("Runs automatically after connecting")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(host == nil ? "Add Host" : "Edit Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(hostname.isEmpty || username.isEmpty)
                }
            }
        }
        .onAppear { loadHost() }
    }

    private func loadHost() {
        guard let host else { return }
        alias = host.alias
        hostname = host.hostname
        port = host.port
        username = host.username
        authMethod = host.authMethod
        startupCommand = host.startupCommand ?? ""
        // Try to load existing password from Keychain
        if let pwd = try? KeychainService().retrievePassword(for: "host-pwd-\(host.hostname)-\(host.username)") {
            password = pwd
        }
    }

    private func save() {
        let target = host ?? Host(alias: alias, hostname: hostname, username: username)
        target.alias = alias.isEmpty ? hostname : alias
        target.hostname = hostname
        target.port = port
        target.username = username
        target.authMethod = authMethod
        target.startupCommand = startupCommand.isEmpty ? nil : startupCommand

        if host == nil { context.insert(target) }

        // Save password to Keychain
        if authMethod == .password, !password.isEmpty {
            try? KeychainService().save(password: password, for: "host-pwd-\(target.hostname)-\(target.username)")
        }

        dismiss()
    }
}
