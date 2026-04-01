import SwiftUI

struct ButtonGridView: View {
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ModeManager.self) private var modeManager

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    performVM.onButtonTap(index)
                } label: {
                    Text(modeManager.currentMode.label(for: index))
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
