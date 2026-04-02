import Foundation
import Testing
@testable import JamPartnerIOS

@MainActor
@Suite("MappingEngine")
struct MappingEngineTests {
        
        // MARK: - Factory
        
        /// Moteur avec config par défaut et debounce désactivé.
        private func makeEngine(config: MappingConfig = .default) -> (MappingEngine, MockMIDIService) {
                let midiService = MockMIDIService()
                var cfg = config
                cfg.debounceMs = 0
                let engine = MappingEngine(midiService: midiService, config: cfg)
                return (engine, midiService)
        }
        
        // MARK: - Note mapping
        
        // CORRIGÉ : noteToButton n'est plus un `static` sur MappingEngine —
        // on lit maintenant depuis MappingConfig.default.
        @Test("default config maps 4 notes to 4 buttons")
        func noteMapping() {
                let map = MappingConfig.default.noteToButton
                #expect(map[15] == 0)
                #expect(map[25] == 1)
                #expect(map[35] == 2)
                #expect(map[45] == 3)
                #expect(map[99] == nil)
        }
        
        @Test("custom noteToButton is used by engine")
        func customNoteMapping() async throws {
                var config = MappingConfig.default
                config.noteToButton = [60: 0, 62: 1, 64: 2, 65: 3]
                config.debounceMs = 0
                let (engine, _) = makeEngine(config: config)
                var triggeredButton: Int?
                engine.onButtonTriggered = { triggeredButton = $0 }
                
                // Note 60 doit déclencher bouton 0
                engine.handleIncoming(status: 0x90, data1: 60, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                #expect(triggeredButton == 0)
                
                // Ancienne note 15 ne doit plus rien déclencher
                triggeredButton = nil
                engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                #expect(triggeredButton == nil)
        }
        
        @Test("noteToButton can be updated at runtime via config")
        func runtimeNoteRemapping() async throws {
                let (engine, _) = makeEngine()
                var triggeredButton: Int?
                engine.onButtonTriggered = { triggeredButton = $0 }
                
                // Avant remapping : note 15 → bouton 0
                engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                #expect(triggeredButton == 0)
                
                // Remapping à chaud
                var newConfig = MappingConfig.default
                newConfig.noteToButton = [99: 2]
                newConfig.debounceMs = 0
                engine.config = newConfig
                
                triggeredButton = nil
                engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                #expect(triggeredButton == nil, "Note 15 ne doit plus être mappée")
                
                engine.handleIncoming(status: 0x90, data1: 99, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                #expect(triggeredButton == 2, "Note 99 doit déclencher bouton 2")
        }
        
        // MARK: - Trigger / CC
        
        @Test("trigger sends CC for the provided action")
        func triggerSendsCC() async throws {
                let (engine, midi) = makeEngine()
                let action = try #require(ActionCatalog.find("prev_track"))
                
                engine.trigger(action: action)
                try await Task.sleep(for: .milliseconds(50))
                
                #expect(midi.sentCCs.count == 1)
                #expect(midi.sentCCs[0].controller == 20)
                #expect(midi.sentCCs[0].value == 127)
        }
        
        // MARK: - Debounce
        
        @Test("debounce blocks rapid triggers for the same action")
        func debounce() async throws {
                let (engine, midi) = makeEngine()
                let action = try #require(ActionCatalog.find("prev_track"))
                engine.debounceMs = 5000
                
                engine.trigger(action: action)
                try await Task.sleep(for: .milliseconds(50))
                engine.trigger(action: action)
                try await Task.sleep(for: .milliseconds(50))
                
                #expect(midi.sentCCs.count == 1)
        }
        
        @Test("different actions are not debounced against each other")
        func debouncePerAction() async throws {
                let (engine, midi) = makeEngine()
                let firstAction  = try #require(ActionCatalog.find("prev_track"))
                let secondAction = try #require(ActionCatalog.find("next_track"))
                engine.debounceMs = 5000
                
                engine.trigger(action: firstAction)
                try await Task.sleep(for: .milliseconds(50))
                engine.trigger(action: secondAction)
                try await Task.sleep(for: .milliseconds(50))
                
                #expect(midi.sentCCs.count == 2)
        }
        
        @Test("debounce value propagates through config")
        func debounceViaConfig() async throws {
                let (engine, midi) = makeEngine()
                let action = try #require(ActionCatalog.find("play_stop"))
                
                var cfg = engine.config
                cfg.debounceMs = 5000
                engine.config = cfg
                
                engine.trigger(action: action)
                try await Task.sleep(for: .milliseconds(50))
                engine.trigger(action: action)
                try await Task.sleep(for: .milliseconds(50))
                
                #expect(midi.sentCCs.count == 1, "Le debounce via config doit bloquer le second trigger")
        }
        
        // MARK: - Incoming MIDI
        
        @Test("Note On for mapped note requests the matching button")
        func incomingNoteOnRequestsButton() async throws {
                let (engine, _) = makeEngine()
                var triggeredButton: Int?
                engine.onButtonTriggered = { triggeredButton = $0 }
                
                engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
                try await Task.sleep(for: .milliseconds(300))
                
                #expect(triggeredButton == 0)
        }
        
        @Test("Note On for unmapped note does not request a button")
        func incomingUnmappedNote() async throws {
                let (engine, _) = makeEngine()
                var triggeredButton: Int?
                engine.onButtonTriggered = { triggeredButton = $0 }
                
                engine.handleIncoming(status: 0x90, data1: 99, data2: 100)
                try await Task.sleep(for: .milliseconds(300))
                
                #expect(triggeredButton == nil)
        }
        
        @Test("Note Off does not request a button")
        func incomingNoteOff() async throws {
                let (engine, _) = makeEngine()
                var triggered = false
                engine.onButtonTriggered = { _ in triggered = true }
                
                engine.handleIncoming(status: 0x80, data1: 15, data2: 0)
                try await Task.sleep(for: .milliseconds(300))
                
                #expect(!triggered)
        }
        
        @Test("handleIncoming logs CC messages")
        func logsCC() async throws {
                let (engine, _) = makeEngine()
                var logged: [String] = []
                engine.onLog = { logged.append($0) }
                
                engine.handleIncoming(status: 0xB0, data1: 50, data2: 127)
                try await Task.sleep(for: .milliseconds(50))
                
                #expect(logged.contains { $0.contains("CC") && $0.contains("50") })
        }
        
        // MARK: - Combo (boutons par défaut : 0 et 3)
        
        @Test("default combo (buttons 0+3) requests a mode cycle")
        func defaultComboRequestsModeCycle() async throws {
                let (engine, _) = makeEngine()
                var cycleCount = 0
                engine.onCycleModeRequested = { cycleCount += 1 }
                
                engine.handleButtonPress(button: 0)
                engine.handleButtonPress(button: 3)
                try await Task.sleep(for: .milliseconds(200))
                
                #expect(cycleCount == 1)
        }
        
        @Test("single combo button press triggers normally after window expires")
        func singleComboPressTriggersAfterWindow() async throws {
                var config = MappingConfig.default
                config.comboWindowMs = 50   // fenêtre courte pour accélérer le test
                config.debounceMs = 0
                let (engine, _) = makeEngine(config: config)
                var triggeredButton: Int?
                engine.onButtonTriggered = { triggeredButton = $0 }
                
                engine.handleButtonPress(button: 0)
                // Attend que la fenêtre expire sans presser le partenaire
                try await Task.sleep(for: .milliseconds(200))
                
                #expect(triggeredButton == 0, "Bouton 0 seul doit se déclencher normalement")
        }
        
        // MARK: - Combo personnalisé
        
        @Test("custom combo buttons trigger mode cycle")
        func customComboButtons() async throws {
                var config = MappingConfig.default
                config.comboButtons = [1, 2]   // on change le combo pour boutons 1+2
                config.debounceMs = 0
                let (engine, _) = makeEngine(config: config)
                var cycleCount = 0
                var triggeredButtons: [Int] = []
                engine.onCycleModeRequested = { cycleCount += 1 }
                engine.onButtonTriggered   = { triggeredButtons.append($0) }
                
                // Ancien combo 0+3 ne doit pas déclencher de cycle
                engine.handleButtonPress(button: 0)
                engine.handleButtonPress(button: 3)
                try await Task.sleep(for: .milliseconds(200))
                #expect(cycleCount == 0, "L'ancien combo ne doit plus fonctionner")
                #expect(triggeredButtons.contains(0))
                #expect(triggeredButtons.contains(3))
                
                // Nouveau combo 1+2 doit déclencher le cycle
                engine.handleButtonPress(button: 1)
                engine.handleButtonPress(button: 2)
                try await Task.sleep(for: .milliseconds(200))
                #expect(cycleCount == 1, "Le nouveau combo doit déclencher le cycle")
        }
        
        @Test("combo updated at runtime is immediately effective")
        func runtimeComboUpdate() async throws {
                let (engine, _) = makeEngine()   // combo par défaut : [0, 3]
                var cycleCount = 0
                engine.onCycleModeRequested = { cycleCount += 1 }
                
                // Changement à chaud → nouveau combo [1, 2]
                var newConfig = MappingConfig.default
                newConfig.comboButtons = [1, 2]
                newConfig.debounceMs = 0
                engine.config = newConfig
                
                engine.handleButtonPress(button: 1)
                engine.handleButtonPress(button: 2)
                try await Task.sleep(for: .milliseconds(200))
                #expect(cycleCount == 1)
        }
        
        @Test("custom combo window is respected")
        func customComboWindow() async throws {
                var config = MappingConfig.default
                config.comboWindowMs = 30   // fenêtre très courte
                config.debounceMs = 0
                let (engine, _) = makeEngine(config: config)
                var cycleCount = 0
                engine.onCycleModeRequested = { cycleCount += 1 }
                
                engine.handleButtonPress(button: 0)
                // Attente > fenêtre avant de presser le partenaire
                try await Task.sleep(for: .milliseconds(100))
                engine.handleButtonPress(button: 3)
                try await Task.sleep(for: .milliseconds(100))
                
                #expect(cycleCount == 0, "Hors fenêtre : pas de cycle")
        }
}
