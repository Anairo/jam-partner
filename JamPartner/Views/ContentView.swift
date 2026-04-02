import SwiftUI

struct ContentView: View {
    @Environment(ConnectionViewModel.self) private var connectionVM
    @Environment(PerformViewModel.self) private var performVM
<<<<<<< Updated upstream
    @Environment(ModeManager.self) private var modeManager
=======
>>>>>>> Stashed changes
    @State private var showModeEditor = false
    @State private var showMappingSettings = false

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
<<<<<<< Updated upstream
=======

            GroupBox("Settings") {
                HStack {
                    Text("Mapping BLE/MIDI")
                        .font(.subheadline)
                    Spacer()
                    Button("Open") { showMappingSettings = true }
                        .controlSize(.small)
                }
            }
>>>>>>> Stashed changes

            Divider()

            MidiLogView(logs: combinedLog)
        }
        .padding()
        .frame(width: 400, height: 620)
        .sheet(isPresented: $showModeEditor) {
            ModeEditorView()
<<<<<<< Updated upstream
=======
        }
        .sheet(isPresented: $showMappingSettings) {
            MappingSettingsView()
>>>>>>> Stashed changes
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}
