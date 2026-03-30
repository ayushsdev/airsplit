import Foundation
import CoreAudio
import AudioToolbox

final class AggregateDeviceService {

    /// Creates an aggregate device combining N output devices into one.
    /// - Parameters:
    ///   - name: Display name for the aggregate device
    ///   - uid: Unique identifier for the aggregate device
    ///   - subDeviceUIDs: UIDs of all devices to include
    ///   - clockSourceUID: UID of the device to use as clock master
    /// - Returns: The AudioObjectID of the created aggregate device, or an error
    func createAggregateDevice(
        name: String,
        uid: String,
        subDeviceUIDs: [String],
        clockSourceUID: String
    ) -> Result<AudioObjectID, AudioError> {
        guard !subDeviceUIDs.isEmpty else {
            return .failure(.noDevicesSelected)
        }

        let subDeviceList: [[String: Any]] = subDeviceUIDs.map { deviceUID in
            [kAudioSubDeviceUIDKey: deviceUID]
        }

        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: name,
            kAudioAggregateDeviceUIDKey: uid,
            kAudioAggregateDeviceSubDeviceListKey: subDeviceList,
            kAudioAggregateDeviceMainSubDeviceKey: clockSourceUID,
            kAudioAggregateDeviceIsPrivateKey: 0,
            kAudioAggregateDeviceIsStackedKey: 1
        ]

        var aggregateDeviceID: AudioDeviceID = kAudioObjectUnknown
        let status = AudioHardwareCreateAggregateDevice(
            description as CFDictionary,
            &aggregateDeviceID
        )

        guard status == noErr else {
            return .failure(.aggregateCreationFailed(status))
        }

        // Enable drift correction on all sub-devices except the clock master
        enableDriftCorrection(
            aggregateDeviceID: aggregateDeviceID,
            clockSourceUID: clockSourceUID,
            subDeviceUIDs: subDeviceUIDs
        )

        return .success(aggregateDeviceID)
    }

    /// Destroys a previously created aggregate device.
    @discardableResult
    func destroyAggregateDevice(id: AudioObjectID) -> OSStatus {
        return AudioHardwareDestroyAggregateDevice(id)
    }

    // MARK: - Private

    private func enableDriftCorrection(
        aggregateDeviceID: AudioObjectID,
        clockSourceUID: String,
        subDeviceUIDs: [String]
    ) {
        // Get the list of sub-devices from the aggregate
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioAggregateDevicePropertyActiveSubDeviceList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            aggregateDeviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == noErr, dataSize > 0 else { return }

        let subDeviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var subDeviceIDs = [AudioObjectID](repeating: 0, count: subDeviceCount)

        status = AudioObjectGetPropertyData(
            aggregateDeviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &subDeviceIDs
        )

        guard status == noErr else { return }

        // Enable drift correction on each non-clock sub-device
        for subDeviceID in subDeviceIDs {
            let uid = getDeviceUID(subDeviceID)
            if uid != clockSourceUID {
                setDriftCorrection(enabled: true, for: subDeviceID)
            }
        }
    }

    private func getDeviceUID(_ deviceID: AudioObjectID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var uid: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &uid
        )

        guard status == noErr, let cfUID = uid?.takeRetainedValue() else { return nil }
        return cfUID as String
    }

    private func setDriftCorrection(enabled: Bool, for deviceID: AudioObjectID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioSubDevicePropertyDriftCompensation,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var value: UInt32 = enabled ? 1 : 0
        AudioObjectSetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &value
        )
    }
}
