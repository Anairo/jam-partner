import CoreMIDI

// MARK: - Protocol

protocol MIDIServiceProtocol: AnyObject {
    var onLog: ((String) -> Void)? { get set }
    func start()
    func sendNoteOn(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendNoteOff(note: UInt8, velocity: UInt8, channel: UInt8)
    func sendCC(controller: UInt8, value: UInt8, channel: UInt8)
}

// MARK: - Implementation

class MIDIService: MIDIServiceProtocol {

    var onLog: ((String) -> Void)?

    private var client = MIDIClientRef()
    private var virtualSource = MIDIEndpointRef()
    private var outputPort = MIDIPortRef()

    // MARK: - Démarrage

    func start() {
        let clientStatus = MIDIClientCreateWithBlock(
            "JamPartner Client" as CFString, &client
        ) { _ in }

        guard clientStatus == noErr else {
            onLog?("Failed to create MIDI client: \(clientStatus)")
            return
        }

        let outputStatus = MIDIOutputPortCreate(
            client,
            "JamPartner Out Port" as CFString,
            &outputPort
        )
        if outputStatus != noErr {
            onLog?("Output port unavailable: \(outputStatus)")
        }

        let sourceStatus = MIDISourceCreate(
            client,
            "JamPartner Out" as CFString,
            &virtualSource
        )
        if sourceStatus != noErr {
            onLog?("Virtual source unavailable: \(sourceStatus)")
        }

        onLog?("MIDI ready (source=\(virtualSource != 0), port=\(outputPort != 0))")
    }

    // MARK: - API publique

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

    // MARK: - Envoi bas niveau (MIDIPacketList — compatible tous DAW)

    private func send(status: UInt8, data1: UInt8, data2: UInt8) {
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

        // Virtual source — Ableton (same machine) reads "JamPartner Out"
        if virtualSource != 0 {
            let err = MIDIReceived(virtualSource, &packetList)
            if err != noErr {
                onLog?("MIDIReceived error: \(err)")
            }
        }

        // Output port → external destinations (USB Mac, Network MIDI…)
        if outputPort != 0 {
            for dest in currentDestinations() {
                let err = MIDISend(outputPort, dest, &packetList)
                if err != noErr {
                    onLog?("MIDISend error: \(err)")
                }
            }
        }
    }

    private func currentDestinations() -> [MIDIEndpointRef] {
        let count = MIDIGetNumberOfDestinations()
        guard count > 0 else { return [] }

        var endpoints: [MIDIEndpointRef] = []
        endpoints.reserveCapacity(Int(count))
        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            if endpoint != 0 {
                endpoints.append(endpoint)
            }
        }
        return endpoints
    }
}
