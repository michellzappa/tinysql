import SwiftUI
import AppKit

struct ConnectionView: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: state.connectionType == .postgres ? "server.rack" : "doc.badge.gearshape")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text(state.connectionType == .postgres ? "Connect to PostgreSQL" : "Open SQLite Database")
                    .font(.title2.bold())

                Picker("", selection: $state.connectionType) {
                    ForEach(ConnectionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)

                switch state.connectionType {
                case .postgres:
                    postgresForm
                case .sqlite:
                    sqliteForm
                }

                Button(action: {
                    Task { await state.connect() }
                }) {
                    if state.isConnecting {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 140)
                    } else {
                        Text(state.connectionType == .postgres ? "Connect" : "Open")
                            .frame(width: 140)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .disabled(state.isConnecting || !canConnect)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canConnect: Bool {
        switch state.connectionType {
        case .postgres: return !state.database.isEmpty
        case .sqlite: return !state.sqliteFilePath.isEmpty
        }
    }

    private var postgresForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                LabeledField("Host", text: $state.host)
                LabeledField("Port", value: $state.port)
                    .frame(width: 80)
            }
            LabeledField("Database", text: $state.database)
            LabeledField("Username", text: $state.username)
            SecureField("Password", text: $state.password)
                .textFieldStyle(.roundedBorder)
        }
        .frame(width: 320)
    }

    private var sqliteForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Database file path", text: $state.sqliteFilePath)
                    .textFieldStyle(.roundedBorder)

                Button("Browse…") {
                    browseForSQLiteFile()
                }
            }
        }
        .frame(width: 320)
    }

    private func browseForSQLiteFile() {
        let panel = NSOpenPanel()
        panel.title = "Choose a SQLite Database"
        panel.allowedContentTypes = [
            .init(filenameExtension: "db")!,
            .init(filenameExtension: "sqlite")!,
            .init(filenameExtension: "sqlite3")!,
        ]
        panel.allowsOtherFileTypes = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            state.sqliteFilePath = url.path
        }
    }
}

private struct LabeledField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
    }
}

private extension LabeledField {
    init(_ label: String, value: Binding<Int>) {
        self.label = label
        self._text = Binding(
            get: { String(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) ?? value.wrappedValue }
        )
    }
}
