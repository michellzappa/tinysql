import SwiftUI

struct TableListView: View {
    @Bindable var state: AppState

    var body: some View {
        List(state.tables, id: \.self, selection: $state.selectedTable) { table in
            Label(table, systemImage: "tablecells")
                .lineLimit(1)
        }
        .listStyle(.sidebar)
        .onChange(of: state.selectedTable) { _, newValue in
            if let table = newValue {
                Task { await state.selectTable(table) }
            }
        }
        .overlay {
            if state.tables.isEmpty && !state.isLoading {
                ContentUnavailableView {
                    Label("No Tables", systemImage: "tablecells")
                } description: {
                    Text("No public tables found in this database.")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await state.disconnect() }
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .help("Disconnect")
            }
        }
    }
}
