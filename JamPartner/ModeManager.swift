//
//  ModeManager.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import Foundation

struct ButtonMode: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var actions: [String]

    func label(for buttonIndex: Int) -> String {
        guard buttonIndex < actions.count,
              let action = ActionCatalog.find(actions[buttonIndex]) else {
            return "---"
        }
        return action.label
    }
}

private let modesKey = "savedModes"
private let currentModeKey = "currentModeIndex"

@Observable
class ModeManager {
    var modes: [ButtonMode] = []
    var currentModeIndex: Int = 0

    var currentMode: ButtonMode {
        modes[currentModeIndex]
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: modesKey),
           let saved = try? JSONDecoder().decode([ButtonMode].self, from: data),
           !saved.isEmpty {
            modes = saved
            currentModeIndex = min(
                UserDefaults.standard.integer(forKey: currentModeKey),
                saved.count - 1
            )
        } else {
            modes = Self.defaultModes
        }
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

    private func save() {
        if let data = try? JSONEncoder().encode(modes) {
            UserDefaults.standard.set(data, forKey: modesKey)
        }
        UserDefaults.standard.set(currentModeIndex, forKey: currentModeKey)
    }

    static let defaultModes: [ButtonMode] = [
        ButtonMode(
            id: UUID(),
            name: "Navigate",
            actions: ["prev_track", "next_track", "scene_up", "scene_down"]
        ),
        ButtonMode(
            id: UUID(),
            name: "Looper",
            actions: ["fire_clip", "stop_clip", "arm_track", "overdub"]
        ),
        ButtonMode(
            id: UUID(),
            name: "Launch",
            actions: ["launch_scene", "stop_all", "play_stop", "record"]
        ),
    ]
}
