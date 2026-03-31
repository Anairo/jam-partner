//
//  JamPartnerApp.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import SwiftUI

@main
struct JamPartnerApp: App {
    @State private var midi = MidiManager()
    @State private var ble = BleManager()
    @State private var modes = ModeManager()

    var body: some Scene {
        WindowGroup {
            ContentView(midi: midi, ble: ble, modes: modes)
                .onAppear {
                    ble.onMidiReceived = { status, data1, data2 in
                        MappingEngine.handleIncoming(
                            status: status, data1: data1, data2: data2,
                            midi: midi, modes: modes)
                    }
                }
        }
    }
}
