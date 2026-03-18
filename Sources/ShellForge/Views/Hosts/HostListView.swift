import SwiftUI
import SwiftData

struct HostListView: View {
    @Query(sort: \Host.sortOrder) private var hosts: [Host]
    @Environment(\.modelContext) private var context
    @State private var showAddHost = false

    var body: some View {
        List {
            ForEach(hosts) { host in
                NavigationLink(value: host) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(host.alias).font(.headline)
                        Text("\(host.username)@\(host.hostname):\(host.port)")
                            .font(.caption).foregroundStyle(.secondary)
                        if let cmd = host.startupCommand {
                            Text(cmd)
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteHosts)
            .onMove(perform: moveHosts)
        }
        .navigationTitle("Hosts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddHost = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showAddHost) {
            HostEditView(host: nil)
        }
        .overlay {
            if hosts.isEmpty {
                ContentUnavailableView(
                    "No Hosts",
                    systemImage: "server.rack",
                    description: Text("Tap + to add your first server")
                )
            }
        }
    }

    private func deleteHosts(at offsets: IndexSet) {
        for index in offsets {
            let host = hosts[index]
            // Clean up Keychain entry
            try? KeychainService().delete(id: "host-pwd-\(host.hostname)-\(host.username)")
            context.delete(host)
        }
    }

    private func moveHosts(from source: IndexSet, to destination: Int) {
        var mutableHosts = hosts
        mutableHosts.move(fromOffsets: source, toOffset: destination)
        for (index, host) in mutableHosts.enumerated() {
            host.sortOrder = index
        }
    }
}
