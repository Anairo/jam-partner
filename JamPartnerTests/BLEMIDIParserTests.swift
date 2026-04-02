import Foundation
import Testing
@testable import JamPartner

@Suite("BLEMIDIParser")
struct BLEMIDIParserTests {

    @Test("parses a BLE MIDI note on packet")
    func parsesNoteOn() {
        let data = Data([0x80, 0x90, 0x0F, 0x64])

        let messages = BLEMIDIParser.parse(data)

        #expect(messages.count == 1)
        #expect(messages[0].status == 0x90)
        #expect(messages[0].data1 == 0x0F)
        #expect(messages[0].data2 == 0x64)
    }

    @Test("parses a BLE MIDI control change packet")
    func parsesControlChange() {
        let data = Data([0x80, 0xB0, 0x32, 0x7F])

        let messages = BLEMIDIParser.parse(data)

        #expect(messages.count == 1)
        #expect(messages[0].status == 0xB0)
        #expect(messages[0].data1 == 0x32)
        #expect(messages[0].data2 == 0x7F)
    }

    @Test("returns no messages for malformed packets")
    func ignoresMalformedPacket() {
        let data = Data([0x01, 0x02])

        let messages = BLEMIDIParser.parse(data)

        #expect(messages.isEmpty)
    }

    @Test("returns partial results when trailing bytes are incomplete")
    func keepsEarlierMessagesOnIncompleteTail() {
        let data = Data([0x80, 0x90, 0x0F, 0x64, 0x80, 0x90, 0x10])

        let messages = BLEMIDIParser.parse(data)

        #expect(messages.count == 1)
        #expect(messages[0].status == 0x90)
        #expect(messages[0].data1 == 0x0F)
        #expect(messages[0].data2 == 0x64)
    }
}
