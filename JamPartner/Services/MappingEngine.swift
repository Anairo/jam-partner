import Foundation

final class MappingEngine {
    static let noteToButton: [UInt8: Int] = [
        15: 0, 25: 1, 35: 2, 45: 3,
    ]

    var debounceMs: Double {
        get { queue.sync { _debounceMs } }
        set { queue.sync { _debounceMs = newValue } }
    }

    let comboWindowMs: Double = 150
    let comboButtons: Set<Int> = [0, 3]

    var onLog: ((String) -> Void)?
    var onButtonTriggered: (@MainActor (Int) -> Void)?
    var onCycleModeRequested: (@MainActor () -> Void)?

    private let midiService: any MIDIServiceProtocol

    private var _debounceMs: Double = 250
    private var lastTriggerTime: [String: TimeInterval] = [:]
    private var pendingButtons: [Int: TimeInterval] = [:]
    private var pendingTimers: [Int: DispatchWorkItem] = [:]
    private let queue = DispatchQueue(label: "com.jampartner.mapping-engine")

    init(midiService: any MIDIServiceProtocol) {
        self.midiService = midiService
    }

    func trigger(action: Action) {
        queue.async { [weak self] in
            self?.triggerOnQueue(action: action)
        }
    }

    func handleButtonPress(button: Int) {
        queue.async { [weak self] in
            self?.handleButtonPressOnQueue(button: button)
        }
    }

    func handleIncoming(status: UInt8, data1: UInt8, data2: UInt8) {
        queue.async { [weak self] in
            self?.handleIncomingOnQueue(status: status, data1: data1, data2: data2)
        }
    }

    private func triggerOnQueue(action: Action) {
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastTriggerTime[action.id],
           (now - last) * 1000 < _debounceMs {
            onLog?("debounce: \(action.label) skipped")
            return
        }

        lastTriggerTime[action.id] = now
        midiService.sendCC(controller: action.cc, value: 127, channel: 0)
    }

    private func triggerButtonOnMainActor(_ button: Int) {
        Task { @MainActor [weak self] in
            self?.onButtonTriggered?(button)
        }
    }

    private func requestModeCycleOnMainActor() {
        Task { @MainActor [weak self] in
            self?.onCycleModeRequested?()
        }
    }

    private func handleButtonPressOnQueue(button: Int) {
        let now = ProcessInfo.processInfo.systemUptime

        if comboButtons.contains(button) {
            guard let partner = comboButtons.first(where: { $0 != button }) else {
                triggerButtonOnMainActor(button)
                return
            }

            if let partnerTime = pendingButtons[partner],
               (now - partnerTime) * 1000 < comboWindowMs {
                pendingTimers[partner]?.cancel()
                pendingTimers.removeValue(forKey: partner)
                pendingButtons.removeValue(forKey: partner)
                pendingButtons.removeValue(forKey: button)
                requestModeCycleOnMainActor()
                return
            }

            pendingButtons[button] = now
            let work = DispatchWorkItem { [weak self] in
                self?.queue.async {
                    self?.pendingButtons.removeValue(forKey: button)
                    self?.pendingTimers.removeValue(forKey: button)
                    self?.triggerButtonOnMainActor(button)
                }
            }

            pendingTimers[button]?.cancel()
            pendingTimers[button] = work
            queue.asyncAfter(deadline: .now() + comboWindowMs / 1000, execute: work)
            return
        }

        triggerButtonOnMainActor(button)
    }

    private func handleIncomingOnQueue(status: UInt8, data1: UInt8, data2: UInt8) {
        let messageType = status & 0xF0
        let channel = status & 0x0F

        switch messageType {
        case 0x90 where data2 > 0:
            onLog?("IN: Note On  ch=\(channel) note=\(data1) vel=\(data2)")
            if let button = Self.noteToButton[data1] {
                handleButtonPressOnQueue(button: button)
            }
        case 0x80, 0x90:
            onLog?("IN: Note Off ch=\(channel) note=\(data1)")
        case 0xB0:
            onLog?("IN: CC ch=\(channel) cc=\(data1) val=\(data2)")
        default:
            onLog?("IN: status=0x\(String(status, radix: 16)) d1=\(data1) d2=\(data2)")
        }
    }
}
