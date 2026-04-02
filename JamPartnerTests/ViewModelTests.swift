import Testing
import Foundation
@testable import JamPartner

// MARK: - ConnectionViewModel

@MainActor
@Suite("ConnectionViewModel")
struct ConnectionViewModelTests {

    @Test("scan delegates to BLE service")
    func scan() {
        let ble = MockBLEService()
        let vm = ConnectionViewModel(bleService: ble)
        vm.scan()
        #expect(ble.startScanCalled)
    }

    @Test("stopScan delegates to BLE service")
    func stopScan() {
        let ble = MockBLEService()
        let vm = ConnectionViewModel(bleService: ble)
        vm.stopScan()
        #expect(ble.stopScanCalled)
    }

    @Test("disconnect delegates to BLE service")
    func disconnect() {
        let ble = MockBLEService()
        let vm = ConnectionViewModel(bleService: ble)
        vm.disconnect()
        #expect(ble.disconnectCalled)
    }

    @Test("connection callback updates VM state")
    func connectionState() async throws {
        let ble = MockBLEService()
        let vm = ConnectionViewModel(bleService: ble)

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
        let vm = ConnectionViewModel(bleService: ble)

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
        let vm = ConnectionViewModel(bleService: ble)

        ble.onLog?("test message")
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.log.contains("test message"))
    }

    @Test("log capped at 30 entries")
    func logCap() async throws {
        let ble = MockBLEService()
        let vm = ConnectionViewModel(bleService: ble)

        for i in 0..<40 {
            ble.onLog?("msg \(i)")
        }
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.log.count <= 30)
    }
}

// MARK: - PerformViewModel

@Suite("PerformViewModel")
@MainActor
struct PerformViewModelTests {

    private func makeVM() -> (PerformViewModel, MockMIDIService) {
        let suite = "com.jampartner.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let midi = MockMIDIService()
        let modeManager = ModeManager(defaults: defaults)
        let engine = MappingEngine(midiService: midi)
        let vm = PerformViewModel(midiService: midi, mappingEngine: engine, modeManager: modeManager)
        return (vm, midi)
    }

    @Test("init calls midiService.start()")
    func initStartsMidi() {
        let (_, midi) = makeVM()
        #expect(midi.startCalled)
    }

    @Test("cycleMode changes current mode")
    func cycleMode() {
        let (vm, _) = makeVM()
        #expect(vm.modeManager.currentMode.name == "Navigate")
        vm.cycleMode()
        #expect(vm.modeManager.currentMode.name == "Looper")
    }

    @Test("syncDebounce propagates to engine")
    func syncDebounce() async throws {
        let (vm, midi) = makeVM()
        vm.debounceMs = 9999

        vm.syncDebounce()
        vm.onButtonTap(0)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.count == 1)

        vm.onButtonTap(0)
        try await Task.sleep(for: .milliseconds(300))

        #expect(midi.sentCCs.count == 1, "Debounce of 9999ms should block second tap")
    }

    @Test("MIDI log messages appear in VM log")
    func midiLogForwarded() async throws {
        let (vm, midi) = makeVM()
        midi.onLog?("test from midi")
        try await Task.sleep(for: .milliseconds(50))

        #expect(vm.log.contains("test from midi"))
    }

    @Test("modeManager is accessible and shared")
    func modeManagerAccess() {
        let (vm, _) = makeVM()
        #expect(vm.modeManager.modes.count == 3)
        #expect(vm.modeManager.currentMode.name == "Navigate")
    }
}
