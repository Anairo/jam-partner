import SwiftUI

@MainActor
@main
struct JamPartnerApp: App {
    @State private var connectionVM: ConnectionViewModel
    @State private var performVM: PerformViewModel
    @State private var modeManager: ModeManager

    init() {
        let bleService = BLEService()
        let midiService = MIDIService()
        let modeManager = ModeManager()
        let mappingEngine = MappingEngine(midiService: midiService)

        let connVM = ConnectionViewModel(bleService: bleService)
        let perfVM = PerformViewModel(
            midiService: midiService,
            mappingEngine: mappingEngine,
            modeManager: modeManager
        )

        _connectionVM = State(initialValue: connVM)
        _performVM = State(initialValue: perfVM)
        _modeManager = State(initialValue: modeManager)

        bleService.onMidiMessage = { status, data1, data2 in
            Task { @MainActor in
                perfVM.handleIncomingMidi(status: status, data1: data1, data2: data2)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(connectionVM)
                .environment(performVM)
                .environment(modeManager)
        }
    }
}
