//
//  MidiManager.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import CoreMIDI

@Observable
class MidiManager {
    var log: [String] = []
    
    private var client = MIDIClientRef()
    private var virtualSource = MIDIEndpointRef()
    
    init() {
        setupMIDI()
    }
    
    private func setupMIDI() {
           let clientStatus = MIDIClientCreateWithBlock("JamPartner Client" as CFString, &client) { notificationPtr in
               // Optional: react to MIDI notifications
           }
           
           guard clientStatus == noErr else {
               appendLog("Failed to create MIDI client: \(clientStatus)")
               return
           }
           
           let sourceStatus = MIDISourceCreate(client, "JamPartner Out" as CFString, &virtualSource)
           guard sourceStatus == noErr else {
               appendLog("Failed to create virtual MIDI source: \(sourceStatus)")
               return
           }
           
           appendLog("Virtual MIDI source created: JamPartner Out")
       }
    
    
    func sendNoteOn(note: UInt8, velocity: UInt8 = 100, channel: UInt8 = 0) {
        send(status: 0x90 | channel, data1: note, data2: velocity)
        appendLog("Note On  note=\(note) vel=\(velocity)")
    }
    
    func sendNoteOff(note: UInt8, velocity: UInt8 = 0, channel: UInt8 = 0) {
        send(status: 0x80 | channel, data1: note, data2: velocity)
        appendLog("Note Off note=\(note)")
    }
    
    func sendCC(controller: UInt8, value: UInt8, channel: UInt8 = 0) {
        send(status: 0xB0 | channel, data1: controller, data2: value)
        appendLog("CC \(controller) value=\(value)")
    }
    
    private func send(status: UInt8, data1: UInt8, data2: UInt8) {
        guard virtualSource != 0 else {
            appendLog("No virtual source")
            return
        }

        var packetList = MIDIPacketList()
        let bufferSize = MemoryLayout<MIDIPacketList>.size

        withUnsafeMutablePointer(to: &packetList) { ptr in
            var cur = MIDIPacketListInit(ptr)
            let bytes: [UInt8] = [status, data1, data2]
            cur = MIDIPacketListAdd(ptr, bufferSize, cur, 0, bytes.count, bytes)

            let err = MIDIReceived(virtualSource, ptr)
            if err != noErr {
                DispatchQueue.main.async {
                    self.appendLog("MIDIReceived error: \(err)")
                }
            }
        }
    }

    func appendLog(_ message: String) {
          DispatchQueue.main.async {
              self.log.insert(message, at: 0)
              if self.log.count > 30 {
                  self.log.removeLast()
              }
          }
      }
    
}
