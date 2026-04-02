import Foundation
import Testing
@testable import JamPartner

@Suite("BLEMIDIParser")
struct BLEMIDIParserTests {

    @Test("parses a BLE MIDI note on packet")
    func parsesNoteOn() throws {
        let data = Data([0x80, 0x80, 0x90, 0x0F, 0x64])

        let messages = BLEMIDIParser.parse(data)
        let message = try #require(messages.first)

        #expect(messages.count == 1)
        #expect(message.status == 0x90)
        #expect(message.data1 == 0x0F)
        #expect(message.data2 == 0x64)
    }

    @Test("parses a BLE MIDI control change packet")
    func parsesControlChange() throws {
        let data = Data([0x80, 0x80, 0xB0, 0x32, 0x7F])

        let messages = BLEMIDIParser.parse(data)
        let message = try #require(messages.first)

        #expect(messages.count == 1)
        #expect(message.status == 0xB0)
        #expect(message.data1 == 0x32)
        #expect(message.data2 == 0x7F)
    }

    @Test("returns no messages for malformed packets")
    func ignoresMalformedPacket() {
        let data = Data([0x01, 0x02])

        let messages = BLEMIDIParser.parse(data)

        #expect(messages.isEmpty)
    }

    @Test("returns partial results when trailing bytes are incomplete")
    func keepsEarlierMessagesOnIncompleteTail() throws {
        let data = Data([0x80, 0x80, 0x90, 0x0F, 0x64, 0x81, 0x90, 0x10])

        let messages = BLEMIDIParser.parse(data)
        let message = try #require(messages.first)

        #expect(messages.count == 1)
        #expect(message.status == 0x90)
        #expect(message.data1 == 0x0F)
        #expect(message.data2 == 0x64)
    }
}
