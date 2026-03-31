import Testing
import Foundation
@testable import JamPartner

@Suite("ButtonMode")
struct ButtonModeTests {

    @Test("label returns action label for valid index")
    func labelValid() {
        let mode = ButtonMode(
            id: UUID(),
            name: "Test",
            actions: ["play_stop", "record", "prev_track", "next_track"]
        )
        #expect(mode.label(for: 0) == "Play / Stop")
        #expect(mode.label(for: 1) == "Record")
        #expect(mode.label(for: 2) == "Prev Track")
        #expect(mode.label(for: 3) == "Next Track")
    }

    @Test("label returns --- for out-of-bounds index")
    func labelOutOfBounds() {
        let mode = ButtonMode(id: UUID(), name: "Test", actions: ["play_stop"])
        #expect(mode.label(for: 5) == "---")
    }

    @Test("label returns --- for unknown action id")
    func labelUnknownAction() {
        let mode = ButtonMode(id: UUID(), name: "Test", actions: ["bogus_action"])
        #expect(mode.label(for: 0) == "---")
    }

    @Test("Codable round-trip preserves data")
    func codableRoundTrip() throws {
        let original = ButtonMode(
            id: UUID(),
            name: "MyMode",
            actions: ["play_stop", "record", "undo", "overdub"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ButtonMode.self, from: data)
        #expect(decoded == original)
    }
}
