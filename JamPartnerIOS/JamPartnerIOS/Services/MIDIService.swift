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

/// Crée une source MIDI virtuelle et envoie des messages MIDI 1.0 via CoreMIDI.
/// Les appels CoreMIDI sont thread-safe par conception
/// Les rappels `onLog` doivent être dispatchés sur le main thread par l'appelant
/// (ex: via `Task { @MainActor in ... }` dans PerformViewModel).
class MIDIService: MIDIServiceProtocol {

    // MARK: Callback de log  (nil par défaut)
        
    var onLog: ((String) -> Void)?

    // MARK: Propriétés CoreMIDI privées

    private var client = MIDIClientRef()
    private var virtualSource = MIDIEndpointRef()

    // MARK: - Démarrage

    func start() {
        let clientStatus = MIDIClientCreateWithBlock(
            "JamPartner Client" as CFString, &client
        ) { _ in }

        guard clientStatus == noErr else {
            onLog?("Failed to create MIDI client: \(clientStatus)")
            return
        }

        let sourceStatus = MIDISourceCreateWithProtocol(
            client,
            "JamPartner Out" as CFString,
            ._1_0,
            &virtualSource
        )

        guard sourceStatus == noErr else {
            onLog?("Failed to create virtual MIDI source: \(sourceStatus)")
            return
        }

        onLog?("Virtual MIDI source created: JamPartner Out")
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

    // MARK: - Envoi bas niveau

    private func send(status: UInt8, data1: UInt8, data2: UInt8) {
        guard virtualSource != 0 else {
            onLog?("No virtual source — call start() first")
            return
        }
            
        let word: UInt32 = 0x2000_0000
            | UInt32(status) << 16
            | UInt32(data1)  << 8
            | UInt32(data2)

        var eventList = MIDIEventList()
        var packet = MIDIEventListInit(&eventList, ._1_0)

        withUnsafePointer(to: word) { ptr in
            packet = MIDIEventListAdd(
                &eventList,
                MemoryLayout<MIDIEventList>.size,
                packet,
                0,   // timestamp : 0 = envoi immédiat
                1,   // 1 mot UMP
                ptr
            )
        }

        let err = MIDIReceivedEventList(virtualSource, &eventList)
        if err != noErr {
            onLog?("MIDIReceivedEventList error: \(err)")
        }
    }
}
