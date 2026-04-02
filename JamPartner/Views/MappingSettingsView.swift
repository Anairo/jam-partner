import SwiftUI

struct MappingSettingsView: View {
    @Environment(ModeManager.self) private var modeManager
    @Environment(PerformViewModel.self) private var performVM

    @State private var draft: MappingConfig = .default

    var body: some View {
        VStack(spacing: 14) {
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

            GroupBox("BLE Notes -> Buttons") {
                VStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { button in
                        HStack {
                            Text("Button \(button + 1)")
                                .frame(width: 70, alignment: .leading)
                            Picker("", selection: noteBinding(for: button)) {
                                ForEach(0...127, id: \.self) { note in
                                    Text("Note \(note)").tag(note)
                                }
                            }
                            .frame(width: 160)
                        }
                    }
                }
            }

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
                    draft = .default
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 430, height: 380)
        .onAppear {
            draft = modeManager.mappingConfig
        }
        .onChange(of: draft) {
            guard draft.isValid else { return }
            modeManager.mappingConfig = draft
            performVM.applyMappingConfig(draft)
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

    private func noteBinding(for button: Int) -> Binding<Int> {
        Binding(
            get: {
                Int(draft.noteToButton.first(where: { $0.value == button })?.key ?? 0)
            },
            set: { selectedNote in
                draft.noteToButton = draft.noteToButton.filter { $0.value != button }
                draft.noteToButton[UInt8(selectedNote)] = button
            }
        )
    }
}
