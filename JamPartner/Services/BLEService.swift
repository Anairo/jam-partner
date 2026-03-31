import CoreBluetooth
import Foundation

private let midiServiceUUID = CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
private let midiCharacteristicUUID = CBUUID(string: "7772E5DB-3868-4112-A1A9-F2669D106BF3")
private let savedPeripheralKey = "lastBLEMIDIPeripheralUUID"

protocol BLEServiceProtocol: AnyObject {
    var onMidiMessage: ((UInt8, UInt8, UInt8) -> Void)? { get set }
    var onConnectionChanged: ((Bool, String?) -> Void)? { get set }
    var onDeviceDiscovered: ((DiscoveredDevice) -> Void)? { get set }
    var onScanningChanged: ((Bool) -> Void)? { get set }
    var onLog: ((String) -> Void)? { get set }

    func startScan()
    func stopScan()
    func connect(to device: DiscoveredDevice)
    func disconnect()
}

class BLEService: NSObject, BLEServiceProtocol {
    var onMidiMessage: ((UInt8, UInt8, UInt8) -> Void)?
    var onConnectionChanged: ((Bool, String?) -> Void)?
    var onDeviceDiscovered: ((DiscoveredDevice) -> Void)?
    var onScanningChanged: ((Bool) -> Void)?
    var onLog: ((String) -> Void)?

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var midiCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            onLog?("Bluetooth not ready")
            return
        }
        onScanningChanged?(true)
        central.scanForPeripherals(withServices: [midiServiceUUID])
        onLog?("Scanning for BLE MIDI devices...")
    }

    func stopScan() {
        central.stopScan()
        onScanningChanged?(false)
    }

    func connect(to device: DiscoveredDevice) {
        stopScan()
        onLog?("Connecting to \(device.name)...")
        central.connect(device.peripheral)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
    }

    private func attemptAutoReconnect() {
        guard let uuidString = UserDefaults.standard.string(forKey: savedPeripheralKey),
              let uuid = UUID(uuidString: uuidString) else { return }
        let known = central.retrievePeripherals(withIdentifiers: [uuid])
        if let peripheral = known.first {
            onLog?("Auto-reconnecting to \(peripheral.name ?? "device")...")
            central.connect(peripheral)
        }
    }

    private func parseBLEMIDI(_ data: Data) {
        guard data.count >= 3 else { return }
        let bytes = [UInt8](data)

        var i = 0
        guard bytes[i] & 0x80 != 0 else { return }
        i += 1

        var runningStatus: UInt8 = 0

        while i < bytes.count {
            if bytes[i] & 0x80 != 0 {
                i += 1
                if i >= bytes.count { break }
            }
            if bytes[i] & 0x80 != 0 {
                runningStatus = bytes[i]
                i += 1
            }
            guard runningStatus & 0x80 != 0 else { break }

            let messageType = runningStatus & 0xF0
            switch messageType {
            case 0x80, 0x90, 0xA0, 0xB0, 0xE0:
                guard i + 1 < bytes.count else { return }
                let d1 = bytes[i]
                let d2 = bytes[i + 1]
                i += 2
                onMidiMessage?(runningStatus, d1, d2)
            case 0xC0, 0xD0:
                guard i < bytes.count else { return }
                let d1 = bytes[i]
                i += 1
                onMidiMessage?(runningStatus, d1, 0)
            default:
                i += 1
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            onLog?("Bluetooth powered on")
            attemptAutoReconnect()
        case .poweredOff:
            onLog?("Bluetooth powered off")
        case .unauthorized:
            onLog?("Bluetooth unauthorized")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager,
                         didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any],
                         rssi: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        let device = DiscoveredDevice(id: peripheral.identifier, name: name, peripheral: peripheral)
        onDeviceDiscovered?(device)
        onLog?("Found: \(name)")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        let name = peripheral.name ?? "Unknown"
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: savedPeripheralKey)
        onConnectionChanged?(true, name)
        onLog?("Connected to \(name)")
        peripheral.delegate = self
        peripheral.discoverServices([midiServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                         didDisconnectPeripheral peripheral: CBPeripheral,
                         error: Error?) {
        connectedPeripheral = nil
        midiCharacteristic = nil
        onConnectionChanged?(false, nil)
        onLog?("Disconnected")
    }

    func centralManager(_ central: CBCentralManager,
                         didFailToConnect peripheral: CBPeripheral,
                         error: Error?) {
        onLog?("Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }
}

// MARK: - CBPeripheralDelegate

extension BLEService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == midiServiceUUID {
            peripheral.discoverCharacteristics([midiCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didDiscoverCharacteristicsFor service: CBService,
                     error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars where char.uuid == midiCharacteristicUUID {
            midiCharacteristic = char
            peripheral.setNotifyValue(true, for: char)
            onLog?("Subscribed to BLE MIDI characteristic")
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didUpdateValueFor characteristic: CBCharacteristic,
                     error: Error?) {
        guard characteristic.uuid == midiCharacteristicUUID,
              let data = characteristic.value else { return }
        parseBLEMIDI(data)
    }
}
