import SwiftUI

struct ConnectionView: View {
    @Bindable var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "server.rack")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                Text("Connect to PostgreSQL")
                    .font(.title2.bold())

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

                Button(action: {
                    Task { await state.connect() }
                }) {
                    if state.isConnecting {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 140)
                    } else {
                        Text("Connect")
                            .frame(width: 140)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .disabled(state.isConnecting || state.database.isEmpty)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
