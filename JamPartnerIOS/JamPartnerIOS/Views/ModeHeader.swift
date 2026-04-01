import SwiftUI

struct ModeHeader: View {
    @Environment(ModeManager.self) private var modeManager

    var body: some View {
        Text(modeManager.currentMode.name.uppercased())
            .font(.title3.weight(.heavy))
            .tracking(2)
            .foregroundStyle(.secondary)
    }
}
