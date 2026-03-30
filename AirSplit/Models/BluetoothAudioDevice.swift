import Foundation
import SimplyCoreAudio
import CoreAudio

struct BluetoothAudioDevice: Identifiable {
    let id: AudioObjectID
    let uid: String
    let name: String
    let transportType: TransportType
    var isEnabled: Bool
    var volume: Float
    var isConnected: Bool
    let underlyingDevice: AudioDevice

    init(from device: AudioDevice) {
        self.id = device.id
        self.uid = device.uid ?? UUID().uuidString
        self.name = device.name
        self.transportType = device.transportType ?? .unknown
        self.isEnabled = false
        self.volume = device.virtualMainVolume(scope: .output) ?? Constants.defaultMasterVolume
        self.isConnected = device.isAlive
        self.underlyingDevice = device
    }
}

extension BluetoothAudioDevice: Hashable {
    static func == (lhs: BluetoothAudioDevice, rhs: BluetoothAudioDevice) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
