import SwiftUI

struct MidiLogView: View {
    var logs: [String]

    var body: some View {
        Text("MIDI Log")
            .font(.caption.bold())
            .frame(maxWidth: .infinity, alignment: .leading)

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 3) {
                ForEach(Array(logs.enumerated()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 140)
    }
}
