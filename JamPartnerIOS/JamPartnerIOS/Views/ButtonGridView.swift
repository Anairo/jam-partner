import SwiftUI

struct ButtonGridView: View {
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ModeManager.self) private var modeManager
    @State private var tapCounts = [0, 0, 0, 0]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let buttonColors: [Color] = [.blue, .purple, .orange, .green]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    tapCounts[index] += 1
                    performVM.onButtonTap(index)
                } label: {
                    Text(modeManager.currentMode.label(for: index))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(buttonColors[index].gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(flexibility: .solid), trigger: tapCounts[index])
            }
        }
    }
}
