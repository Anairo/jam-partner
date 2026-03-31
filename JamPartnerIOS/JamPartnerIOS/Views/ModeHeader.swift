import SwiftUI

struct ModeHeader: View {
    var vm: PerformViewModel

    var body: some View {
        Text(vm.modeManager.currentMode.name.uppercased())
            .font(.title3.weight(.heavy))
            .tracking(2)
            .foregroundStyle(.secondary)
    }
}
