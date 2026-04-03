import SwiftUI

struct MappingSettingsView: View {
    @Environment(ModeManager.self) private var modeManager
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ConnectionViewModel.self) private var connectionVM

    @State private var draft = MappingConfig.default
    @State private var showResetAlert = false
    @State private var coordinator = LearnModeCoordinator()

    private var isConnected: Bool { connectionVM.isConnected }

    var body: some View {
        VStack(spacing: 14) {

            // MARK: Notes BLE → boutons
            GroupBox("BLE Notes → Buttons") {
                VStack(alignment: .leading, spacing: 8) {
                    if !isConnected {
                        Label(
                            "Connect a BLE controller to use learn mode.",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    ForEach(0..<4, id: \.self) { index in
                        NoteLearnRow(
                            buttonIndex: index,
                            noteToButton: $draft.noteToButton,
                            coordinator: coordinator,
                            isConnected: isConnected,
                            onStartLearn: { startLearning(for: index) }
                        )
                    }
                }
            }

            // MARK: Mode Combo
            GroupBox("Mode Combo") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pick 2 buttons to cycle mode.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { idx in
                            let selected = draft.comboButtons.contains(idx)
                            Button("Button \(idx + 1)") {
                                toggleComboButton(idx)
                            }
                            .buttonStyle(.bordered)
                            .tint(selected ? .accentColor : .gray)
                        }
                    }

                    HStack {
                        Text("Window")
                        Slider(value: $draft.comboWindowMs, in: 50...500, step: 25)
                        Text("\(Int(draft.comboWindowMs)) ms")
                            .font(.caption.monospacedDigit())
                            .frame(width: 56, alignment: .trailing)
                    }
                }
            }

            // MARK: Debounce
            GroupBox("Debounce") {
                HStack {
                    Slider(value: $draft.debounceMs, in: 50...800, step: 10)
                    Text("\(Int(draft.debounceMs)) ms")
                        .font(.caption.monospacedDigit())
                        .frame(width: 56, alignment: .trailing)
                }
            }

            HStack {
                Spacer()
                Button("Reset Defaults") {
                    showResetAlert = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 430, height: 440)
        .onAppear { draft = modeManager.mappingConfig }
        .onDisappear { coordinator.cancelLearning() }
        .onChange(of: draft) {
            guard draft.isValid else { return }
            modeManager.mappingConfig = draft
            performVM.applyMappingConfig(draft)
        }
        .alert("Reset settings?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) { draft = .default }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Combo, notes and debounce settings will be reset to defaults.")
        }
    }

    private func toggleComboButton(_ index: Int) {
        if draft.comboButtons.contains(index) {
            guard draft.comboButtons.count > 1 else { return }
            draft.comboButtons.remove(index)
            return
        }
        draft.comboButtons.insert(index)
        while draft.comboButtons.count > 2 {
            draft.comboButtons.remove(draft.comboButtons.first!)
        }
    }

    private func startLearning(for buttonIndex: Int) {
        performVM.startNoteLearn(
            buttonIndex: buttonIndex,
            coordinator: coordinator
        ) { note, idx in
            draft.noteToButton = draft.noteToButton.filter { $0.value != idx }
            draft.noteToButton[note] = idx
        }
    }
}

// MARK: - Learn row per button

private struct NoteLearnRow: View {
    let buttonIndex: Int
    @Binding var noteToButton: [UInt8: Int]
    let coordinator: LearnModeCoordinator
    let isConnected: Bool
    let onStartLearn: () -> Void

    private var assignedNote: UInt8? {
        noteToButton.first(where: { $0.value == buttonIndex })?.key
    }
    private var isLearning: Bool {
        coordinator.learningButtonIndex == buttonIndex
    }
    private let buttonColors: [Color] = [.blue, .purple, .orange, .green]

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(buttonColors[buttonIndex].gradient)
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(buttonIndex + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Button \(buttonIndex + 1)")
                    .font(.subheadline)

                Group {
                    if isLearning {
                        if let note = coordinator.capturedNote {
                            Text("Note \(note)  ·  \(noteName(note))  — captured!")
                                .foregroundStyle(.green)
                        } else {
                            Text("Play a note on your controller…")
                                .foregroundStyle(.orange)
                        }
                    } else if let note = assignedNote {
                        Text("Note \(note)  ·  \(noteName(note))")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No note assigned")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }

            Spacer()

            if isLearning {
                Button("Cancel") { coordinator.cancelLearning() }
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Button(isConnected ? "Learn" : "Not connected") {
                    onStartLearn()
                }
                .font(.caption)
                .disabled(!isConnected)

                if assignedNote != nil {
                    Button {
                        noteToButton = noteToButton.filter { $0.value != buttonIndex }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLearning)
        .animation(.easeInOut(duration: 0.2), value: coordinator.capturedNote)
    }

    private func noteName(_ note: UInt8) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = Int(note) / 12 - 1
        return "\(names[Int(note) % 12])\(octave)"
    }
}
