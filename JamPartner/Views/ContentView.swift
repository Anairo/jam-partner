import SwiftUI

struct ContentView: View {
    var connectionVM: ConnectionViewModel
    var performVM: PerformViewModel
    @State private var showModeEditor = false

    var body: some View {
        VStack(spacing: 10) {
            Text("JamPartner")
                .font(.title.bold())

            ConnectionView(vm: connectionVM)

            HStack {
                Text("Mode: \(performVM.modeManager.currentMode.name)")
                    .font(.subheadline.bold())
                Spacer()
                Button("Edit Modes") { showModeEditor = true }
                    .controlSize(.small)
                Button("Next Mode") { performVM.cycleMode() }
                    .controlSize(.small)
            }

            ButtonGridView(vm: performVM)
            DebounceView(vm: performVM)

            Divider()

            MidiLogView(logs: combinedLog)
        }
        .padding()
        .frame(width: 400, height: 620)
        .sheet(isPresented: $showModeEditor) {
            ModeEditorView(modeManager: performVM.modeManager)
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}
