import Foundation
import Testing
@testable import JamPartner

@MainActor
@Suite("MappingEngine")
struct MappingEngineTests {

    private func makeEngine() -> (MappingEngine, MockMIDIService) {
        let midiService = MockMIDIService()
        let engine = MappingEngine(midiService: midiService)
        engine.debounceMs = 0
        return (engine, midiService)
    }

    @Test("noteToButton maps 4 notes to 4 buttons")
    func noteMapping() {
        #expect(MappingEngine.noteToButton[15] == 0)
        #expect(MappingEngine.noteToButton[25] == 1)
        #expect(MappingEngine.noteToButton[35] == 2)
        #expect(MappingEngine.noteToButton[45] == 3)
        #expect(MappingEngine.noteToButton[99] == nil)
    }

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
        let firstAction = try #require(ActionCatalog.find("prev_track"))
        let secondAction = try #require(ActionCatalog.find("next_track"))
        engine.debounceMs = 5000

        engine.trigger(action: firstAction)
        try await Task.sleep(for: .milliseconds(50))
        engine.trigger(action: secondAction)
        try await Task.sleep(for: .milliseconds(50))

        #expect(midi.sentCCs.count == 2)
    }

    @Test("Note On for mapped note requests the matching button")
    func incomingNoteOnRequestsButton() async throws {
        let (engine, _) = makeEngine()
        var triggeredButton: Int?

        engine.onButtonTriggered = { button in
            triggeredButton = button
        }

        engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
        try await Task.sleep(for: .milliseconds(300))

        #expect(triggeredButton == 0)
    }

    @Test("Note On for unmapped note does not request a button")
    func incomingUnmappedNote() async throws {
        let (engine, _) = makeEngine()
        var triggeredButton: Int?

        engine.onButtonTriggered = { button in
            triggeredButton = button
        }

        engine.handleIncoming(status: 0x90, data1: 99, data2: 100)
        try await Task.sleep(for: .milliseconds(300))

        #expect(triggeredButton == nil)
    }

    @Test("Note Off does not request a button")
    func incomingNoteOff() async throws {
        let (engine, _) = makeEngine()
        var triggered = false

        engine.onButtonTriggered = { _ in
            triggered = true
        }

        engine.handleIncoming(status: 0x80, data1: 15, data2: 0)
        try await Task.sleep(for: .milliseconds(300))

        #expect(!triggered)
    }

    @Test("combo button press requests a mode cycle")
    func comboRequestsModeCycle() async throws {
        let (engine, _) = makeEngine()
        var cycleCount = 0

        engine.onCycleModeRequested = {
            cycleCount += 1
        }

        engine.handleButtonPress(button: 0)
        engine.handleButtonPress(button: 3)
        try await Task.sleep(for: .milliseconds(100))

        #expect(cycleCount == 1)
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
}
