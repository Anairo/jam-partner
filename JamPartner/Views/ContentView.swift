import SwiftUI

struct ContentView: View {
    @Environment(ConnectionViewModel.self) private var connectionVM
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ModeManager.self) private var modeManager
    @State private var showModeEditor = false

    var body: some View {
        VStack(spacing: 10) {
            Text("JamPartner")
                .font(.title.bold())

            ConnectionView()

            HStack {
                Text("Mode: \(modeManager.currentMode.name)")
                    .font(.subheadline.bold())
                Spacer()
                Button("Edit Modes") { showModeEditor = true }
                    .controlSize(.small)
                Button("Next Mode") { performVM.cycleMode() }
                    .controlSize(.small)
            }

            ButtonGridView()
            DebounceView()

            Divider()

            MidiLogView(logs: combinedLog)
        }
        .padding()
        .frame(width: 400, height: 620)
        .sheet(isPresented: $showModeEditor) {
            ModeEditorView()
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}
