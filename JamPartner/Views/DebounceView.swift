import SwiftUI

struct DebounceView: View {
    @Environment(PerformViewModel.self) private var performVM

    var body: some View {
        @Bindable var vm = performVM
        GroupBox("Debounce") {
            HStack {
                Slider(value: $vm.debounceMs, in: 50...800, step: 10)
                    .onChange(of: vm.debounceMs) {
                        vm.syncDebounce()
                    }
                Text("\(Int(vm.debounceMs)) ms")
                    .font(.caption.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }
}
