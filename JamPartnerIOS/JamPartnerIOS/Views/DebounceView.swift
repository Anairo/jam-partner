import SwiftUI

struct DebounceView: View {
    @Bindable var vm: PerformViewModel

    var body: some View {
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
