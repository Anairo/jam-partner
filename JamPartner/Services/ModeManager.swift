import Foundation

private let modesKey = "savedModes"
private let currentModeKey = "currentModeIndex"

@Observable
@MainActor
class ModeManager {
    var modes: [ButtonMode] = []
    var currentModeIndex: Int = 0

    private let defaults: UserDefaults

    var currentMode: ButtonMode {
        modes[currentModeIndex]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

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
    }

    func cycleMode() {
        currentModeIndex = (currentModeIndex + 1) % modes.count
        save()
    }

    func actionForButton(_ index: Int) -> Action? {
        guard currentMode.actions.indices.contains(index) else { return nil }
        return ActionCatalog.find(currentMode.actions[index])
    }

    func updateMode(at index: Int, mode: ButtonMode) {
        guard modes.indices.contains(index) else { return }
        modes[index] = mode
        save()
    }

    func addMode(_ mode: ButtonMode) {
        modes.append(mode)
        save()
    }

    func removeMode(at index: Int) {
        guard modes.count > 1, modes.indices.contains(index) else { return }
        modes.remove(at: index)
        if currentModeIndex >= modes.count {
            currentModeIndex = modes.count - 1
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(modes) {
            defaults.set(data, forKey: modesKey)
        }
        defaults.set(currentModeIndex, forKey: currentModeKey)
    }

    static let defaultModes: [ButtonMode] = [
        ButtonMode(id: UUID(), name: "Navigate",
                   actions: ["prev_track", "next_track", "scene_up", "scene_down"]),
        ButtonMode(id: UUID(), name: "Looper",
                   actions: ["fire_clip", "stop_clip", "arm_track", "overdub"]),
        ButtonMode(id: UUID(), name: "Launch",
                   actions: ["launch_scene", "stop_all", "play_stop", "record"]),
    ]
}
