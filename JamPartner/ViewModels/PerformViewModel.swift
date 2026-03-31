import Foundation

@Observable
class PerformViewModel {
    private(set) var log: [String] = []
    var debounceMs: Double = 250

    let modeManager: ModeManager
    private let midiService: any MIDIServiceProtocol
    private let mappingEngine: MappingEngine

    init(midiService: any MIDIServiceProtocol, mappingEngine: MappingEngine, modeManager: ModeManager) {
        self.midiService = midiService
        self.mappingEngine = mappingEngine
        self.modeManager = modeManager

        midiService.onLog = { [weak self] msg in self?.appendLog(msg) }
        mappingEngine.onLog = { [weak self] msg in self?.appendLog(msg) }

        midiService.start()
    }

    func onButtonTap(_ index: Int) {
        mappingEngine.handleButtonPress(button: index)
    }

    func syncDebounce() {
        mappingEngine.debounceMs = debounceMs
    }

    func handleIncomingMidi(status: UInt8, data1: UInt8, data2: UInt8) {
        mappingEngine.handleIncoming(status: status, data1: data1, data2: data2)
    }

    func cycleMode() {
        modeManager.cycleMode()
    }

    private func appendLog(_ message: String) {
        DispatchQueue.main.async {
            self.log.insert(message, at: 0)
            if self.log.count > 30 { self.log.removeLast() }
        }
    }
}
