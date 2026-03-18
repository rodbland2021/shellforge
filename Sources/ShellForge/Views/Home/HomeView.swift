import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Host.lastConnected, order: .reverse) private var hosts: [Host]

    var body: some View {
        NavigationStack {
            List {
                let recent = Array(hosts.filter { $0.lastConnected != nil }.prefix(3))
                if !recent.isEmpty {
                    Section("Recent") {
                        ForEach(recent) { host in
                            NavigationLink(value: host) {
                                HostRow(host: host)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink {
                        HostListView()
                    } label: {
                        Label("All Hosts", systemImage: "server.rack")
                    }

                    NavigationLink {
                        Text("Sessions") // Placeholder — replaced in Task 1.5
                    } label: {
                        Label("Sessions", systemImage: "terminal")
                    }

                    NavigationLink {
                        Text("Settings") // Placeholder — replaced in Task 1.6
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("ShellForge")
            .navigationDestination(for: Host.self) { host in
                Text("Terminal for \(host.alias)") // Placeholder — replaced when terminal view is wired up
            }
        }
    }
}

struct HostRow: View {
    let host: Host

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(host.alias).font(.headline)
            Text("\(host.username)@\(host.hostname)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
