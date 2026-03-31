import SwiftUI

struct SingleModeEditorView: View {
    var modeManager: ModeManager
    @State var mode: ButtonMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Edit Mode").font(.headline)
                Spacer()
                Button("Save") {
                    if let idx = modeManager.modes.firstIndex(where: { $0.id == mode.id }) {
                        modeManager.updateMode(at: idx, mode: mode)
                    }
                    dismiss()
                }
            }

            TextField("Mode Name", text: $mode.name)
                .textFieldStyle(.roundedBorder)

            ForEach(0..<4, id: \.self) { i in
                HStack {
                    Text("Button \(i + 1)")
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    Picker("", selection: $mode.actions[i]) {
                        ForEach(ActionCatalog.all) { action in
                            Text(action.label).tag(action.id)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 360, height: 250)
    }
}
