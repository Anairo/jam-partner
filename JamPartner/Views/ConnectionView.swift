import SwiftUI

struct ConnectionView: View {
    var vm: ConnectionViewModel

    var body: some View {
        GroupBox("Glove Connection") {
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(vm.isConnected ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(connectionLabel)
                        .font(.subheadline)
                    Spacer()
                    if vm.isConnected {
                        Button("Disconnect") { vm.disconnect() }
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
                                .controlSize(.mini)
                        }
                    }
                }
            }
        }
    }

    private var connectionLabel: String {
        if let name = vm.connectedDeviceName {
            return "Connected to \(name)"
        }
        return vm.isScanning ? "Scanning..." : "Disconnected"
    }
}
