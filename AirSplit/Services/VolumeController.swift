import Foundation
import SimplyCoreAudio
import CoreAudio

final class VolumeController {

    func setVolume(_ volume: Float, for device: AudioDevice) {
        device.setVirtualMainVolume(volume, scope: .output)
    }

    func getVolume(for device: AudioDevice) -> Float? {
        return device.virtualMainVolume(scope: .output)
    }

    func setMasterVolume(_ volume: Float, across devices: [AudioDevice]) {
        for device in devices {
            setVolume(volume, for: device)
        }
    }

    func setChannelVolume(_ volume: Float, channel: UInt32, for device: AudioDevice) {
        device.setVolume(volume, channel: channel, scope: .output)
    }
}
