import SwiftUI
import TinyKit

struct ContentView: View {
    @Bindable var state: AppState
    @Binding var columnVisibility: NavigationSplitViewVisibility

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
                    SQLFileView(state: state)
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
        }
    }
}
