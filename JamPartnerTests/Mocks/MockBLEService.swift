@testable import JamPartner

final class MockBLEService: BLEServiceProtocol {
    var onMidiMessage: ((UInt8, UInt8, UInt8) -> Void)?
    var onConnectionChanged: ((Bool, String?) -> Void)?
    var onDeviceDiscovered: ((DiscoveredDevice) -> Void)?
    var onScanningChanged: ((Bool) -> Void)?
    var onLog: ((String) -> Void)?

    var startScanCalled = false
    var stopScanCalled = false
    var disconnectCalled = false
    var connectCalledWith: String?

    func startScan() {
        startScanCalled = true
    }

    func stopScan() {
        stopScanCalled = true
    }

    func connect(to device: DiscoveredDevice) {
        connectCalledWith = device.name
    }

    func disconnect() {
        disconnectCalled = true
    }

    // MARK: - Simulate events

    func simulateConnection(name: String) {
        onConnectionChanged?(true, name)
    }

    func simulateDisconnection() {
        onConnectionChanged?(false, nil)
    }

    func simulateScanningChanged(_ scanning: Bool) {
        onScanningChanged?(scanning)
    }

    func simulateMidiMessage(status: UInt8, data1: UInt8, data2: UInt8) {
        onMidiMessage?(status, data1, data2)
    }

    func reset() {
        startScanCalled = false
        stopScanCalled = false
        disconnectCalled = false
        connectCalledWith = nil
    }
}
