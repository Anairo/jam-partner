import SwiftUI

struct SingleModeEditorView: View {
    @Environment(ModeManager.self) private var modeManager
    @State var mode: ButtonMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Mode Name") {
                    TextField("Name", text: $mode.name)
                }

                Section("Button Actions") {
                    ForEach(0..<4, id: \.self) { i in
                        Picker("Button \(i + 1)", selection: $mode.actions[i]) {
                            ForEach(ActionCatalog.all) { action in
                                Text(action.label).tag(action.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let idx = modeManager.modes.firstIndex(where: { $0.id == mode.id }) {
                            modeManager.updateMode(at: idx, mode: mode)
                        }
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
