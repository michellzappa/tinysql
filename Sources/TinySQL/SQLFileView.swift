import SwiftUI
import TinyKit

struct SQLFileView: View {
    @Bindable var state: AppState
    @State private var wordWrap = true
    @State private var fontSize = 14.0
    @State private var showLineNumbers = true
    private let scrollBridge = ScrollBridge()

    private var filename: String {
        (state.sqlFilePath as NSString?)?.lastPathComponent ?? "SQL File"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(filename)
                    .font(.headline)
                Spacer()
                Button("Close") {
                    state.sqlFilePath = nil
                    state.queryText = ""
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            TinyEditorView(
                text: $state.queryText,
                wordWrap: $wordWrap,
                fontSize: $fontSize,
                showLineNumbers: $showLineNumbers,
                shouldHighlight: true,
                highlighterProvider: { SQLHighlighter() },
                commentStyle: .init(prefix: "-- ", suffix: ""),
                scrollBridge: scrollBridge,
                isEditable: false
            )
        }
    }
}
