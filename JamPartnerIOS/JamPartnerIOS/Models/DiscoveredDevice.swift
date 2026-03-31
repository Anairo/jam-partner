import CoreBluetooth

struct DiscoveredDevice: Identifiable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
}
