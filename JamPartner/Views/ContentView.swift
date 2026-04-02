import SwiftUI

struct ContentView: View {
    @Environment(ConnectionViewModel.self) private var connectionVM
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ModeManager.self) private var modeManager
        
        //MARK: PrivateProperties
    @State private var showModeEditor = false
    @State private var showMappingSettings = false

        //MARK: Body
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

            GroupBox("Settings") {
                HStack {
                    Text("Mapping BLE/MIDI")
                        .font(.subheadline)
                    Spacer()
                    Button("Open") { showMappingSettings = true }
                        .controlSize(.small)
                }
            }

            Divider()

            MidiLogView(logs: combinedLog)
        }
        .padding()
        .frame(width: 400, height: 620)
        .sheet(isPresented: $showModeEditor) {
            ModeEditorView()
        }
        .sheet(isPresented: $showMappingSettings) {
            MappingSettingsView()
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}
