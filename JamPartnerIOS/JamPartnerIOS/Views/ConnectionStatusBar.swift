import SwiftUI

struct ConnectionStatusBar: View {
    var vm: ConnectionViewModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(vm.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            Text(statusLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    private var statusLabel: String {
        if let name = vm.connectedDeviceName {
            return "Connected to \(name)"
        }
        return vm.isScanning ? "Scanning..." : "Disconnected"
    }
}
