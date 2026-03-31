@testable import JamPartnerIOS

final class MockMIDIService: MIDIServiceProtocol {
    var onLog: ((String) -> Void)?

    var startCalled = false
    var sentCCs: [(controller: UInt8, value: UInt8, channel: UInt8)] = []
    var sentNoteOns: [(note: UInt8, velocity: UInt8, channel: UInt8)] = []
    var sentNoteOffs: [(note: UInt8, velocity: UInt8, channel: UInt8)] = []

    func start() {
        startCalled = true
        onLog?("Mock MIDI started")
    }

    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        sentNoteOns.append((note, velocity, channel))
        onLog?("Note On note=\(note) vel=\(velocity)")
    }

    func sendNoteOff(note: UInt8, velocity: UInt8, channel: UInt8) {
        sentNoteOffs.append((note, velocity, channel))
        onLog?("Note Off note=\(note)")
    }

    func sendCC(controller: UInt8, value: UInt8, channel: UInt8) {
        sentCCs.append((controller, value, channel))
        onLog?("CC \(controller) value=\(value)")
    }

    func reset() {
        startCalled = false
        sentCCs.removeAll()
        sentNoteOns.removeAll()
        sentNoteOffs.removeAll()
    }
}
