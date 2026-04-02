//
//  MappingConfig.swift
//  JamPartnerIOS
//
//  Created by Perez William on 02/04/2026.
//
import Foundation

/// Toute la configuration de MappingEngine en un seul objet persistable.

struct MappingConfig: Codable, Equatable {

    // MARK: - Combo de changement de mode

    /// Les indices de boutons à presser simultanément pour cycler de mode.
    /// Défaut : boutons 0 et 3 (coins opposés d'une grille 2×2).
    /// Doit contenir exactement 2 éléments — validé à l'init.
    var comboButtons: Set<Int>

    /// Fenêtre de temps (ms) pendant laquelle les deux boutons du combo
    /// doivent être pressés pour déclencher le cycle de mode.
    var comboWindowMs: Double

    // MARK: - Mapping note → bouton (entrée BLE MIDI)

    /// Traduit une note MIDI entrante en index de bouton (0–3).
    /// Clé = note MIDI (0–127), valeur = index bouton.
    /// Défaut : notes 15/25/35/45 → boutons 0/1/2/3.
    var noteToButton: [UInt8: Int]

    // MARK: - Debounce

    /// Temps minimum (ms) entre deux déclenchements du même bouton.
    var debounceMs: Double

    // MARK: - Valeurs par défaut

    static let `default` = MappingConfig(
        comboButtons:  [0, 3],
        comboWindowMs: 150,
        noteToButton:  [15: 0, 25: 1, 35: 2, 45: 3],
        debounceMs:    250
    )

    // MARK: - Validation

    /// Retourne true si la config est utilisable par MappingEngine.
    var isValid: Bool {
        comboButtons.count == 2
        && comboButtons.allSatisfy { $0 >= 0 && $0 < 4 }
        && comboWindowMs > 0
        && debounceMs >= 0
        && noteToButton.values.allSatisfy { $0 >= 0 && $0 < 4 }
    }
}
