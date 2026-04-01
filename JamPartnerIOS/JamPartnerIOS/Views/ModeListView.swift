import SwiftUI

struct ModeListView: View {
    @Environment(ModeManager.self) private var modeManager
    @State private var editingMode: ButtonMode?

    var body: some View {
        ForEach(Array(modeManager.modes.enumerated()), id: \.element.id) { index, mode in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name).font(.subheadline.bold())
                    Text(mode.actions.compactMap { ActionCatalog.find($0)?.label }.joined(separator: " / "))
                        .font(.caption2)
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
            }
            .contentShape(Rectangle())
            .onTapGesture { editingMode = mode }
        }
        .onDelete { offsets in
            for i in offsets { modeManager.removeMode(at: i) }
        }

        Button {
            let newMode = ButtonMode(
                id: UUID(),
                name: "New Mode",
                actions: ["play_stop", "play_stop", "play_stop", "play_stop"]
            )
            modeManager.addMode(newMode)
            editingMode = newMode
        } label: {
            Label("Add Mode", systemImage: "plus")
        }

        .sheet(item: $editingMode) { mode in
            SingleModeEditorView(mode: mode)
        }
    }
}
