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
    var modes: ModeManager
    @State private var debounceMs: Double = 250
    @State private var showModeEditor = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 10) {
            Text("JamPartner")
                .font(.title.bold())

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
                                Text(device.name).font(.caption)
                                Spacer()
                                Button("Connect") { ble.connect(to: device) }
                                    .controlSize(.mini)
                            }
                        }
                    }
                }
            }

            HStack {
                Text("Mode: \(modes.currentMode.name)")
                    .font(.subheadline.bold())
                Spacer()
                Button("Edit Modes") { showModeEditor = true }
                    .controlSize(.small)
                Button("Next Mode") { modes.cycleMode() }
                    .controlSize(.small)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        MappingEngine.handleButtonPress(
                            button: index, midi: midi, modes: modes)
                    } label: {
                        Text(modes.currentMode.label(for: index))
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            GroupBox("Debounce") {
                HStack {
                    Slider(value: $debounceMs, in: 50...800, step: 10)
                        .onChange(of: debounceMs) {
                            MappingEngine.debounceMs = debounceMs
                        }
                    Text("\(Int(debounceMs)) ms")
                        .font(.caption.monospacedDigit())
                        .frame(width: 52, alignment: .trailing)
                }
            }

            Divider()

            Text("MIDI Log")
                .font(.caption.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(combinedLog.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 140)
        }
        .padding()
        .frame(width: 400, height: 620)
        .sheet(isPresented: $showModeEditor) {
            ModeEditorView(modes: modes)
        }
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

// MARK: - Mode Editor

struct ModeEditorView: View {
    var modes: ModeManager
    @Environment(\.dismiss) private var dismiss
    @State private var editingMode: ButtonMode?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Modes").font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }

            List {
                ForEach(Array(modes.modes.enumerated()), id: \.element.id) { index, mode in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name).font(.subheadline.bold())
                            Text(mode.actions.compactMap { ActionCatalog.find($0)?.label }.joined(separator: " / "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if modes.currentModeIndex == index {
                            Text("Active")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        Button("Edit") { editingMode = mode }
                            .controlSize(.small)
                    }
                }
                .onDelete { offsets in
                    for i in offsets { modes.removeMode(at: i) }
                }
            }
            .frame(minHeight: 150)

            Button("Add Mode") {
                let newMode = ButtonMode(
                    id: UUID(),
                    name: "New Mode",
                    actions: ["play_stop", "play_stop", "play_stop", "play_stop"]
                )
                modes.addMode(newMode)
                editingMode = newMode
            }
            .controlSize(.small)
        }
        .padding()
        .frame(width: 400, height: 350)
        .sheet(item: $editingMode) { mode in
            SingleModeEditorView(modes: modes, mode: mode)
        }
    }
}

struct SingleModeEditorView: View {
    var modes: ModeManager
    @State var mode: ButtonMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Edit Mode").font(.headline)
                Spacer()
                Button("Save") {
                    if let idx = modes.modes.firstIndex(where: { $0.id == mode.id }) {
                        modes.updateMode(at: idx, mode: mode)
                    }
                    dismiss()
                }
            }

            TextField("Mode Name", text: $mode.name)
                .textFieldStyle(.roundedBorder)

            ForEach(0..<4, id: \.self) { i in
                HStack {
                    Text("Button \(i + 1)")
                        .font(.subheadline)
                        .frame(width: 70, alignment: .leading)
                    Picker("", selection: $mode.actions[i]) {
                        ForEach(ActionCatalog.all) { action in
                            Text(action.label).tag(action.id)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 360, height: 250)
    }
}
