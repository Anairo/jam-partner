import SwiftUI

struct ButtonGridView: View {
    var vm: PerformViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    vm.onButtonTap(index)
                } label: {
                    Text(vm.modeManager.currentMode.label(for: index))
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
