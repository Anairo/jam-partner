//
//  ContentView.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import SwiftUI

struct ContentView: View {
    var midi: MidiManager
    var ble: BleManager

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("JamPartner")
                .font(.title.bold())

            // -- BLE connection section --
            GroupBox("Glove Connection") {
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(ble.isConnected ? .green : .red)
                            .frame(width: 10, height: 10)
                        Text(connectionLabel)
                            .font(.subheadline)
                        Spacer()
                        if ble.isConnected {
                            Button("Disconnect") { ble.disconnect() }
                                .controlSize(.small)
                        } else if ble.isScanning {
                            Button("Stop") { ble.stopScan() }
                                .controlSize(.small)
                        } else {
                            Button("Scan") { ble.startScan() }
                                .controlSize(.small)
                        }
                    }

                    if ble.isScanning && !ble.discoveredDevices.isEmpty {
                        ForEach(ble.discoveredDevices) { device in
                            HStack {
                                Text(device.name)
                                    .font(.caption)
                                Spacer()
                                Button("Connect") { ble.connect(to: device) }
                                    .controlSize(.mini)
                            }
                        }
                    }
                }
            }

            // -- Test buttons --
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(MappingEngine.actions.enumerated()), id: \.offset) { index, action in
                    Button {
                        MappingEngine.trigger(index, midi: midi)
                    } label: {
                        Text(action.label)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
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
                    ForEach(Array(combinedLog.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
        }
        .padding()
        .frame(width: 380, height: 520)
    }

    private var connectionLabel: String {
        if let name = ble.connectedDeviceName {
            return "Connected to \(name)"
        }
        return ble.isScanning ? "Scanning..." : "Disconnected"
    }

    private var combinedLog: [String] {
        midi.log + ble.log
    }
}
