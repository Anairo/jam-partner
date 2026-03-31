import Foundation

@Observable
class ConnectionViewModel {
    var isConnected = false
    var isScanning = false
    var connectedDeviceName: String?
    var discoveredDevices: [DiscoveredDevice] = []
    private(set) var log: [String] = []

    private let bleService: any BLEServiceProtocol

    init(bleService: any BLEServiceProtocol) {
        self.bleService = bleService

        bleService.onConnectionChanged = { [weak self] connected, name in
            DispatchQueue.main.async {
                self?.isConnected = connected
                self?.connectedDeviceName = name
            }
        }

        bleService.onDeviceDiscovered = { [weak self] device in
            DispatchQueue.main.async {
                guard let self else { return }
                if !self.discoveredDevices.contains(where: { $0.id == device.id }) {
                    self.discoveredDevices.append(device)
                }
            }
        }

        bleService.onScanningChanged = { [weak self] scanning in
            DispatchQueue.main.async {
                self?.isScanning = scanning
            }
        }

        bleService.onLog = { [weak self] msg in
            self?.appendLog(msg)
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
        DispatchQueue.main.async {
            self.log.insert(message, at: 0)
            if self.log.count > 30 { self.log.removeLast() }
        }
    }
}
