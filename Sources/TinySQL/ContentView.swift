import SwiftUI
import AppKit
import TinyKit

struct ContentView: View {
    @Bindable var state: AppState
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @State private var eventMonitor: Any?
    @State private var aiState = AIState()
    @State private var editorBridge = EditorBridge()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if state.isConnected {
                TableListView(state: state)
                    .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Not Connected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
            }
        } detail: {
            VStack(spacing: 0) {
                if state.isConnected {
                    if state.selectedTable != nil {
                        if state.isLoading {
                            ProgressView("Loading…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            TablePreviewView(columns: state.columns, rows: state.rows)
                            SQLStatusBar(state: state)
                        }
                    } else {
                        Text("Select a table from the sidebar")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if state.sqlFilePath != nil {
                    SQLFileView(state: state, editorBridge: editorBridge)
                } else {
                    ConnectionView(state: state)
                }

                if let error = state.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                        Spacer()
                        Button("Dismiss") { state.error = nil }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.08))
                }
            }
            .modifier(CmdKOverlay(
                aiState: aiState,
                editorBridge: editorBridge,
                content: state.aiDocument,
                fileExtension: state.sqlFilePath != nil ? "sql" : "txt"
            ))
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let chars = event.charactersIgnoringModifiers ?? ""

                if flags == .command && chars == "k" {
                    aiState.activate(
                        selection: state.sqlFilePath != nil ? editorBridge.currentSelection : "",
                        range: state.sqlFilePath != nil ? editorBridge.currentSelectedRange : NSRange(location: 0, length: 0),
                        bridge: state.sqlFilePath != nil ? editorBridge : nil,
                        supportedExtensions: []
                    )
                    return nil
                }

                return event
            }
        }
    }
}
