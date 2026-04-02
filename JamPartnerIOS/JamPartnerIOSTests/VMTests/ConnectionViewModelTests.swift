import Testing
import Foundation
@testable import JamPartnerIOS

// MARK: - ConnectionViewModel (inchangé)

@MainActor
@Suite("ConnectionViewModel")
struct ConnectionViewModelTests {

    @Test("scan delegates to BLE service")
    func scan() {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)
        vm.scan()
        #expect(ble.startScanCalled)
    }

    @Test("stopScan delegates to BLE service")
    func stopScan() {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)
        vm.stopScan()
        #expect(ble.stopScanCalled)
    }

    @Test("disconnect delegates to BLE service")
    func disconnect() {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)
        vm.disconnect()
        #expect(ble.disconnectCalled)
    }

    @Test("connection callback updates VM state")
    func connectionState() async throws {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)

        ble.simulateConnection(name: "TestGlove")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.isConnected)
        #expect(vm.connectedDeviceName == "TestGlove")

        ble.simulateDisconnection()
        try await Task.sleep(for: .milliseconds(50))
        #expect(!vm.isConnected)
        #expect(vm.connectedDeviceName == nil)
    }

    @Test("scanning callback updates VM state")
    func scanningState() async throws {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)

        ble.simulateScanningChanged(true)
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.isScanning)

        ble.simulateScanningChanged(false)
        try await Task.sleep(for: .milliseconds(50))
        #expect(!vm.isScanning)
    }

    @Test("log callback appends to VM log")
    func logAppend() async throws {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)
        ble.onLog?("test message")
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.log.contains("test message"))
    }

    @Test("log capped at 30 entries")
    func logCap() async throws {
        let ble = MockBLEService()
        let vm  = ConnectionViewModel(bleService: ble)
        for i in 0..<40 { ble.onLog?("msg \(i)") }
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.log.count <= 30)
    }
}
