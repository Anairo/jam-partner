import Testing
import Foundation
@testable import JamPartnerIOS

@Suite("ModeManager")
struct ModeManagerTests {

    private func makeFreshManager() -> ModeManager {
        let suite = "com.jampartner.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return ModeManager(defaults: defaults)
    }

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
}
