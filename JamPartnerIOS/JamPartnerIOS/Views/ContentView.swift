import SwiftUI

struct ContentView: View {
    @Environment(ConnectionViewModel.self) private var connectionVM
    @Environment(PerformViewModel.self) private var performVM
    @State private var showConnection = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ConnectionStatusBar()

                        ModeHeader()
                            .padding(.vertical, 12)

                        ButtonGridView()
                            .padding(.horizontal)

                        Spacer().frame(height: 32)

                        Divider()
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        ModePickerSection()
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        Divider()
                            .padding(.horizontal)

                        Spacer().frame(height: 24)

                        DebounceSection()
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
                ConnectionSheet()
            }
        }
    }

    private var combinedLog: [String] {
        performVM.log + connectionVM.log
    }
}

// MARK: - Inline sections

private struct DebounceSection: View {
    @Environment(PerformViewModel.self) private var performVM

    var body: some View {
        @Bindable var vm = performVM
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
    @Environment(PerformViewModel.self) private var performVM
    @Environment(ModeManager.self) private var modeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MODES")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    ModeEditorDestination()
                } label: {
                    Text("Edit")
                        .font(.caption)
                }
            }

            HStack(spacing: 8) {
                ForEach(Array(modeManager.modes.enumerated()), id: \.element.id) { index, mode in
                    Button {
                        modeManager.selectMode(at: index)
                    } label: {
                        Text(mode.name)
                            .font(.subheadline.weight(index == modeManager.currentModeIndex ? .bold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                index == modeManager.currentModeIndex
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
    var body: some View {
        List {
            ModeListView()
        }
        .navigationTitle("Edit Modes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ConnectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ConnectionView()
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
