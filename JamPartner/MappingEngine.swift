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

    static func trigger(_ index: Int, midi: MidiManager) {
        let action = actions[index]
        midi.sendCC(controller: action.cc, value: action.value, channel: action.channel)
    }
}
