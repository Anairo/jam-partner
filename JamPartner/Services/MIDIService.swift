import CoreMIDI

protocol MIDIServiceProtocol: AnyObject {
    var onLog: ((String) -> Void)? { get set }
    func start()
    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendNoteOff(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendCC(controller: UInt8, value: UInt8, channel: UInt8)
}

final class MIDIService: MIDIServiceProtocol {
    var onLog: ((String) -> Void)?

    private var client = MIDIClientRef()
    private var virtualSource = MIDIEndpointRef()
    private var isStarted = false

    func start() {
        guard !isStarted else {
            onLog?("MIDI service already started")
            return
        }

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
            MIDIClientDispose(client)
            client = 0
            onLog?("Failed to create virtual MIDI source: \(sourceStatus)")
            return
        }

        isStarted = true
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

    // MIDIPacketList + MIDIReceived — legacy API, most compatible with all DAWs
    private func send(status: UInt8, data1: UInt8, data2: UInt8) {
        guard virtualSource != 0 else {
            onLog?("No virtual source — call start() first")
            return
        }

        let bytes: [UInt8] = [status, data1, data2]
        var packetList = MIDIPacketList()
        var packet = MIDIPacketListInit(&packetList)
        packet = MIDIPacketListAdd(
            &packetList,
            MemoryLayout<MIDIPacketList>.size,
            packet,
            0,
            bytes.count,
            bytes
        )

        let err = MIDIReceived(virtualSource, &packetList)
        if err != noErr {
            onLog?("MIDIReceived error: \(err)")
        }
    }

    deinit {
        if virtualSource != 0 {
            MIDIEndpointDispose(virtualSource)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }
}
