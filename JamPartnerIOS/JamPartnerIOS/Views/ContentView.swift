import SwiftUI

struct ContentView: View {
    var connectionVM: ConnectionViewModel
    var performVM: PerformViewModel
    @State private var showConnection = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ConnectionStatusBar(vm: connectionVM)

                        ModeHeader(vm: performVM)
                            .padding(.vertical, 12)

                        ButtonGridView(vm: performVM)
                            .padding(.horizontal)

                        Spacer().frame(height: 32)

                        Divider()
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        ModePickerSection(vm: performVM)
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        Divider()
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        DebounceSection(vm: performVM)
                            .padding(.horizontal)

                        Spacer().frame(height: 16)
                    }
                }

                Divider()

                MidiLogView(logs: combinedLog)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(height: 120)
                    .background(Color(.systemBackground))
            }
            .navigationTitle("JamPartner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showConnection = true } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                }
            }
            .sheet(isPresented: $showConnection) {
                ConnectionSheet(vm: connectionVM)
            }
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}

// MARK: - Inline sections

private struct DebounceSection: View {
    @Bindable var vm: PerformViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEBOUNCE")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            HStack {
                Slider(value: $vm.debounceMs, in: 50...800, step: 10)
                    .onChange(of: vm.debounceMs) { vm.syncDebounce() }
                Text("\(Int(vm.debounceMs)) ms")
                    .font(.caption.monospacedDigit())
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }
}

private struct ModePickerSection: View {
    var vm: PerformViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MODES")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    ModeEditorDestination(modeManager: vm.modeManager)
                } label: {
                    Text("Edit")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                ForEach(Array(vm.modeManager.modes.enumerated()), id: \.element.id) { index, mode in
                    Button {
                        vm.modeManager.selectMode(at: index)
                    } label: {
                        Text(mode.name)
                            .font(.subheadline.weight(index == vm.modeManager.currentModeIndex ? .bold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                index == vm.modeManager.currentModeIndex
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ModeEditorDestination: View {
    var modeManager: ModeManager

    var body: some View {
        List {
            ModeListView(modeManager: modeManager)
        }
        .navigationTitle("Edit Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ConnectionSheet: View {
    var vm: ConnectionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ConnectionView(vm: vm)
            }
            .navigationTitle("Bluetooth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
