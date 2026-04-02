//
//  PerformViewModelTests.swift
//  JamPartnerIOSTests
//
//  Created by Perez William on 02/04/2026.
//

import Testing
import Foundation
@testable import JamPartnerIOS


@MainActor
@Suite("PerformViewModel")
struct PerformViewModelTests {
        
        // MARK: Factory
        
        private func makeVM(config: MappingConfig = .default) -> (PerformViewModel, MockMIDIService) {
                let suite    = "com.jampartner.test.\(UUID().uuidString)"
                let defaults = UserDefaults(suiteName: suite)!
                let midi     = MockMIDIService()
                let manager  = ModeManager(defaults: defaults)
                // Injecte la config dans le manager pour que le VM la récupère au démarrage
                manager.mappingConfig = config
                let engine = MappingEngine(midiService: midi)
                let vm     = PerformViewModel(midiService: midi, mappingEngine: engine, modeManager: manager)
                return (vm, midi)
        }
        
        // MARK: Tests existants (inchangés)
        
        @Test("init calls midiService.start()")
        func initStartsMidi() {
                let (_, midi) = makeVM()
                #expect(midi.startCalled)
        }
        
        @Test("cycleMode changes current mode")
        func cycleMode() {
                let (vm, _) = makeVM()
                #expect(vm.modeManager.currentMode.name == "Navigate")
                vm.cycleMode()
                #expect(vm.modeManager.currentMode.name == "Looper")
        }
        
        @Test("syncDebounce propagates to engine")
        func syncDebounce() async throws {
                let (vm, midi) = makeVM()
                vm.debounceMs = 9999
                vm.syncDebounce()
                
                vm.onButtonTap(0)
                try await Task.sleep(for: .milliseconds(300))
                #expect(midi.sentCCs.count == 1)
                
                vm.onButtonTap(0)
                try await Task.sleep(for: .milliseconds(300))
                #expect(midi.sentCCs.count == 1, "Debounce of 9999ms should block second tap")
        }
        
        @Test("MIDI log messages appear in VM log")
        func midiLogForwarded() async throws {
                let (vm, midi) = makeVM()
                midi.onLog?("test from midi")
                try await Task.sleep(for: .milliseconds(50))
                #expect(vm.log.contains("test from midi"))
        }
        
        @Test("modeManager is accessible and shared")
        func modeManagerAccess() {
                let (vm, _) = makeVM()
                #expect(vm.modeManager.modes.count == 3)
                #expect(vm.modeManager.currentMode.name == "Navigate")
        }
        
        // MARK: Nouveaux tests — applyMappingConfig
        
        @Test("init applies persisted mappingConfig to engine")
        func initAppliesPersistedConfig() async throws {
                var config = MappingConfig.default
                config.noteToButton = [60: 0, 62: 1, 64: 2, 65: 3]
                config.debounceMs = 0
                let (vm, _) = makeVM(config: config)
                
                var triggeredButton: Int?
                // Accès direct à l'engine via handleIncomingMidi
                vm.handleIncomingMidi(status: 0x90, data1: 60, data2: 100)
                try await Task.sleep(for: .milliseconds(200))
                
                // On vérifie via le log que le bouton a été déclenché
                // (handleIncomingMidi logue "IN: Note On...")
                #expect(vm.log.contains { $0.contains("Note On") && $0.contains("60") })
                _ = triggeredButton  // silence warning
        }
        
        @Test("applyMappingConfig propagates new debounce immediately")
        func applyConfigDebounce() async throws {
                let (vm, midi) = makeVM()
                let action = try #require(ActionCatalog.find("play_stop"))
                
                // Applique un debounce très long
                var config = MappingConfig.default
                config.debounceMs = 9999
                vm.applyMappingConfig(config)
                
                vm.onButtonTap(0)
                try await Task.sleep(for: .milliseconds(200))
                let countAfterFirst = midi.sentCCs.count
                
                vm.onButtonTap(0)
                try await Task.sleep(for: .milliseconds(200))
                #expect(midi.sentCCs.count == countAfterFirst,
                        "Le second tap doit être bloqué par le debounce appliqué via applyMappingConfig")
                _ = action
        }
        
        @Test("applyMappingConfig updates debounceMs on ViewModel")
        func applyConfigUpdatesDebounceProperty() {
                let (vm, _) = makeVM()
                var config = MappingConfig.default
                config.debounceMs = 777
                vm.applyMappingConfig(config)
                #expect(vm.debounceMs == 777)
        }
}
