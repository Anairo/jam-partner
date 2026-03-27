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

    var body: some Scene {
        WindowGroup {
            ContentView(midi: midi)
        }
    }
}
