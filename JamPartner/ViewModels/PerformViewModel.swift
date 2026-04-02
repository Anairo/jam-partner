import Foundation

@MainActor
@Observable
final class PerformViewModel {
    private(set) var log: [String] = []
    var debounceMs: Double = 250

    let modeManager: ModeManager
    private let midiService: any MIDIServiceProtocol
    private let mappingEngine: MappingEngine

    init(midiService: any MIDIServiceProtocol, mappingEngine: MappingEngine, modeManager: ModeManager) {
        self.midiService = midiService
        self.mappingEngine = mappingEngine
        self.modeManager = modeManager

        midiService.onLog = { [weak self] msg in
            Task { @MainActor in
                self?.appendLog(msg)
            }
        }
        mappingEngine.onLog = { [weak self] msg in
            Task { @MainActor in
                self?.appendLog(msg)
            }
        }
        mappingEngine.onButtonTriggered = { [weak self] index in
            self?.triggerAction(for: index)
        }
        mappingEngine.onCycleModeRequested = { [weak self] in
            guard let self else { return }
            self.modeManager.cycleMode()
            self.appendLog("Mode -> \(self.modeManager.currentMode.name)")
        }

        mappingEngine.config = modeManager.mappingConfig
        debounceMs = modeManager.mappingConfig.debounceMs

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

    func applyMappingConfig(_ config: MappingConfig) {
        mappingEngine.config = config
        debounceMs = config.debounceMs
    }

    private func triggerAction(for index: Int) {
        guard let action = modeManager.actionForButton(index) else { return }
        mappingEngine.trigger(action: action)
    }

    private func appendLog(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 30 { log.removeLast() }
    }
}
