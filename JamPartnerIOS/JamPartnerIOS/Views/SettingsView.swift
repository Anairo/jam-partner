import SwiftUI

struct SettingsView: View {
    var connectionVM: ConnectionViewModel
    var performVM: PerformViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Bluetooth") {
                    ConnectionView(vm: connectionVM)
                }

                Section("Debounce") {
                    DebounceView(vm: performVM)
                }

                Section("Modes") {
                    ModeListView(modeManager: performVM.modeManager)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
