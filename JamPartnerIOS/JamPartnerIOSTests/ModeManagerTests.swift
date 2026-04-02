import Testing
import Foundation
@testable import JamPartnerIOS

@MainActor
@Suite("ModeManager")
struct ModeManagerTests {
        
        // MARK: - Factory
        
        private func makeFreshManager() -> ModeManager {
                let suite = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                return ModeManager(defaults: defaults)
        }
        
        // Retourne (manager, même suite UserDefaults) pour tester la persistance
        private func makePersistentManager() -> (ModeManager, UserDefaults) {
                let suite = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                return (ModeManager(defaults: defaults), defaults)
        }
        
        // MARK: - Modes (tests inchangés)
        
        @Test("init loads 3 default modes")
        func defaultModes() {
                let manager = makeFreshManager()
                #expect(manager.modes.count == 3)
                #expect(manager.modes[0].name == "Navigate")
                #expect(manager.modes[1].name == "Looper")
                #expect(manager.modes[2].name == "Launch")
        }
        
        @Test("currentMode starts at index 0")
        func initialIndex() {
                let manager = makeFreshManager()
                #expect(manager.currentModeIndex == 0)
                #expect(manager.currentMode.name == "Navigate")
        }
        
        @Test("cycleMode advances and wraps around")
        func cycle() {
                let manager = makeFreshManager()
                manager.cycleMode()
                #expect(manager.currentModeIndex == 1)
                #expect(manager.currentMode.name == "Looper")
                
                manager.cycleMode()
                #expect(manager.currentModeIndex == 2)
                
                manager.cycleMode()
                #expect(manager.currentModeIndex == 0, "Should wrap back to 0")
        }
        
        @Test("addMode appends a new mode")
        func addMode() {
                let manager = makeFreshManager()
                let newMode = ButtonMode(id: UUID(), name: "Custom", actions: ["undo", "undo", "undo", "undo"])
                manager.addMode(newMode)
                #expect(manager.modes.count == 4)
                #expect(manager.modes.last?.name == "Custom")
        }
        
        @Test("removeMode removes a mode but keeps at least one")
        func removeMode() {
                let manager = makeFreshManager()
                manager.removeMode(at: 2)
                #expect(manager.modes.count == 2)
                
                manager.removeMode(at: 1)
                #expect(manager.modes.count == 1)
                
                manager.removeMode(at: 0)
                #expect(manager.modes.count == 1, "Should not remove the last mode")
        }
        
        @Test("removeMode adjusts currentModeIndex if needed")
        func removeModeAdjustsIndex() {
                let manager = makeFreshManager()
                manager.cycleMode()
                manager.cycleMode()
                #expect(manager.currentModeIndex == 2)
                
                manager.removeMode(at: 2)
                #expect(manager.currentModeIndex == 1, "Index should clamp to modes.count - 1")
        }
        
        @Test("updateMode replaces mode at index")
        func updateMode() {
                let manager = makeFreshManager()
                var mode = manager.modes[0]
                mode.name = "Renamed"
                manager.updateMode(at: 0, mode: mode)
                #expect(manager.modes[0].name == "Renamed")
        }
        
        @Test("actionForButton returns correct action")
        func actionForButton() {
                let manager = makeFreshManager()
                let action = manager.actionForButton(0)
                #expect(action?.id == "prev_track")
                #expect(action?.cc == 20)
        }
        
        @Test("actionForButton returns nil for out-of-bounds")
        func actionForButtonOutOfBounds() {
                let manager = makeFreshManager()
                #expect(manager.actionForButton(99) == nil)
        }
        
        // MARK: - MappingConfig (nouveaux tests)
        
        @Test("init loads default mappingConfig when nothing is persisted")
        func defaultMappingConfig() {
                let manager = makeFreshManager()
                #expect(manager.mappingConfig == MappingConfig.default)
        }
        
        @Test("mappingConfig is persisted and reloaded")
        func mappingConfigPersistence() {
                let suite = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                
                // Sauvegarde d'une config personnalisée
                let manager1 = ModeManager(defaults: defaults)
                var custom = MappingConfig.default
                custom.comboButtons  = [1, 2]
                custom.comboWindowMs = 300
                custom.debounceMs    = 400
                manager1.mappingConfig = custom
                
                // Rechargement depuis le même UserDefaults
                let manager2 = ModeManager(defaults: defaults)
                #expect(manager2.mappingConfig.comboButtons  == [1, 2])
                #expect(manager2.mappingConfig.comboWindowMs == 300)
                #expect(manager2.mappingConfig.debounceMs    == 400)
        }
        
        @Test("invalid persisted mappingConfig falls back to default")
        func invalidPersistedConfigFallback() throws {
                let suite = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                
                // On persiste délibérément une config invalide (JSON malformé)
                defaults.set("not valid json".data(using: .utf8), forKey: "savedMappingConfig")
                
                let manager = ModeManager(defaults: defaults)
                #expect(manager.mappingConfig == MappingConfig.default,
                        "Une config invalide doit tomber sur le défaut")
        }
        
        @Test("updating mappingConfig triggers save")
        func mappingConfigSaveOnUpdate() {
                let suite = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                let manager = ModeManager(defaults: defaults)
                
                var custom = MappingConfig.default
                custom.comboButtons = [0, 1]
                manager.mappingConfig = custom
                
                // Vérifie que UserDefaults contient bien quelque chose
                let data = defaults.data(forKey: "savedMappingConfig")
                #expect(data != nil, "La config doit être écrite dans UserDefaults")
                
                // Et que c'est décodable
                let decoded = try? JSONDecoder().decode(MappingConfig.self, from: data!)
                #expect(decoded?.comboButtons == [0, 1])
        }
}
