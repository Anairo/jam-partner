//
//  ModeManager.swift
//  JamPartnerIOS
//
//  Created by Perez William on 01/04/2026.
//

import Foundation

private let modesKey       = "savedModes"
private let currentModeKey = "currentModeIndex"
private let mappingKey     = "savedMappingConfig"  // nouveau

@MainActor
@Observable
final class ModeManager {
        
        // MARK: - Modes
        
        var modes: [ButtonMode] = []
        var currentModeIndex: Int = 0
        
        var currentMode: ButtonMode {
                modes[currentModeIndex]
        }
        
        // MARK: - Configuration de mapping (combo, notes, debounce)
        
        /// Modifiable depuis l'UI via un SettingsView — persisté automatiquement.
        var mappingConfig: MappingConfig = .default {
                didSet { save() }
        }
        
        // MARK: - Init
        
        private let defaults: UserDefaults
        
        init(defaults: UserDefaults = .standard) {
                self.defaults = defaults
                
                // Chargement des modes
                if let data = defaults.data(forKey: modesKey),
                   let saved = try? JSONDecoder().decode([ButtonMode].self, from: data),
                   !saved.isEmpty {
                        modes = saved
                        currentModeIndex = min(
                                defaults.integer(forKey: currentModeKey),
                                saved.count - 1
                        )
                } else {
                        modes = Self.defaultModes
                }
                
                // Chargement de la config de mapping
                if let data = defaults.data(forKey: mappingKey),
                   let saved = try? JSONDecoder().decode(MappingConfig.self, from: data),
                   saved.isValid {
                        mappingConfig = saved
                }
        }
        
        // MARK: - Gestion des modes
        
        func selectMode(at index: Int) {
                guard index >= 0 && index < modes.count else { return }
                currentModeIndex = index
                save()
        }
        
        func cycleMode() {
                currentModeIndex = (currentModeIndex + 1) % modes.count
                save()
        }
        
        func actionForButton(_ index: Int) -> Action? {
                guard index < currentMode.actions.count else { return nil }
                return ActionCatalog.find(currentMode.actions[index])
        }
        
        func updateMode(at index: Int, mode: ButtonMode) {
                modes[index] = mode
                save()
        }
        
        func addMode(_ mode: ButtonMode) {
                modes.append(mode)
                save()
        }
        
        func removeMode(at index: Int) {
                guard modes.count > 1 else { return }
                modes.remove(at: index)
                if currentModeIndex >= modes.count {
                        currentModeIndex = modes.count - 1
                }
                save()
        }
        
        // MARK: - Persistance
        
        private func save() {
                if let data = try? JSONEncoder().encode(modes) {
                        defaults.set(data, forKey: modesKey)
                }
                defaults.set(currentModeIndex, forKey: currentModeKey)
                
                if let data = try? JSONEncoder().encode(mappingConfig) {
                        defaults.set(data, forKey: mappingKey)
                }
        }
        
        // MARK: - Defaults
        
        static let defaultModes: [ButtonMode] = [
                ButtonMode(id: UUID(), name: "Navigate",
                           actions: ["prev_track", "next_track", "scene_up", "scene_down"]),
                ButtonMode(id: UUID(), name: "Looper",
                           actions: ["fire_clip", "stop_clip", "arm_track", "overdub"]),
                ButtonMode(id: UUID(), name: "Launch",
                           actions: ["launch_scene", "stop_all", "play_stop", "record"]),
        ]
}
