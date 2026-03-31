import SwiftUI

struct MidiLogView: View {
    var logs: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("MIDI Log")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, entry in
                        Text(entry)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
