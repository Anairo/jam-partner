import Foundation

@MainActor
@Observable
final class ConnectionViewModel {
    var isConnected = false
    var isScanning = false
    var connectedDeviceName: String?
    var discoveredDevices: [DiscoveredDevice] = []
    private(set) var log: [String] = []

    private let bleService: any BLEServiceProtocol

    init(bleService: any BLEServiceProtocol) {
        self.bleService = bleService

        bleService.onConnectionChanged = { [weak self] connected, name in
            Task { @MainActor in
                self?.isConnected = connected
                self?.connectedDeviceName = name
            }
        }

        bleService.onDeviceDiscovered = { [weak self] device in
            Task { @MainActor in
                guard let self else { return }
                if !self.discoveredDevices.contains(where: { $0.id == device.id }) {
                    self.discoveredDevices.append(device)
                }
            }
        }

        bleService.onScanningChanged = { [weak self] scanning in
            Task { @MainActor in
                self?.isScanning = scanning
            }
        }

        bleService.onLog = { [weak self] msg in
            Task { @MainActor in
                self?.appendLog(msg)
            }
        }
    }

    func scan() {
        discoveredDevices = []
        bleService.startScan()
    }

    func stopScan() {
        bleService.stopScan()
    }

    func connect(to device: DiscoveredDevice) {
        bleService.connect(to: device)
    }

    func disconnect() {
        bleService.disconnect()
    }

    private func appendLog(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 30 { log.removeLast() }
    }
}
