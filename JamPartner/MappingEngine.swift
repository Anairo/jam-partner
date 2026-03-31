//
//  MappingEngine.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import Foundation

struct MappingEngine {

    static let noteToButton: [UInt8: Int] = [
        15: 0,
        25: 1,
        35: 2,
        45: 3,
    ]

    static var debounceMs: Double = 250
    static let comboWindowMs: Double = 150
    static let comboButtons: Set<Int> = [0, 3]

    private static var lastTriggerTime: [Int: TimeInterval] = [:]
    private static var pendingButtons: [Int: TimeInterval] = [:]
    private static var pendingTimers: [Int: DispatchWorkItem] = [:]

    // MARK: - Mode-aware trigger

    static func trigger(button: Int, midi: MidiManager, modes: ModeManager) {
        guard let action = modes.actionForButton(button) else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastTriggerTime[action.id.hashValue],
           (now - last) * 1000 < debounceMs {
            midi.appendLog("debounce: \(action.label) skipped")
            return
        }
        lastTriggerTime[action.id.hashValue] = now
        midi.sendCC(controller: action.cc, value: 127, channel: 0)
    }

    // MARK: - Combo detection

    static func handleButtonPress(button: Int, midi: MidiManager, modes: ModeManager) {
        let now = ProcessInfo.processInfo.systemUptime

        if comboButtons.contains(button) {
            let partner = comboButtons.first { $0 != button }!
            if let partnerTime = pendingButtons[partner],
               (now - partnerTime) * 1000 < comboWindowMs {
                pendingTimers[partner]?.cancel()
                pendingTimers.removeValue(forKey: partner)
                pendingButtons.removeValue(forKey: partner)
                pendingButtons.removeValue(forKey: button)
                modes.cycleMode()
                midi.appendLog("Mode -> \(modes.currentMode.name)")
                return
            }

            pendingButtons[button] = now
            let work = DispatchWorkItem {
                pendingButtons.removeValue(forKey: button)
                pendingTimers.removeValue(forKey: button)
                trigger(button: button, midi: midi, modes: modes)
            }
            pendingTimers[button]?.cancel()
            pendingTimers[button] = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + comboWindowMs / 1000,
                execute: work
            )
            return
        }

        trigger(button: button, midi: midi, modes: modes)
    }

    // MARK: - Incoming BLE MIDI

    static func handleIncoming(status: UInt8, data1: UInt8, data2: UInt8,
                               midi: MidiManager, modes: ModeManager) {
        let messageType = status & 0xF0
        let channel = status & 0x0F

        switch messageType {
        case 0x90 where data2 > 0:
            midi.appendLog("IN: Note On  ch=\(channel) note=\(data1) vel=\(data2)")
            if let button = noteToButton[data1] {
                handleButtonPress(button: button, midi: midi, modes: modes)
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
