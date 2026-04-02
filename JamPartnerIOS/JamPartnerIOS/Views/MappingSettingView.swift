//
//  MappingSettingView.swift
//  JamPartnerIOS
//
//  Created by Perez William on 02/04/2026.
//

import SwiftUI

/// Écran de configuration du mapping BLE → MIDI.
/// Accessible depuis ContentView via un NavigationLink "Réglages".
struct MappingSettingsView: View {
        @Environment(ModeManager.self) private var modeManager
        @Environment(PerformViewModel.self) private var performVM
        
        // Copie locale pour édition — appliquée à la sauvegarde
        @State private var draft: MappingConfig = .default
        @State private var showResetAlert = false
        
        var body: some View {
                @Bindable var mm = modeManager
                
                Form {
                        
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
                                                .frame(width: 140)
                                        Text("\(Int(draft.comboWindowMs)) ms")
                                                .font(.caption.monospacedDigit())
                                                .frame(width: 52, alignment: .trailing)
                                }
                        } header: {
                                Text("Combo de mode")
                        }
                        
                        // MARK: Mapping notes BLE → boutons
                        Section {
                                Text("Note MIDI reçue via BLE qui déclenche chaque bouton.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                
                                ForEach(0..<4, id: \.self) { buttonIndex in
                                        NotePickerRow(
                                                buttonIndex: buttonIndex,
                                                noteToButton: $draft.noteToButton
                                        )
                                }
                        } header: {
                                Text("Notes BLE → boutons")
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
                                Button(role: .destructive) {
                                        showResetAlert = true
                                } label: {
                                        Text("Rétablir les réglages par défaut")
                                }
                        }
                }
                .navigationTitle("Réglages du mapping")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                        draft = modeManager.mappingConfig
                }
                .onChange(of: draft) { _, newValue in
                        guard newValue.isValid else { return }
                        modeManager.mappingConfig = newValue
                        // Propage immédiatement au moteur sans recréer PerformViewModel
                        performVM.applyMappingConfig(newValue)
                }
                .alert("Rétablir les réglages ?", isPresented: $showResetAlert) {
                        Button("Rétablir", role: .destructive) {
                                draft = .default
                        }
                        Button("Annuler", role: .cancel) {}
                } message: {
                        Text("Les réglages de combo, notes et debounce seront remis à zéro.")
                }
        }
}

// MARK: - Sous-vue : sélecteur de combo (grille 2×2)

private struct ComboPickerView: View {
        @Binding var selected: Set<Int>
        
        private let labels = ["1", "2", "3", "4"]
        private let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        var body: some View {
                LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<4, id: \.self) { index in
                                let isSelected = selected.contains(index)
                                Button {
                                        toggle(index)
                                } label: {
                                        Text("Bouton \(labels[index])")
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
                        // On ne peut pas désélectionner si on n'a qu'un seul sélectionné
                        guard selected.count > 1 else { return }
                        selected.remove(index)
                        // Garde exactement 2 éléments
                        while selected.count > 2 { selected.remove(selected.first!) }
                } else {
                        selected.insert(index)
                        while selected.count > 2 { selected.remove(selected.first!) }
                }
        }
}

// MARK: - Sous-vue : sélecteur de note par bouton

private struct NotePickerRow: View {
        let buttonIndex: Int
        @Binding var noteToButton: [UInt8: Int]
        
        // Note actuellement assignée à ce bouton (nil si aucune)
        private var currentNote: UInt8? {
                noteToButton.first(where: { $0.value == buttonIndex })?.key
        }
        
        var body: some View {
                Picker("Bouton \(buttonIndex + 1)", selection: noteBinding) {
                        Text("Aucune").tag(UInt8?.none)
                        ForEach(UInt8(0)...UInt8(127), id: \.self) { note in
                                Text("Note \(note)").tag(UInt8?.some(note))
                        }
                }
        }
        
        private var noteBinding: Binding<UInt8?> {
                Binding(
                        get: { currentNote },
                        set: { newNote in
                                // Retire l'ancienne assignation de ce bouton
                                noteToButton = noteToButton.filter { $0.value != buttonIndex }
                                // Ajoute la nouvelle
                                if let note = newNote {
                                        noteToButton[note] = buttonIndex
                                }
                        }
                )
        }
}
