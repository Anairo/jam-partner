//
//  MappingConfigTests.swift
//  JamPartnerIOSTests
//
//  Created by Perez William on 02/04/2026.
//

import Testing
import Foundation
@testable import JamPartnerIOS

@Suite("MappingConfig")
struct MappingConfigTests {

    // MARK: - Valeurs par défaut

    @Test("default config has combo buttons 0 and 3")
    func defaultComboButtons() {
        #expect(MappingConfig.default.comboButtons == [0, 3])
    }

    @Test("default config has 4 note mappings")
    func defaultNoteMappings() {
        let map = MappingConfig.default.noteToButton
        #expect(map.count == 4)
        #expect(map[15] == 0)
        #expect(map[25] == 1)
        #expect(map[35] == 2)
        #expect(map[45] == 3)
    }

    @Test("default config has positive comboWindowMs")
    func defaultComboWindow() {
        #expect(MappingConfig.default.comboWindowMs > 0)
    }

    @Test("default config is valid")
    func defaultIsValid() {
        #expect(MappingConfig.default.isValid)
    }

    // MARK: - Validation

    @Test("config with 1 combo button is invalid")
    func invalidComboOneButton() {
        var config = MappingConfig.default
        config.comboButtons = [0]
        #expect(!config.isValid)
    }

    @Test("config with 3 combo buttons is invalid")
    func invalidComboThreeButtons() {
        var config = MappingConfig.default
        config.comboButtons = [0, 1, 2]
        #expect(!config.isValid)
    }

    @Test("config with out-of-range combo button is invalid")
    func invalidComboOutOfRange() {
        var config = MappingConfig.default
        config.comboButtons = [0, 99]
        #expect(!config.isValid)
    }

    @Test("config with negative comboWindowMs is invalid")
    func invalidNegativeWindow() {
        var config = MappingConfig.default
        config.comboWindowMs = -1
        #expect(!config.isValid)
    }

    @Test("config with out-of-range note target is invalid")
    func invalidNoteTarget() {
        var config = MappingConfig.default
        config.noteToButton[60] = 99   // bouton 99 n'existe pas
        #expect(!config.isValid)
    }

    @Test("config with valid custom values is valid")
    func validCustomConfig() {
        let config = MappingConfig(
            comboButtons:  [1, 2],
            comboWindowMs: 200,
            noteToButton:  [60: 0, 62: 1, 64: 2, 65: 3],
            debounceMs:    100
        )
        #expect(config.isValid)
    }

    // MARK: - Codable

    @Test("MappingConfig survives JSON round-trip")
    func codableRoundTrip() throws {
        let original = MappingConfig(
            comboButtons:  [1, 2],
            comboWindowMs: 200,
            noteToButton:  [60: 0, 62: 1],
            debounceMs:    300
        )
        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MappingConfig.self, from: data)

        #expect(decoded.comboButtons  == original.comboButtons)
        #expect(decoded.comboWindowMs == original.comboWindowMs)
        #expect(decoded.debounceMs    == original.debounceMs)
        #expect(decoded.noteToButton  == original.noteToButton)
    }

    @Test("default config survives JSON round-trip")
    func defaultCodableRoundTrip() throws {
        let data    = try JSONEncoder().encode(MappingConfig.default)
        let decoded = try JSONDecoder().decode(MappingConfig.self, from: data)
        #expect(decoded == MappingConfig.default)
    }
}
