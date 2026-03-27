//
//  ContentView.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import SwiftUI

struct ContentView: View {
    var midi: MidiManager

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("JamPartner")
                .font(.title.bold())

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(MappingEngine.actions.enumerated()), id: \.offset) { index, action in
                    Button {
                        MappingEngine.trigger(index, midi: midi)
                    } label: {
                        Text(action.label)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Divider()

            Text("MIDI Log")
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(midi.log.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
        }
        .padding()
        .frame(width: 360, height: 420)
    }
}
