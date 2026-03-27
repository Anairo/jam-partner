//
//  MappingEngine.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

struct MappingEngine {
    struct MidiAction {
        let cc: UInt8
        let value: UInt8
        let channel: UInt8
        let label: String
    }

    static let actions: [MidiAction] = [
        MidiAction(cc: 20, value: 127, channel: 0, label: "Prev Track"),
        MidiAction(cc: 21, value: 127, channel: 0, label: "Next Track"),
        MidiAction(cc: 22, value: 127, channel: 0, label: "Loop / Record"),
        MidiAction(cc: 23, value: 127, channel: 0, label: "Play / Stop"),
    ]

    static let noteToAction: [UInt8: Int] = [
        15: 0,  // Prev Track  -> CC 20
        25: 1,  // Next Track  -> CC 21
        35: 2,  // Loop/Record -> CC 22
        45: 3,  // Play/Stop   -> CC 23
    ]

    static func trigger(_ index: Int, midi: MidiManager) {
        let action = actions[index]
        midi.sendCC(controller: action.cc, value: action.value, channel: action.channel)
    }

    static func handleIncoming(status: UInt8, data1: UInt8, data2: UInt8, midi: MidiManager) {
        let messageType = status & 0xF0
        let channel = status & 0x0F

        switch messageType {
        case 0x90 where data2 > 0:
            midi.appendLog("IN: Note On  ch=\(channel) note=\(data1) vel=\(data2)")
            if let actionIndex = noteToAction[data1] {
                trigger(actionIndex, midi: midi)
            }
        case 0x80, 0x90:
            midi.appendLog("IN: Note Off ch=\(channel) note=\(data1)")
        case 0xB0:
            midi.appendLog("IN: CC ch=\(channel) cc=\(data1) val=\(data2)")
        default:
            midi.appendLog("IN: status=0x\(String(status, radix: 16)) d1=\(data1) d2=\(data2)")
        }
    }
}
