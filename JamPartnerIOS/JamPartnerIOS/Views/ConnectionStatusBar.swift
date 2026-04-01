import SwiftUI

struct ConnectionStatusBar: View {
    @Environment(ConnectionViewModel.self) private var connectionVM

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectionVM.isConnected ? .green : .red)
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
        if let name = connectionVM.connectedDeviceName {
            return "Connected to \(name)"
        }
        return connectionVM.isScanning ? "Scanning..." : "Disconnected"
    }
}
