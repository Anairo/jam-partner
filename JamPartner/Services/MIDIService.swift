import CoreMIDI

protocol MIDIServiceProtocol: AnyObject {
    var onLog: ((String) -> Void)? { get set }
    func start()
    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendNoteOff(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendCC(controller: UInt8, value: UInt8, channel: UInt8)
}

class MIDIService: MIDIServiceProtocol {
    var onLog: ((String) -> Void)?

    private var client = MIDIClientRef()
    private var virtualSource = MIDIEndpointRef()

    func start() {
        let clientStatus = MIDIClientCreateWithBlock(
            "JamPartner Client" as CFString, &client
        ) { _ in }

        guard clientStatus == noErr else {
            onLog?("Failed to create MIDI client: \(clientStatus)")
            return
        }

        let sourceStatus = MIDISourceCreate(
            client, "JamPartner Out" as CFString, &virtualSource
        )
        guard sourceStatus == noErr else {
            onLog?("Failed to create virtual MIDI source: \(sourceStatus)")
            return
        }

        onLog?("Virtual MIDI source created: JamPartner Out")
    }

    func sendNoteOn(note: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        send(status: 0x90 | channel, data1: note, data2: velocity)
        onLog?("Note On  note=\(note) vel=\(velocity)")
    }

    func sendNoteOff(note: UInt8, velocity: UInt8 = 0, channel: UInt8 = 0) {
        send(status: 0x80 | channel, data1: note, data2: velocity)
        onLog?("Note Off note=\(note)")
    }

    func sendCC(controller: UInt8, value: UInt8, channel: UInt8 = 0) {
        send(status: 0xB0 | channel, data1: controller, data2: value)
        onLog?("CC \(controller) value=\(value)")
    }

    private func send(status: UInt8, data1: UInt8, data2: UInt8) {
        guard virtualSource != 0 else {
            onLog?("No virtual source")
            return
        }

        var eventList = MIDIEventList()
        var packet = MIDIEventListInit(&eventList, ._1_0)
        let words: [UInt32] = [
            UInt32(status) << 16 | UInt32(data1) << 8 | UInt32(data2)
        ]
        packet = MIDIEventListAdd(&eventList,
                                  MemoryLayout<MIDIEventList>.size,
                                  packet, 0, words.count, words)

        let err = MIDIReceivedEventList(virtualSource, &eventList)
        if err != noErr {
            onLog?("MIDIReceivedEventList error: \(err)")
        }
    }
}
