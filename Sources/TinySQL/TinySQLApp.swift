import SwiftUI
import TinyKit

@main
struct TinySQLApp: App {
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showWelcome = false

    var body: some Scene {
        WindowGroup {
            ContentView(state: state, columnVisibility: $columnVisibility)
                .navigationTitle(state.isConnected
                    ? "\(state.database) — TinySQL"
                    : "TinySQL")
                .frame(minWidth: 700, minHeight: 500)
                .onAppear {
                    state.restoreLastConnection()
                    if WelcomeState.isFirstLaunch {
                        showWelcome = true
                    }
                }
                .welcomeSheet(
                    isPresented: $showWelcome,
                    appName: "TinySQL",
                    subtitle: "A tiny PostgreSQL viewer.",
                    features: [
                        (icon: "server.rack", title: "Connect", description: "Connect to any PostgreSQL database"),
                        (icon: "tablecells", title: "Browse Tables", description: "View all tables in your database"),
                        (icon: "magnifyingglass", title: "Preview Data", description: "See table contents with sorting"),
                        (icon: "bolt.horizontal", title: "Fast & Native", description: "Pure Swift connection, no drivers needed"),
                    ],
                    openButtonTitle: "Connect to Database",
                    onOpen: { },
                    onDismiss: { }
                )
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Connection...") {
                    Task { await state.disconnect() }
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    withAnimation {
                        columnVisibility = columnVisibility == .detailOnly ? .automatic : .detailOnly
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
    }
}
