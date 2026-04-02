import Foundation

struct MappingConfig: Codable, Equatable {
    var comboButtons: Set<Int>
    var comboWindowMs: Double
    var noteToButton: [UInt8: Int]
    var debounceMs: Double

    static let `default` = MappingConfig(
        comboButtons: [0, 3],
        comboWindowMs: 150,
        noteToButton: [15: 0, 25: 1, 35: 2, 45: 3],
        debounceMs: 250
    )

    var isValid: Bool {
        comboButtons.count == 2
        && comboButtons.allSatisfy { (0..<4).contains($0) }
        && comboWindowMs > 0
        && debounceMs >= 0
        && noteToButton.values.allSatisfy { (0..<4).contains($0) }
    }
}
