import SwiftUI

struct ModeEditorView: View {
    @Environment(ModeManager.self) private var modeManager
    @Environment(\.dismiss) private var dismiss
    @State private var editingMode: ButtonMode?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Modes").font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }

            List {
                ForEach(Array(modeManager.modes.enumerated()), id: \.element.id) { index, mode in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name).font(.subheadline.bold())
                            Text(mode.actions.compactMap { ActionCatalog.find($0)?.label }.joined(separator: " / "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if modeManager.currentModeIndex == index {
                            Text("Active")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        Button("Edit") { editingMode = mode }
                            .controlSize(.small)
                    }
                }
                .onDelete { offsets in
                    for i in offsets.sorted(by: >) {
                        modeManager.removeMode(at: i)
                    }
                }
            }
            .frame(minHeight: 150)

            Button("Add Mode") {
                let newMode = ButtonMode(
                    id: UUID(),
                    name: "New Mode",
                    actions: ["play_stop", "play_stop", "play_stop", "play_stop"]
                )
                modeManager.addMode(newMode)
                editingMode = newMode
            }
            .controlSize(.small)
        }
        .padding()
        .frame(width: 400, height: 350)
        .sheet(item: $editingMode) { mode in
            SingleModeEditorView(mode: mode)
        }
    }
}
