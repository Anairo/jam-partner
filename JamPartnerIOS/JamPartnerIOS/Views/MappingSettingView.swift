//
//  MappingSettingView.swift
//  JamPartnerIOS
//
//  Created by Perez William on 02/04/2026.
//

import SwiftUI

/// Écran de configuration du mapping BLE → MIDI sur iOS.
///

struct MappingSettingsView: View {
        @Environment(ModeManager.self)         private var modeManager
        @Environment(PerformViewModel.self)    private var performVM
        @Environment(ConnectionViewModel.self) private var connectionVM
        
        @State private var draft          = MappingConfig.default
        @State private var showResetAlert = false
        @State private var coordinator    = LearnModeCoordinator()
        
        private var isConnected: Bool { connectionVM.isConnected }
        
        var body: some View {
                Form {
                        
                        // MARK: Notes BLE → boutons
                        Section {
                                if !isConnected {
                                        Label(
                                                "Connectez un contrôleur BLE pour utiliser le mode apprentissage.",
                                                systemImage: "antenna.radiowaves.left.and.right"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                ForEach(0..<4, id: \.self) { index in
                                        NoteLearnRow(
                                                buttonIndex:  index,
                                                noteToButton: $draft.noteToButton,
                                                coordinator:  coordinator,
                                                isConnected:  isConnected,
                                                onStartLearn: { startLearning(for: index) }
                                        )
                                }
                        } header: {
                                Text("Notes BLE → boutons")
                        } footer: {
                                Text("Appuyez sur \"Apprendre\" puis jouez une note sur votre contrôleur.")
                        }
                        
                        // MARK: Combo de changement de mode
                        Section {
                                VStack(alignment: .leading, spacing: 12) {
                                        Text("Appuyez simultanément sur deux boutons pour changer de mode.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        ComboPickerView(selected: $draft.comboButtons)
                                }
                                .padding(.vertical, 4)
                                
                                HStack {
                                        Text("Fenêtre de détection")
                                        Spacer()
                                        Slider(value: $draft.comboWindowMs, in: 50...500, step: 25)
                                                .frame(width: 130)
                                        Text("\(Int(draft.comboWindowMs)) ms")
                                                .font(.caption.monospacedDigit())
                                                .frame(width: 52, alignment: .trailing)
                                }
                        } header: {
                                Text("Combo de mode")
                        }
                        
                        // MARK: Debounce
                        Section {
                                HStack {
                                        Slider(value: $draft.debounceMs, in: 50...800, step: 10)
                                        Text("\(Int(draft.debounceMs)) ms")
                                                .font(.caption.monospacedDigit())
                                                .frame(width: 52, alignment: .trailing)
                                }
                        } header: {
                                Text("Debounce")
                        } footer: {
                                Text("Temps minimum entre deux déclenchements du même bouton.")
                        }
                        
                        // MARK: Reset
                        Section {
                                Button(role: .destructive) { showResetAlert = true } label: {
                                        Text("Rétablir les réglages par défaut")
                                }
                        }
                }
                .navigationTitle("Réglages du mapping")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear    { draft = modeManager.mappingConfig }
                .onDisappear { coordinator.cancelLearning() }
                .onChange(of: draft) { _, newValue in
                        guard newValue.isValid else { return }
                        modeManager.mappingConfig = newValue
                        performVM.applyMappingConfig(newValue)
                }
                .alert("Rétablir les réglages ?", isPresented: $showResetAlert) {
                        Button("Rétablir", role: .destructive) { draft = .default }
                        Button("Annuler", role: .cancel) {}
                } message: {
                        Text("Les réglages de combo, notes et debounce seront remis à zéro.")
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

// MARK: - Ligne d'apprentissage par bouton

private struct NoteLearnRow: View {
        let buttonIndex:  Int
        @Binding var noteToButton: [UInt8: Int]
        let coordinator:  LearnModeCoordinator
        let isConnected:  Bool
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
                                .frame(width: 32, height: 32)
                                .overlay(
                                        Text("\(buttonIndex + 1)")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                )
                        
                        VStack(alignment: .leading, spacing: 2) {
                                Text("Bouton \(buttonIndex + 1)")
                                        .font(.subheadline)
                                
                                Group {
                                        if isLearning {
                                                if let note = coordinator.capturedNote {
                                                        Text("Note \(note)  ·  \(noteName(note))  — enregistrée !")
                                                                .foregroundStyle(.green)
                                                } else {
                                                        Text("Jouez une note sur le contrôleur…")
                                                                .foregroundStyle(.orange)
                                                }
                                        } else if let note = assignedNote {
                                                Text("Note \(note)  ·  \(noteName(note))")
                                                        .foregroundStyle(.secondary)
                                        } else {
                                                Text("Aucune note assignée")
                                                        .foregroundStyle(.secondary)
                                        }
                                }
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        if isLearning {
                                Button("Annuler") { coordinator.cancelLearning() }
                                        .font(.caption)
                                        .foregroundStyle(.red)
                        } else {
                                Button(isConnected ? "Apprendre" : "Non connecté") {
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
        
        /// Convertit un numéro MIDI en notation musicale iOS : 60 → "C4", 69 → "A4"
        private func noteName(_ note: UInt8) -> String {
                let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
                let octave = Int(note) / 12 - 1
                return "\(names[Int(note) % 12])\(octave)"
        }
}

// MARK: - Sélecteur de combo

private struct ComboPickerView: View {
        @Binding var selected: Set<Int>
        
        private let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        var body: some View {
                LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<4, id: \.self) { index in
                                let isSelected = selected.contains(index)
                                Button { toggle(index) } label: {
                                        Text("Bouton \(index + 1)")
                                                .font(.subheadline.weight(isSelected ? .bold : .regular))
                                                .frame(maxWidth: .infinity, minHeight: 44)
                                                .background(
                                                        isSelected
                                                        ? Color.accentColor.opacity(0.15)
                                                        : Color(.secondarySystemBackground)
                                                )
                                                .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                        }
                }
        }
        
        private func toggle(_ index: Int) {
                if selected.contains(index) {
                        guard selected.count > 1 else { return }
                        selected.remove(index)
                        while selected.count > 2 { selected.remove(selected.first!) }
                } else {
                        selected.insert(index)
                        while selected.count > 2 { selected.remove(selected.first!) }
                }
        }
}
