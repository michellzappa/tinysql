import SwiftUI

struct SQLStatusBar: View {
    @Bindable var state: AppState

    var body: some View {
        HStack(spacing: 16) {
            if let table = state.selectedTable {
                Text(table)
                    .fontWeight(.medium)
            }
            Text("\(state.columns.count) columns")
            Text("\(state.totalRowCount) rows")
            if state.queryTime > 0 {
                Text(String(format: "%.0f ms", state.queryTime * 1000))
            }

            Spacer()

            if state.totalRowCount > state.limit {
                HStack(spacing: 8) {
                    Button(action: { Task { await state.previousPage() } }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!state.canGoPrevious)
                    .buttonStyle(.borderless)

                    Text(state.pageDescription)

                    Button(action: { Task { await state.nextPage() } }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!state.canGoNext)
                    .buttonStyle(.borderless)
                }
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(.bar)
    }
}
