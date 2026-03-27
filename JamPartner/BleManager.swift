//
//  BleManager.swift
//  JamPartner
//
//  Created by Orian Patterson Rivero on 23/03/2026.
//

import CoreBluetooth
import Foundation

private let midiServiceUUID = CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
private let midiCharacteristicUUID = CBUUID(string: "7772E5DB-3868-4112-A1A9-F2669D106BF3")
private let savedPeripheralKey = "lastBLEMIDIPeripheralUUID"

struct DiscoveredDevice: Identifiable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
}

@Observable
class BleManager: NSObject {
    var isScanning = false
    var isConnected = false
    var connectedDeviceName: String?
    var discoveredDevices: [DiscoveredDevice] = []
    var log: [String] = []

    var onMidiReceived: ((UInt8, UInt8, UInt8) -> Void)?

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var midiCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else {
            appendLog("Bluetooth not ready")
            return
        }
        discoveredDevices = []
        isScanning = true
        central.scanForPeripherals(withServices: [midiServiceUUID])
        appendLog("Scanning for BLE MIDI devices...")
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
    }

    func connect(to device: DiscoveredDevice) {
        stopScan()
        appendLog("Connecting to \(device.name)...")
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
            appendLog("Auto-reconnecting to \(peripheral.name ?? "device")...")
            central.connect(peripheral)
        }
    }

    private func appendLog(_ message: String) {
        DispatchQueue.main.async {
            self.log.insert(message, at: 0)
            if self.log.count > 30 {
                self.log.removeLast()
            }
        }
    }

    private func parseBLEMIDI(_ data: Data) {
        guard data.count >= 3 else { return }
        let bytes = [UInt8](data)

        var i = 0
        // skip header byte (timestamp high)
        guard bytes[i] & 0x80 != 0 else { return }
        i += 1

        var runningStatus: UInt8 = 0

        while i < bytes.count {
            // timestamp byte
            if bytes[i] & 0x80 != 0 {
                i += 1
                if i >= bytes.count { break }
            }

            // status byte or running status
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
                onMidiReceived?(runningStatus, d1, d2)
            case 0xC0, 0xD0:
                guard i < bytes.count else { return }
                let d1 = bytes[i]
                i += 1
                onMidiReceived?(runningStatus, d1, 0)
            default:
                i += 1
            }
        }
    }
}

extension BleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            appendLog("Bluetooth powered on")
            attemptAutoReconnect()
        case .poweredOff:
            appendLog("Bluetooth powered off")
        case .unauthorized:
            appendLog("Bluetooth unauthorized")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any], rssi: NSNumber) {
        let name = peripheral.name ?? "Unknown"
        if !discoveredDevices.contains(where: { $0.id == peripheral.identifier }) {
            discoveredDevices.append(DiscoveredDevice(id: peripheral.identifier, name: name, peripheral: peripheral))
            appendLog("Found: \(name)")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        connectedDeviceName = peripheral.name ?? "Unknown"
        isConnected = true
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: savedPeripheralKey)
        appendLog("Connected to \(connectedDeviceName!)")
        peripheral.delegate = self
        peripheral.discoverServices([midiServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedDeviceName = nil
        midiCharacteristic = nil
        connectedPeripheral = nil
        appendLog("Disconnected")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        appendLog("Failed to connect: \(error?.localizedDescription ?? "unknown")")
    }
}

extension BleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == midiServiceUUID {
            peripheral.discoverCharacteristics([midiCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for char in chars where char.uuid == midiCharacteristicUUID {
            midiCharacteristic = char
            peripheral.setNotifyValue(true, for: char)
            appendLog("Subscribed to BLE MIDI characteristic")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == midiCharacteristicUUID,
              let data = characteristic.value else { return }
        parseBLEMIDI(data)
    }
}
