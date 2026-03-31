import Testing
import Foundation
@testable import JamPartner

@Suite("MappingEngine")
struct MappingEngineTests {

    private func makeEngine() -> (MappingEngine, MockMIDIService, ModeManager) {
        let suite = "com.jampartner.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let midiService = MockMIDIService()
        let modeManager = ModeManager(defaults: defaults)
        let engine = MappingEngine(modeManager: modeManager, midiService: midiService)
        engine.debounceMs = 0
        return (engine, midiService, modeManager)
    }

    // MARK: - Note mapping

    @Test("noteToButton maps 4 notes to 4 buttons")
    func noteMapping() {
        #expect(MappingEngine.noteToButton[15] == 0)
        #expect(MappingEngine.noteToButton[25] == 1)
        #expect(MappingEngine.noteToButton[35] == 2)
        #expect(MappingEngine.noteToButton[45] == 3)
        #expect(MappingEngine.noteToButton[99] == nil)
    }

    // MARK: - Trigger

    @Test("trigger sends CC for the current mode's action")
    func triggerSendsCC() async throws {
        let (engine, midi, _) = makeEngine()
        engine.trigger(button: 0)
        try await Task.sleep(for: .milliseconds(50))

        #expect(midi.sentCCs.count == 1)
        #expect(midi.sentCCs[0].controller == 20, "Button 0 in Navigate = prev_track = CC 20")
        #expect(midi.sentCCs[0].value == 127)
    }

    @Test("debounce blocks rapid triggers")
    func debounce() async throws {
        let (engine, midi, _) = makeEngine()
        engine.debounceMs = 5000

        engine.trigger(button: 0)
        try await Task.sleep(for: .milliseconds(50))
        engine.trigger(button: 0)
        try await Task.sleep(for: .milliseconds(50))

        #expect(midi.sentCCs.count == 1, "Second trigger should be debounced")
    }

    @Test("different buttons are not debounced against each other")
    func debouncePerAction() async throws {
        let (engine, midi, _) = makeEngine()
        engine.debounceMs = 5000

        engine.trigger(button: 0)
        try await Task.sleep(for: .milliseconds(50))
        engine.trigger(button: 1)
        try await Task.sleep(for: .milliseconds(50))

        #expect(midi.sentCCs.count == 2)
    }

    // MARK: - Incoming MIDI

    @Test("Note On for mapped note triggers button press")
    func incomingNoteOn() async throws {
        let (engine, midi, _) = makeEngine()
        engine.handleIncoming(status: 0x90, data1: 15, data2: 100)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.count == 1)
        #expect(midi.sentCCs[0].controller == 20)
    }

    @Test("Note On for unmapped note does not trigger")
    func incomingUnmappedNote() async throws {
        let (engine, midi, _) = makeEngine()
        engine.handleIncoming(status: 0x90, data1: 99, data2: 100)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.isEmpty)
    }

    @Test("Note Off does not trigger button press")
    func incomingNoteOff() async throws {
        let (engine, midi, _) = makeEngine()
        engine.handleIncoming(status: 0x80, data1: 15, data2: 0)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.isEmpty)
    }

    @Test("Note On with velocity 0 treated as Note Off")
    func incomingVelocityZero() async throws {
        let (engine, midi, _) = makeEngine()
        engine.handleIncoming(status: 0x90, data1: 15, data2: 0)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.isEmpty)
    }

    // MARK: - Logging

    @Test("handleIncoming logs CC messages")
    func logsCC() async throws {
        let (engine, _, _) = makeEngine()
        var logged: [String] = []
        engine.onLog = { logged.append($0) }

        engine.handleIncoming(status: 0xB0, data1: 50, data2: 127)
        try await Task.sleep(for: .milliseconds(50))

        #expect(logged.contains { $0.contains("CC") && $0.contains("50") })
    }
}
