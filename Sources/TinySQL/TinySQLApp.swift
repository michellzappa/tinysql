import SwiftUI
import TinyKit
import UniformTypeIdentifiers

@main
struct TinySQLApp: App {
    @NSApplicationDelegateAdaptor(TinyAppDelegate.self) private var appDelegate
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showWelcome = false

    var body: some Scene {
        WindowGroup {
            ContentView(state: state, columnVisibility: $columnVisibility)
                .defaultAppBanner(appName: "TinySQL", associations: [
                    FileTypeAssociation(utType: .database, label: ".db files"),
                ])
                .navigationTitle({
                    if state.isConnected {
                        return "\(state.connectionDisplayName) — TinySQL"
                    } else if let path = state.sqlFilePath {
                        return "\((path as NSString).lastPathComponent) — TinySQL"
                    } else {
                        return "TinySQL"
                    }
                }())
                .frame(minWidth: 700, minHeight: 500)
                .onAppear {
                    if let file = TinyAppDelegate.pendingFiles.first {
                        TinyAppDelegate.pendingFiles.removeAll()
                        openFile(file)
                    } else {
                        state.restoreLastConnection()
                    }
                    TinyAppDelegate.onOpenFiles = { [weak state] urls in
                        guard let state, let url = urls.first else { return }
                        if url.pathExtension.lowercased() == "sql" {
                            state.openSQLFile(url)
                        } else {
                            Task { await state.openSQLiteFile(url) }
                        }
                    }
                    if WelcomeState.isFirstLaunch {
                        showWelcome = true
                    }
                }
                .welcomeSheet(
                    isPresented: $showWelcome,
                    appName: "TinySQL",
                    subtitle: "A minimal, fast PostgreSQL browser for macOS.",
                    features: [
                        (icon: "server.rack", title: "Connect", description: "PostgreSQL and SQLite support"),
                        (icon: "tablecells", title: "Browse Tables", description: "View all tables in your database"),
                        (icon: "magnifyingglass", title: "Preview Data", description: "See table contents with sorting"),
                        (icon: "bolt.horizontal", title: "Fast & Native", description: "Pure Swift connection, no drivers needed"),
                    ],
                    onOpenFolder: { },
                    onDismiss: { }
                )
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About TinySQL") {
                    NSApp.orderFrontStandardAboutPanel()
                }
                Divider()
                Button("Feedback\u{2026}") {
                    NSWorkspace.shared.open(URL(string: "https://tinysuite.app/support.html")!)
                }
                Button("TinySuite Website") {
                    NSWorkspace.shared.open(URL(string: "https://tinysuite.app")!)
                }
            }
            CommandGroup(replacing: .help) {
                Button("TinySQL on GitHub") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/michellzappa/tinysql")!)
                }
            }
            CommandGroup(replacing: .newItem) {
                Button("New Connection...") {
                    Task { await state.disconnect() }
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open\u{2026}") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [
                        .database,
                        UTType(filenameExtension: "sqlite")!,
                        UTType(filenameExtension: "sqlite3")!,
                        UTType(filenameExtension: "sql")!,
                    ]
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        openFile(url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
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

    private func openFile(_ url: URL) {
        if url.pathExtension.lowercased() == "sql" {
            state.openSQLFile(url)
        } else {
            Task { await state.openSQLiteFile(url) }
        }
    }
}
