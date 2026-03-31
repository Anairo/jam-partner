import SwiftUI

struct ConnectionView: View {
    var vm: ConnectionViewModel

    var body: some View {
        HStack {
            Circle()
                .fill(vm.isConnected ? .green : .red)
                .frame(width: 10, height: 10)
            if let name = vm.connectedDeviceName {
                Text(name).font(.subheadline)
            } else {
                Text(vm.isScanning ? "Scanning..." : "Disconnected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if vm.isConnected {
                Button("Disconnect", role: .destructive) { vm.disconnect() }
                    .controlSize(.small)
            } else if vm.isScanning {
                Button("Stop") { vm.stopScan() }
                    .controlSize(.small)
            } else {
                Button("Scan") { vm.scan() }
                    .controlSize(.small)
            }
        }

        if vm.isScanning && !vm.discoveredDevices.isEmpty {
            ForEach(vm.discoveredDevices) { device in
                HStack {
                    Text(device.name).font(.caption)
                    Spacer()
                    Button("Connect") { vm.connect(to: device) }
                        .controlSize(.small)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
